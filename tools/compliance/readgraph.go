// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package compliance

import (
	"fmt"
	"io"
	"io/fs"
	"strings"
	"sync"

	"android/soong/compliance/license_metadata_proto"

	"google.golang.org/protobuf/encoding/prototext"
)

const (
	// MaxResolutions is the limit to number of resolution sets for each graph.
	MaxResolutions = 10
)

var (
	// ConcurrentReaders is the size of the task pool for limiting resource usage e.g. open files.
	ConcurrentReaders = 5
)

// result describes the outcome of reading and parsing a single license metadata file.
type result struct {
	// file identifies the path to the license metadata file
	file string

	// target contains the parsed metadata or nil if an error
	target *TargetNode

	// err is nil unless an error occurs
	err error
}

// receiver coordinates the tasks for reading and parsing license metadata files.
type receiver struct {
	// lg accumulates the read metadata and becomes the final resulting LicenseGraph.
	lg *LicenseGraph

	// targets facilitates quick lookup by target name and tracks the scheduled reads.
	targets map[string]*TargetNode

	// rootFS locates the root of the file system from which to read the files.
	rootFS fs.FS

	// stderr identifies the error output writer.
	stderr io.Writer

	// task provides a fixed-size task pool to limit concurrent open files etc.
	task chan bool

	// results returns one license metadata file result at a time.
	results chan *result

	// wg detects when done
	wg sync.WaitGroup
}

// ReadLicenseGraph reads and parses `files` and their dependencies into a LicenseGraph.
//
// `files` become the root files of the graph for top-down walks of the graph.
func ReadLicenseGraph(rootFS fs.FS, stderr io.Writer, files []string) (*LicenseGraph, error) {
	if len(files) == 0 {
		return nil, fmt.Errorf("no license metadata to analyze")
	}
	if ConcurrentReaders < 1 {
		return nil, fmt.Errorf("need at least one task in pool")
	}

	lg := newLicenseGraph()
	for _, f := range files {
		if strings.HasSuffix(f, ".meta_lic") {
			lg.rootFiles = append(lg.rootFiles, f)
		} else {
			lg.rootFiles = append(lg.rootFiles, f+".meta_lic")
		}
	}
	lg.rootNodes = make([]*TargetNode, len(lg.rootFiles))

	recv := &receiver{
		lg:      lg,
		rootFS:  rootFS,
		stderr:  stderr,
		task:    make(chan bool, ConcurrentReaders),
		results: make(chan *result, ConcurrentReaders),
		targets: make(map[string]*TargetNode),
		wg:      sync.WaitGroup{},
	}
	for i := 0; i < ConcurrentReaders; i++ {
		recv.task <- true
	}

	readFiles := func() {
		lg.mu.Lock()
		// identify the metadata files to schedule reading tasks for
		for _, f := range lg.rootFiles {
			recv.targets[f] = nil
		}
		lg.mu.Unlock()

		// schedule tasks to read the files
		for _, f := range lg.rootFiles {
			readFile(recv, f)
		}

		// schedule a task to wait until finished and close the channel.
		go func() {
			recv.wg.Wait()
			close(recv.task)
			close(recv.results)
		}()
	}
	go readFiles()

	// tasks to read license metadata files are scheduled; read and process results from channel
	var err error
	for recv.results != nil {
		select {
		case r, ok := <-recv.results:
			if ok {
				// handle errors by nil'ing ls, setting err, and clobbering results channel
				if r.err != nil {
					err = r.err
					fmt.Fprintf(recv.stderr, "%s\n", err.Error())
					lg = nil
					recv.results = nil
					continue
				}

				// record the parsed metadata (guarded by mutex)
				recv.lg.mu.Lock()
				recv.targets[r.target.name] = r.target
				r.target.index = TargetNodeIndex(len(recv.lg.targets))
				if len(recv.lg.targets) == cap(recv.lg.targets) {
					newTargets := make([]*TargetNode, len(recv.lg.targets), cap(recv.lg.targets) * 2)
					copy(newTargets, recv.lg.targets)
					recv.lg.targets = newTargets
				}
				recv.lg.targets = append(recv.lg.targets, r.target)
				recv.lg.mu.Unlock()
			} else {
				// finished -- nil the results channel
				recv.results = nil
			}
		}
	}

	if lg != nil {
		for i, f := range lg.rootFiles {
			tn, ok := recv.targets[f]
			if !ok {
				return nil, fmt.Errorf("no node for root %q", f)
			}
			lg.rootNodes[i] = tn
		}
		esize := 0
		for _, tn := range lg.targets {
			esize += len(tn.proto.Deps)
		}
		lg.edges = make(TargetEdgeList, 0, esize)
		for _, tn := range lg.targets {
			tn.resolutions[0] = LicenseConditionSetFromNames(tn, tn.proto.LicenseConditions...)
			err = addDependencies(lg, tn, recv.targets)
			if err != nil {
				return nil, fmt.Errorf("error indexing dependencies for %q: %w", tn.name, err)
			}
			tn.proto.Deps = []*license_metadata_proto.AnnotatedDependency{}
		}
	}
	return lg, err

}

// targetNode contains the license metadata for a node in the license graph.
type targetNode struct {
	proto license_metadata_proto.LicenseMetadata

	// name is the path to the metadata file.
	name string

	// lg is the license graph the node belongs to.
	lg *LicenseGraph

	// index locates the target node in the license graph's list of target nodes.
	index TargetNodeIndex

	// edges indentifies the dependencies of the target.
	edges TargetEdgeList

	// resolutions identifies the license conditions acting on the target for each resolution set.
	resolutions [MaxResolutions]LicenseConditionSet
}

// addDependencies converts the proto AnnotatedDependencies into `edges`
func addDependencies(lg *LicenseGraph, tn *TargetNode, byName map[string]*TargetNode) error {
	tn.edges = make(TargetEdgeList, 0,len(tn.proto.Deps))
	for _, ad := range tn.proto.Deps {
		dependency := ad.GetFile()
		if len(dependency) == 0 {
			return fmt.Errorf("missing dependency name")
		}
		dtn, ok := byName[dependency]
		if !ok {
			return fmt.Errorf("unknown dependency name %q", dependency)
		}
		if dtn == nil {
			return fmt.Errorf("nil dependency for name %q", dependency)
		}
		annotations := newEdgeAnnotations()
		for _, a := range ad.Annotations {
			if len(a) == 0 {
				continue
			}
			annotations.annotations[a] = true
		}
		edge := &TargetEdge{tn, dtn, annotations}
		lg.edges = append(lg.edges, edge)
		tn.edges = append(tn.edges, edge)
	}
	return nil
}

// readFile is a task to read and parse a single license metadata file, and to schedule
// additional tasks for reading and parsing dependencies as necessary.
func readFile(recv *receiver, file string) {
	recv.wg.Add(1)
	<-recv.task
	go func() {
		f, err := recv.rootFS.Open(file)
		if err != nil {
			recv.results <- &result{file, nil, fmt.Errorf("error opening license metadata %q: %w", file, err)}
			return
		}

		// read the file
		data, err := io.ReadAll(f)
		if err != nil {
			recv.results <- &result{file, nil, fmt.Errorf("error reading license metadata %q: %w", file, err)}
			return
		}

		tn := &TargetNode{lg: recv.lg, name: file}

		err = prototext.Unmarshal(data, &tn.proto)
		if err != nil {
			recv.results <- &result{file, nil, fmt.Errorf("error license metadata %q: %w", file, err)}
			return
		}

		// send result for this file and release task before scheduling dependencies,
		// but do not signal done to WaitGroup until dependencies are scheduled.
		recv.results <- &result{file, tn, nil}
		recv.task <- true

		// schedule tasks as necessary to read dependencies
		for _, ad := range tn.proto.Deps {
			dependency := ad.GetFile()
			// decide, signal and record whether to schedule task in critical section
			recv.lg.mu.Lock()
			_, alreadyScheduled := recv.targets[dependency]
			if !alreadyScheduled {
				recv.targets[dependency] = nil
			}
			recv.lg.mu.Unlock()
			// schedule task to read dependency file outside critical section
			if !alreadyScheduled {
				readFile(recv, dependency)
			}
		}

		// signal task done after scheduling dependencies
		recv.wg.Done()
	}()
}
