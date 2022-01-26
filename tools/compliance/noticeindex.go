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
	"bufio"
	"crypto/md5"
	"fmt"
	"io"
	"io/fs"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

const (
	noProjectName = "\u2205"
)

var (
	nameRegexp         = regexp.MustCompile(`^\s*name\s*:\s*"(.*)"\s*$`)
	descRegexp         = regexp.MustCompile(`^\s*description\s*:\s*"(.*)"\s*$`)
	versionRegexp      = regexp.MustCompile(`^\s*version\s*:\s*"(.*)"\s*$`)
	licensesPathRegexp = regexp.MustCompile(`licen[cs]es?/`)
)

// NoticeIndex transforms license metadata into license text hashes, library
// names, and install paths indexing them for fast lookup/iteration.
type NoticeIndex struct {
	// lg identifies the license graph to which the index applies.
	lg *LicenseGraph
	// rs identifies the set of resolutions upon which the index is based.
	rs ResolutionSet
	// shipped identifies the set of target nodes shipped directly or as derivative works.
	shipped *TargetNodeSet
	// rootFS locates the root of the file system from which to read the files.
	rootFS fs.FS
	// hash maps license text filenames to content hashes
	hash map[string]hash
	// text maps content hashes to content
	text map[hash][]byte
	// hashLibInstall maps hashes to libraries to install paths.
	hashLibInstall map[hash]map[string]map[string]struct{}
	// installLibHash maps install paths to libraries to hashes.
	installLibHash map[string]map[string]map[hash]struct{}
	// libHash maps libraries to hashes.
	libHash map[string]map[hash]struct{}
	// targetHash maps target nodes to hashes.
	targetHashes map[*TargetNode]map[hash]struct{}
	// projectName maps project directory names to project name text.
	projectName map[string]string
}

// IndexLicenseTexts creates a hashed index of license texts for `lg` and `rs`
// using the files rooted at `rootFS`.
func IndexLicenseTexts(rootFS fs.FS, lg *LicenseGraph, rs ResolutionSet) (*NoticeIndex, error) {
	if rs == nil {
		rs = ResolveNotices(lg)
	}
	ni := &NoticeIndex{
		lg, rs, ShippedNodes(lg), rootFS,
		make(map[string]hash),
		make(map[hash][]byte),
		make(map[hash]map[string]map[string]struct{}),
		make(map[string]map[string]map[hash]struct{}),
		make(map[string]map[hash]struct{}),
		make(map[*TargetNode]map[hash]struct{}),
		make(map[string]string),
	}

	// index adds all license texts for `tn` to the index.
	index := func(tn *TargetNode) (map[hash]struct{}, error) {
		if hashes, ok := ni.targetHashes[tn]; ok {
			return hashes, nil
		}
		hashes := make(map[hash]struct{})
		for _, text := range tn.LicenseTexts() {
			if _, ok := ni.hash[text]; !ok {
				err := ni.addText(text)
				if err != nil {
					return nil, err
				}
			}
			hash := ni.hash[text]
			if _, ok := hashes[hash]; !ok {
				hashes[hash] = struct{}{}
			}
		}
		ni.targetHashes[tn] = hashes
		return hashes, nil
	}

	link := func(libName string, hashes map[hash]struct{}, installPaths []string) {
		if _, ok := ni.libHash[libName]; !ok {
			ni.libHash[libName] = make(map[hash]struct{})
		}
		for h := range hashes {
			if _, ok := ni.hashLibInstall[h]; !ok {
				ni.hashLibInstall[h] = make(map[string]map[string]struct{})
			}
			if _, ok := ni.libHash[libName][h]; !ok {
				ni.libHash[libName][h] = struct{}{}
			}
			for _, installPath := range installPaths {
				if _, ok := ni.installLibHash[installPath]; !ok {
					ni.installLibHash[installPath] = make(map[string]map[hash]struct{})
					ni.installLibHash[installPath][libName] = make(map[hash]struct{})
					ni.installLibHash[installPath][libName][h] = struct{}{}
				} else if _, ok = ni.installLibHash[installPath][libName]; !ok {
					ni.installLibHash[installPath][libName] = make(map[hash]struct{})
					ni.installLibHash[installPath][libName][h] = struct{}{}
				} else if _, ok = ni.installLibHash[installPath][libName][h]; !ok {
					ni.installLibHash[installPath][libName][h] = struct{}{}
				}
				if _, ok := ni.hashLibInstall[h]; !ok {
					ni.hashLibInstall[h] = make(map[string]map[string]struct{})
					ni.hashLibInstall[h][libName] = make(map[string]struct{})
					ni.hashLibInstall[h][libName][installPath] = struct{}{}
				} else if _, ok = ni.hashLibInstall[h][libName]; !ok {
					ni.hashLibInstall[h][libName] = make(map[string]struct{})
					ni.hashLibInstall[h][libName][installPath] = struct{}{}
				} else if _, ok = ni.hashLibInstall[h][libName][installPath]; !ok {
					ni.hashLibInstall[h][libName][installPath] = struct{}{}
				}
			}
		}
	}

	// returns error from walk below.
	var err error

	WalkTopDown(NoEdgeContext{}, lg, func(lg *LicenseGraph, tn *TargetNode, path TargetEdgePath) bool {
		if err != nil {
			return false
		}
		if !ni.shipped.Contains(tn) {
			return false
		}
		installPaths := getInstallPaths(tn, path)
		var hashes map[hash]struct{}
		hashes, err = index(tn)
		if err != nil {
			return false
		}
		link(ni.getLibName(tn), hashes, installPaths)
		if tn.IsContainer() {
			return true
		}

		for _, r := range rs.Resolutions(tn) {
			hashes, err = index(r.actsOn)
			if err != nil {
				return false
			}
			link(ni.getLibName(r.actsOn), hashes, installPaths)
		}
		return false
	})

	if err != nil {
		return nil, err
	}

	return ni, nil
}

// Hashes returns an ordered channel of the hashed license texts.
func (ni *NoticeIndex) Hashes() chan hash {
	c := make(chan hash)
	go func() {
		libs := make([]string, 0, len(ni.libHash))
		for libName := range ni.libHash {
			libs = append(libs, libName)
		}
		sort.Strings(libs)
		hashes := make(map[hash]struct{})
		for _, libName := range libs {
			hl := make([]hash, 0, len(ni.libHash[libName]))
			for h := range ni.libHash[libName] {
				if _, ok := hashes[h]; ok {
					continue
				}
				hashes[h] = struct{}{}
				hl = append(hl, h)
			}
			if len(hl) > 0 {
				sort.Sort(hashList{ni, libName, &hl})
				for _, h := range hl {
					c <- h
				}
			}
		}
		close(c)
	}()
	return c
}

// HashLibs returns the ordered array of library names using the license text
// hashed as `h`.
func (ni *NoticeIndex) HashLibs(h hash) []string {
	libs := make([]string, 0, len(ni.hashLibInstall[h]))
	for libName := range ni.hashLibInstall[h] {
		libs = append(libs, libName)
	}
	sort.Strings(libs)
	return libs
}

// HashLibInstalls returns the ordered array of install paths referencing
// library `libName` using the license text hashed as `h`.
func (ni *NoticeIndex) HashLibInstalls(h hash, libName string) []string {
	installs := make([]string, 0, len(ni.hashLibInstall[h][libName]))
	for installPath := range ni.hashLibInstall[h][libName] {
		installs = append(installs, installPath)
	}
	sort.Strings(installs)
	return installs
}

// HashText returns the file content of the license text hashed as `h`.
func (ni *NoticeIndex) HashText(h hash) []byte {
	return ni.text[h]
}

// getLibName returns the name of the library associated with `noticeFor`.
func (ni *NoticeIndex) getLibName(noticeFor *TargetNode) string {
	// use name from METADATA if available
	ln := ni.checkMetadata(noticeFor)
	if len(ln) > 0 {
		return ln
	}
	// use package_name: from license{} module if available
	pn := noticeFor.PackageName()
	if len(pn) > 0 {
		return pn
	}
	for _, p := range noticeFor.Projects() {
		if strings.HasPrefix(p, "prebuilts/") {
			for _, licenseText := range noticeFor.LicenseTexts() {
				if !strings.HasPrefix(licenseText, "prebuilts/") {
					continue
				}
				for r, prefix := range SafePrebuiltPrefixes {
					match := r.FindString(licenseText)
					if len(match) == 0 {
						continue
					}
					strip := SafePathPrefixes[prefix]
					if strip {
						// strip entire prefix
						match = licenseText[len(match):]
					} else {
						// strip from prebuilts/ until safe prefix
						match = licenseText[len(match)-len(prefix):]
					}
					// remove LICENSE or NOTICE or other filename
					li := strings.LastIndex(match, "/")
					if 0 < li {
						match = match[:li]
					}
					// remove *licenses/ path segment and subdirectory if in path
					if offsets := licensesPathRegexp.FindAllStringIndex(match, -1); offsets != nil && 0 < offsets[len(offsets)-1][0] {
						match = match[:offsets[len(offsets)-1][0]]
						li = strings.LastIndex(match, "/")
						if 0 < li {
							match = match[:li]
						}
					}
					return match
				}
				break
			}
		}
		for prefix, strip := range SafePathPrefixes {
			if strings.HasPrefix(p, prefix) {
				if strip {
					return p[len(prefix):]
				} else {
					return p
				}
			}
		}
	}
	// strip off [./]meta_lic from license metadata path and extract base name
	n := noticeFor.name[:len(noticeFor.name)-9]
	li := strings.LastIndex(n, "/")
	if 0 < li {
		n = n[li+1:]
	}
	return n
}

// checkMetadata tries to look up a library name from a METADATA file associated with `noticeFor`.
func (ni *NoticeIndex) checkMetadata(noticeFor *TargetNode) string {
	for _, p := range noticeFor.Projects() {
		if name, ok := ni.projectName[p]; ok {
			if name == noProjectName {
				continue
			}
			return name
		}
		f, err := ni.rootFS.Open(filepath.Join(p, "METADATA"))
		if err != nil {
			ni.projectName[p] = noProjectName
			continue
		}
		name := ""
		description := ""
		version := ""
		s := bufio.NewScanner(f)
		for s.Scan() {
			line := s.Text()
			m := nameRegexp.FindStringSubmatch(line)
			if m != nil {
				if 1 < len(m) && m[1] != "" {
					name = m[1]
				}
				if version != "" {
					break
				}
				continue
			}
			m = versionRegexp.FindStringSubmatch(line)
			if m != nil {
				if 1 < len(m) && m[1] != "" {
					version = m[1]
				}
				if name != "" {
					break
				}
				continue
			}
			m = descRegexp.FindStringSubmatch(line)
			if m != nil {
				if 1 < len(m) && m[1] != "" {
					description = m[1]
				}
			}
		}
		_ = s.Err()
		_ = f.Close()
		if name != "" {
			if version != "" {
				if version[0] == 'v' || version[0] == 'V' {
					ni.projectName[p] = name + "_" + version
				} else {
					ni.projectName[p] = name + "_v_" + version
				}
			} else {
				ni.projectName[p] = name
			}
			return ni.projectName[p]
		}
		if description != "" {
			ni.projectName[p] = description
			return ni.projectName[p]
		}
		ni.projectName[p] = noProjectName
	}
	return ""
}

// addText reads and indexes the content of a license text file.
func (ni *NoticeIndex) addText(file string) error {
	f, err := ni.rootFS.Open(filepath.Clean(file))
	if err != nil {
		return fmt.Errorf("error opening license text file %q: %w", file, err)
	}

	// read the file
	text, err := io.ReadAll(f)
	if err != nil {
		return fmt.Errorf("error reading license text file %q: %w", file, err)
	}

	hash := hash{fmt.Sprintf("%x", md5.Sum(text))}
	ni.hash[file] = hash
	if _, alreadyPresent := ni.text[hash]; !alreadyPresent {
		ni.text[hash] = text
	}

	return nil
}

// getInstallPaths returns the names of the used dependencies mapped to their
// installed locations.
func getInstallPaths(attachesTo *TargetNode, path TargetEdgePath) []string {
	if len(path) == 0 {
		installs := attachesTo.Installed()
		if 0 == len(installs) {
			installs = attachesTo.Built()
		}
		return installs
	}

	var getInstalls func(path TargetEdgePath) []string

	getInstalls = func(path TargetEdgePath) []string {
		// deps contains the output targets from the dependencies in the path
		var deps []string
		if len(path) > 1 {
			// recursively get the targets from the sub-path skipping 1 path segment
			deps = getInstalls(path[1:])
		} else {
			// stop recursion at 1 path segment
			deps = path[0].Dependency().TargetFiles()
		}
		size := 0
		prefixes := path[0].Target().TargetFiles()
		installMap := path[0].Target().InstallMap()
		sources := path[0].Target().Sources()
		for _, dep := range deps {
			found := false
			for _, source := range sources {
				if strings.HasPrefix(dep, source) {
					found = true
					break
				}
			}
			if !found {
				continue
			}
			for _, im := range installMap {
				if strings.HasPrefix(dep, im.FromPath) {
					size += len(prefixes)
					break
				}
			}
		}

		installs := make([]string, 0, size)
		for _, dep := range deps {
			found := false
			for _, source := range sources {
				if strings.HasPrefix(dep, source) {
					found = true
					break
				}
			}
			if !found {
				continue
			}
			for _, im := range installMap {
				if strings.HasPrefix(dep, im.FromPath) {
					for _, prefix := range prefixes {
						installs = append(installs, prefix+im.ContainerPath+dep[len(im.FromPath):])
					}
					break
				}
			}
		}
		return installs
	}
	allInstalls := getInstalls(path)
	installs := path[0].Target().Installed()
	if len(installs) == 0 {
		return allInstalls
	}
	result := make([]string, 0, len(allInstalls))
	for _, install := range allInstalls {
		for _, prefix := range installs {
			if strings.HasPrefix(install, prefix) {
				result = append(result, install)
			}
		}
	}
	return result
}

// hash is an opaque string derived from md5sum.
type hash struct {
	key string
}

// String returns the hexadecimal representation of the hash.
func (h hash) String() string {
	return h.key
}

// hashList orders an array of hashes
type hashList struct {
	ni      *NoticeIndex
	libName string
	hashes  *[]hash
}

// Len returns the count of elements in the slice.
func (l hashList) Len() int { return len(*l.hashes) }

// Swap rearranges 2 elements of the slice so that each occupies the other's
// former position.
func (l hashList) Swap(i, j int) { (*l.hashes)[i], (*l.hashes)[j] = (*l.hashes)[j], (*l.hashes)[i] }

// Less returns true when the `i`th element is lexicographically less than
// the `j`th element.
func (l hashList) Less(i, j int) bool {
	var insti, instj int
	if 0 < len(l.libName) {
		insti = len(l.ni.hashLibInstall[(*l.hashes)[i]][l.libName])
		instj = len(l.ni.hashLibInstall[(*l.hashes)[j]][l.libName])
	}
	if insti == instj {
		leni := len(l.ni.text[(*l.hashes)[i]])
		lenj := len(l.ni.text[(*l.hashes)[j]])
		if leni == lenj {
			// all else equal, just order by hash value
			return (*l.hashes)[i].key < (*l.hashes)[j].key
		}
		// put shortest texts first within same # of installs
		return leni < lenj
	}
	// reverse order of # installs so that most popular appears first
	return instj < insti
}
