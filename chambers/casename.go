package main

import (
	"regexp"
	"strings"

	"github.com/lmullen/legal-modernism/go/citations"
)

// The case name the detector read before a citation (issue #387):
// citations_unlinked.case_name, with case_name_source saying how it was found.
// The pages show the name beside the citation and, when the citation linked,
// say whether the name agrees with the case the linker chose. The verdict
// comes from one SQL fragment, caseNameAgreementSQL, that every query shares,
// so the citation list can filter on it and every page shows the same answer.
// Issue #392.

// DetectedName is a citation's recorded case name and its verdict.
type DetectedName struct {
	Name   string
	Source string // direct, parallel or table (citations.CaseName*)
	// Agrees is whether the name agrees with the linked case: nil when the
	// citation linked to nothing with a name to compare against.
	Agrees *bool
}

// detectedNameFrom builds a DetectedName from the nullable columns a query
// selects: the name, its source and the agreement expression. It is nil when
// the citation has no name.
func detectedNameFrom(name, source *string, agrees *bool) *DetectedName {
	if name == nil || *name == "" {
		return nil
	}
	n := &DetectedName{Name: cleanRaw(*name), Agrees: agrees}
	if source != nil {
		n.Source = *source
	}
	return n
}

// caseNameSourceInfo describes one way the name was found.
type caseNameSourceInfo struct {
	Key   string
	Label string
	Gloss string
}

// caseNameSources lists the sources in order of how directly the name was
// read. The keys are the constants the detector writes (go/citations/casename.go).
var caseNameSources = []caseNameSourceInfo{
	{citations.CaseNameDirect, "direct", "the name printed before this citation"},
	{citations.CaseNameParallel, "parallel", "inherited from the preceding parallel cite: this citation follows another with only punctuation between"},
	{citations.CaseNameTable, "table", "the plaintiff was taken from the row above in a table of cases that elides a repeated plaintiff"},
}

var caseNameSourceByKey = func() map[string]caseNameSourceInfo {
	m := make(map[string]caseNameSourceInfo, len(caseNameSources))
	for _, s := range caseNameSources {
		m[s.Key] = s
	}
	return m
}()

// SourceLabel is the source in a word.
func (n DetectedName) SourceLabel() string {
	if s, ok := caseNameSourceByKey[n.Source]; ok {
		return s.Label
	}
	return n.Source
}

// SourceGloss says how the name was found, for a tooltip.
func (n DetectedName) SourceGloss() string { return caseNameSourceByKey[n.Source].Gloss }

// Verdict is the agreement in words, empty when there was nothing to compare
// the name with.
func (n DetectedName) Verdict() string {
	switch {
	case n.Agrees == nil:
		return ""
	case *n.Agrees:
		return "names the linked case"
	default:
		return "does not name the linked case"
	}
}

// Class is the colour class of the name: green when it agrees with the
// linked case, red when it does not, plain when there is no case to compare.
func (n DetectedName) Class() string {
	switch {
	case n.Agrees == nil:
		return "name-plain"
	case *n.Agrees:
		return "name-agree"
	default:
		return "name-disagree"
	}
}

// Disagrees reports a name that contradicts the linked case.
func (n DetectedName) Disagrees() bool { return n.Agrees != nil && !*n.Agrees }

// caseNameStopWords are the words of a case name that say nothing about which
// case it is: the versus, the parties every jurisdiction has (State, People,
// Commonwealth, United States), the corporate and procedural words (Co.,
// Railroad, Insurance, Estate, Matter), and the honorifics. A detected name
// agrees with a case through some other word.
var caseNameStopWords = []string{
	"the", "and", "versus", "vs",
	"state", "people", "commonwealth", "united", "states", "city", "county", "town", "township", "village",
	"board", "school", "district", "commissioners", "trustees", "mayor", "inhabitants",
	"company", "co", "inc", "corporation", "bank", "railroad", "railway", "insurance", "ins", "trust",
	"national", "first", "second", "union", "american", "pacific", "central", "southern", "northern",
	"western", "eastern", "life", "mutual", "savings", "loan", "manufacturing", "mfg",
	"estate", "matter", "case", "administrator", "administratrix", "executor", "executrix", "executors",
	"guardian", "assignee", "receiver", "lessee", "heirs", "others", "another", "same", "rel",
	"parte", "petition", "application", "appeal", "cause",
	"mrs", "miss", "jr", "sr", "esq", "van", "von", "der", "del", "des",
}

// caseNameStopSQL is the stop list as a SQL array literal.
var caseNameStopSQL = "'{" + strings.Join(caseNameStopWords, ",") + "}'::text[]"

// caseNameAgreementSQL is a boolean SQL expression: whether the detected name
// in the column name agrees with the case name in fullName. They agree when a
// significant token of the detected name -- three or more letters, not a stop
// word -- occurs as a word in the case's name; the test is loose on purpose,
// since the treatises' OCR misspells most names a little, and it still agrees
// with a case picked at random only 0.7% of the time (#391). NULL when
// either side is NULL, so an unlinked citation has no verdict.
func caseNameAgreementSQL(name, fullName string) string {
	return `(CASE WHEN ` + name + ` IS NULL OR ` + fullName + ` IS NULL THEN NULL ELSE EXISTS (
  SELECT 1 FROM unnest(string_to_array(lower(regexp_replace(` + name + `, '[^A-Za-z]+', ' ', 'g')), ' ')) AS t
  WHERE length(t) >= 3 AND t <> ALL(` + caseNameStopSQL + `) AND lower(` + fullName + `) ~ ('\m' || t || '\M')
) END)`
}

// caseFullNameSQL is the full name of the case on a row joined by
// caseMetaJoins, the side a detected name is compared against: CAP's full
// name rather than its short title, both names of an English Reports case,
// the code reporter's name, or a stub's curated party names.
func caseFullNameSQL() string {
	return `COALESCE(cc.name, NULLIF(concat_ws(' ', er.murrell_title, er.er_name), ''), code.name, sm.party_names)`
}

// nameSearchWindow is how far before a citation its name is looked for in the
// page text: the scan reads about fourteen words back, and a long name with
// the OCR's line breaks fits comfortably in this many bytes.
const nameSearchWindow = 240

// locateName finds the span of a citation's recorded name in the text before
// the citation that begins at citeStart: the last occurrence that ends before
// the citation, within nameSearchWindow bytes, with any run of whitespace in
// the name matching any other. (-1, -1) when it is not there. A name read
// from a parallel cite or a table row sits before an earlier citation and is
// found the same way, so two citations may share one span.
func locateName(text, name string, citeStart int) (int, int) {
	fields := strings.Fields(name)
	if len(fields) == 0 || citeStart <= 0 || citeStart > len(text) {
		return -1, -1
	}
	from := citeStart - nameSearchWindow
	if from < 0 {
		from = 0
	}
	// Do not start inside a multi-byte rune.
	for from > 0 && from < len(text) && !isRuneStart(text[from]) {
		from--
	}
	window := text[from:citeStart]
	quoted := make([]string, len(fields))
	for i, f := range fields {
		quoted[i] = regexp.QuoteMeta(f)
	}
	re, err := regexp.Compile(strings.Join(quoted, `\s+`))
	if err != nil {
		return -1, -1
	}
	locs := re.FindAllStringIndex(window, -1)
	if len(locs) == 0 {
		return -1, -1
	}
	last := locs[len(locs)-1]
	return from + last[0], from + last[1]
}

func isRuneStart(b byte) bool { return b&0xC0 != 0x80 }
