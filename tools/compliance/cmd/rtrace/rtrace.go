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
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"android/soong/tools/compliance"
)

var (
	sources         = newMultiString("rtrace", "Projects or metadata files to trace back from. (required; multiple allowed)")
	stripPrefix     = flag.String("strip_prefix", "", "Prefix to remove from paths. i.e. path to root")

	failNoneRequested = fmt.Errorf("\nNo license metadata files requested")
	failNoSources     = fmt.Errorf("\nNo projects or metadata files to trace back from")
	failNoLicenses    = fmt.Errorf("No licenses found")
)

type context struct {
	sources         []string
	stripPrefix     string
}

func init() {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, `Usage: %s {options} file.meta_lic {file.meta_lic...}

Outputs a space-separated Target ActsOn Origin Condition tuple for each
resolution in the graph. When -dot flag given, outputs nodes and edges
in graphviz directed graph format.

If one or more '-c condition' conditions are given, outputs the
resolution for the union of the conditions. Otherwise, outputs the
resolution for all conditions.

In plain text mode, when '-label_conditions' is requested, the Target
and Origin have colon-separated license conditions appended:
i.e. target:condition1:condition2 etc.

Options:
`, filepath.Base(os.Args[0]))
		flag.PrintDefaults()
	}
}

// newMultiString creates a flag that allows multiple values in an array.
func newMultiString(name, usage string) *multiString {
	var f multiString
	flag.Var(&f, name, usage)
	return &f
}

// multiString implements the flag `Value` interface for multiple strings.
type multiString []string

func (ms *multiString) String() string     { return strings.Join(*ms, ", ") }
func (ms *multiString) Set(s string) error { *ms = append(*ms, s); return nil }

func main() {
	flag.Parse()

	// Must specify at least one root target.
	if flag.NArg() == 0 {
		flag.Usage()
		os.Exit(2)
	}

	if len(*sources) == 0 {
		flag.Usage()
		fmt.Fprintf(os.Stderr, "\nMust specify at least 1 --rtrace source.\n")
		os.Exit(2)
	}

	ctx := &context{
		sources:         *sources,
		stripPrefix:     *stripPrefix,
	}
	_, err := traceRestricted(ctx, os.Stdout, os.Stderr, flag.Args()...)
	if err != nil {
		if err == failNoneRequested {
			flag.Usage()
		}
		fmt.Fprintf(os.Stderr, "%s\n", err.Error())
		os.Exit(1)
	}
	os.Exit(0)
}

// traceRestricted implements the rtrace utility.
func traceRestricted(ctx *context, stdout, stderr io.Writer, files ...string) (*compliance.LicenseGraph, error) {
	if len(files) < 1 {
		return nil, failNoneRequested
	}

	if len(ctx.sources) < 1 {
		return nil, failNoSources
	}

	// Read the license graph from the license metadata files (*.meta_lic).
	licenseGraph, err := compliance.ReadLicenseGraph(os.DirFS("."), stderr, files)
	if err != nil {
		return nil, fmt.Errorf("Unable to read license metadata file(s) %q: %v\n", files, err)
	}
	if licenseGraph == nil {
		return nil, failNoLicenses
	}

	sourceMap := make(map[string]struct{})
	for _, source := range ctx.sources {
		sourceMap[source] = struct{}{}
	}

	compliance.TraceTopDownConditions(licenseGraph, func(tn *compliance.TargetNode) compliance.LicenseConditionSet {
		if _, isPresent := sourceMap[tn.Name()]; isPresent {
			return compliance.ImpliesRestricted
		}
		for _, project := range tn.Projects() {
			if _, isPresent := sourceMap[project]; isPresent {
				return compliance.ImpliesRestricted
			}
		}
		return compliance.NewLicenseConditionSet()
	})

	// targetOut calculates the string to output for `target` adding `sep`-separated conditions as needed.
	targetOut := func(target *compliance.TargetNode, sep string) string {
		tOut := strings.TrimPrefix(target.Name(), ctx.stripPrefix)
		return tOut
	}

	// outputResolution prints a resolution in the requested format to `stdout`, where one can read
	// a resolution as `tname` resolves conditions named in `cnames`.
	// `tname` is the name of the target the resolution traces back to.
	// `cnames` is the list of conditions to resolve.
	outputResolution := func(tname string, cnames []string) {
		// ... one edge per line with names in a colon-separated tuple.
		fmt.Fprintf(stdout, "%s %s\n", tname, strings.Join(cnames, ":"))
	}

	// Sort the resolutions by targetname for repeatability/stability.
	actions := compliance.WalkResolutionsForCondition(licenseGraph, compliance.ImpliesShared).AllActions()
	targets := make(compliance.TargetNodeList, 0, len(actions))
	for tn := range actions {
		if tn.LicenseConditions().MatchesAnySet(compliance.ImpliesRestricted) {
			targets = append(targets, tn)
		}
	}
	sort.Sort(targets)

	// Output the sorted targets.
	for _, target := range targets {
		var tname string
		tname = targetOut(target, ":")

		// cnames accumulates the list of condition names originating at a single origin that apply to `target`.
		cnames := target.LicenseConditions().Names()

		// Output 1 line for each attachesTo+actsOn combination.
		outputResolution(tname, cnames)
	}
	fmt.Fprintf(stdout, "restricted conditions trace to %d targets\n", len(targets))
	if 0 == len(targets) {
		fmt.Fprintln(stdout, "  (check for typos in project names or metadata files)")
	}
	return licenseGraph, nil
}
