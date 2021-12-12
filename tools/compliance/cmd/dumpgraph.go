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

package main

import (
	"compliance"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

var (
	graphViz        = flag.Bool("dot", false, "Whether to output graphviz (i.e. dot) format.")
	labelConditions = flag.Bool("label_conditions", false, "Whether to label target nodes with conditions.")
	stripPrefix     = flag.String("strip_prefix", "", "Prefix to remove from paths. i.e. path to root")

	failNoneRequested = fmt.Errorf("\nNo license metadata files requested")
	failNoLicenses = fmt.Errorf("No licenses found")
)

type context struct {
	graphViz        bool
	labelConditions bool
	stripPrefix     string
}

func init() {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, `Usage: %s {options} file.meta_lic {file.meta_lic...}

Outputs space-separated Target Dependency Annotations tuples for each
edge in the license graph. When -dot flag given, outputs the nodes and
edges in graphViz directed graph format.

In plain text mode, multiple values within a field are colon-separated.
e.g. multiple annotations appear as annotation1:annotation2:annotation3
or when -label_conditions is requested, Target and Dependency become
target:condition1:condition2 etc.

Options:
`, filepath.Base(os.Args[0]))
		flag.PrintDefaults()
	}
}

func main() {
	flag.Parse()

	// Must specify at least one root target.
	if flag.NArg() == 0 {
		flag.Usage()
		os.Exit(2)
	}

	ctx := &context{*graphViz, *labelConditions, *stripPrefix}

	err := dumpGraph(ctx, os.Stdout, os.Stderr, flag.Args()...)
	if err != nil {
		if err == failNoneRequested {
			flag.Usage()
		}
		fmt.Fprintf(os.Stderr, "%s\n", err.Error())
		os.Exit(1)
	}
	os.Exit(0)
}

// dumpGraph implements the dumpgraph utility.
func dumpGraph(ctx *context, stdout, stderr io.Writer, files ...string) error {
	if len(files) < 1 {
		return failNoneRequested
	}

	// Read the license graph from the license metadata files (*.meta_lic).
	licenseGraph, err := compliance.ReadLicenseGraph(os.DirFS("."), stderr, files)
	if err != nil {
		return fmt.Errorf("Unable to read license metadata file(s) %q: %w\n", files, err)
	}
	if licenseGraph == nil {
		return failNoLicenses
	}

	// Sort the edges of the graph.
	edges := licenseGraph.Edges()
	sort.Sort(edges)

	// nodes maps license metadata file names to graphViz node names when ctx.graphViz is true.
	var nodes map[string]string
	n := 0

	// targetOut calculates the string to output for `target` separating conditions as needed using `sep`.
	targetOut := func(target *compliance.TargetNode, sep string) string {
		tOut := strings.TrimPrefix(target.Name(), ctx.stripPrefix)
		if ctx.labelConditions {
			conditions := target.LicenseConditions().Names()
			sort.Strings(conditions)
			if len(conditions) > 0 {
				tOut += sep + strings.Join(conditions, sep)
			}
		}
		return tOut
	}

	// makeNode maps `target` to a graphViz node name.
	makeNode := func(target *compliance.TargetNode) {
		tName := target.Name()
		if _, ok := nodes[tName]; !ok {
			nodeName := fmt.Sprintf("n%d", n)
			nodes[tName] = nodeName
			fmt.Fprintf(stdout, "\t%s [label=\"%s\"];\n", nodeName, targetOut(target, "\\n"))
			n++
		}
	}

	// If graphviz output, map targets to node names, and start the directed graph.
	if ctx.graphViz {
		nodes = make(map[string]string)
		targets := licenseGraph.Targets()
		sort.Sort(targets)

		fmt.Fprintf(stdout, "strict digraph {\n\trankdir=RL;\n")
		for _, target := range targets {
			makeNode(target)
		}
	}

	// Print the sorted edges to stdout ...
	for _, e := range edges {
		// sort the annotations for repeatability/stability
		annotations := e.Annotations().AsList()
		sort.Strings(annotations)

		tName := e.Target().Name()
		dName := e.Dependency().Name()

		if ctx.graphViz {
			// ... one edge per line labelled with \\n-separated annotations.
			tNode := nodes[tName]
			dNode := nodes[dName]
			fmt.Fprintf(stdout, "\t%s -> %s [label=\"%s\"];\n", dNode, tNode, strings.Join(annotations, "\\n"))
		} else {
			// ... one edge per line with annotations in a colon-separated tuple.
			fmt.Fprintf(stdout, "%s %s %s\n", targetOut(e.Target(), ":"), targetOut(e.Dependency(), ":"), strings.Join(annotations, ":"))
		}
	}

	// If graphViz output, rank the root nodes together, and complete the directed graph.
	if ctx.graphViz {
		fmt.Fprintf(stdout, "\t{rank=same;")
		for _, f := range files {
			fName := f
			if !strings.HasSuffix(fName, ".meta_lic") {
				fName += ".meta_lic"
			}
			if fNode, ok := nodes[fName]; ok {
				fmt.Fprintf(stdout, " %s", fNode)
			}
		}
		fmt.Fprintf(stdout, "}\n}\n")
	}
	return nil
}
