package main

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

// TestCaseNameSourcesCoverDetector reads every CaseName* constant out of
// go/citations and requires a label and a gloss for each, so a source the
// detector starts writing is explained on the pages.
func TestCaseNameSourcesCoverDetector(t *testing.T) {
	sources := linkerConstants(t, "CaseName")
	require.NotEmpty(t, sources, "found no CaseName* constants; has the naming changed?")
	for name, value := range sources {
		info, ok := caseNameSourceByKey[value]
		require.True(t, ok, "%s = %q has no entry in caseNameSources", name, value)
		require.NotEmpty(t, info.Label, "%s has no label", value)
		require.NotEmpty(t, info.Gloss, "%s has no gloss", value)
	}
}

func TestDetectedName(t *testing.T) {
	require.Nil(t, detectedNameFrom(nil, nil, nil))
	empty := ""
	require.Nil(t, detectedNameFrom(&empty, nil, nil))

	name, source := "Smith v.\n  Jones", "direct"
	yes, no := true, false
	n := detectedNameFrom(&name, &source, nil)
	require.Equal(t, "Smith v. Jones", n.Name, "line breaks inside the name are collapsed")
	require.Equal(t, "direct", n.SourceLabel())
	require.Equal(t, "", n.Verdict(), "no case to compare with")
	require.Equal(t, "name-plain", n.Class())
	require.False(t, n.Disagrees())

	n = detectedNameFrom(&name, &source, &yes)
	require.Equal(t, "names the linked case", n.Verdict())
	require.Equal(t, "name-agree", n.Class())

	source = "parallel"
	n = detectedNameFrom(&name, &source, &no)
	require.Equal(t, "does not name the linked case", n.Verdict())
	require.Equal(t, "name-disagree", n.Class())
	require.True(t, n.Disagrees())
	require.Contains(t, n.SourceGloss(), "parallel")
}

// TestCaseNameAgreementSQL checks the shape of the fragment: both columns
// spliced in, the stop list as an array literal, and NULL when either side is.
func TestCaseNameAgreementSQL(t *testing.T) {
	sql := caseNameAgreementSQL("cu.case_name", "cc.name")
	require.Contains(t, sql, "CASE WHEN cu.case_name IS NULL OR cc.name IS NULL THEN NULL")
	require.Contains(t, sql, "regexp_replace(cu.case_name, '[^A-Za-z]+', ' ', 'g')")
	require.Contains(t, sql, "lower(cc.name) ~ ('\\m' || t || '\\M')")
	require.Contains(t, sql, "'{the,and,")
	require.Contains(t, sql, "}'::text[]")
	require.Equal(t, 1, strings.Count(sql, "length(t) >= 3"))
	for _, w := range caseNameStopWords {
		require.NotContains(t, w, " ", "stop words are single words: %q", w)
		require.Equal(t, strings.ToLower(w), w, "stop words are lowercase: %q", w)
	}
}

func TestLocateName(t *testing.T) {
	text := "as was held in Smith v.\nJones, 2 Mass. 420; and Brown v. Green, 3 Mo. 391, is to the same effect."
	cite := strings.Index(text, "2 Mass. 420")
	start, end := locateName(text, "Smith v. Jones", cite)
	require.Equal(t, "Smith v.\nJones", text[start:end], "found with its whitespace relaxed")

	cite2 := strings.Index(text, "3 Mo. 391")
	start, end = locateName(text, "Brown v. Green", cite2)
	require.Equal(t, "Brown v. Green", text[start:end])

	// A parallel cite inherits the name of the cite before it, and finds the
	// same span.
	parallel := strings.Index(text, "; and") // pretend a cite began here
	s2, e2 := locateName(text, "Smith v. Jones", parallel)
	require.Equal(t, start-start+strings.Index(text, "Smith"), s2)
	require.Equal(t, strings.Index(text, "Jones")+len("Jones"), e2)

	// The last occurrence before the citation wins.
	twice := "Smith v. Jones is cited again: Smith v. Jones, 2 Mass. 420"
	s3, _ := locateName(twice, "Smith v. Jones", strings.Index(twice, "2 Mass."))
	require.Equal(t, strings.LastIndex(twice, "Smith v. Jones"), s3)

	// Absent, out of range, or empty.
	s, e := locateName(text, "Doe v. Roe", cite)
	require.Equal(t, [2]int{-1, -1}, [2]int{s, e})
	s, e = locateName(text, "Smith v. Jones", 0)
	require.Equal(t, [2]int{-1, -1}, [2]int{s, e})
	s, e = locateName(text, "  ", cite)
	require.Equal(t, [2]int{-1, -1}, [2]int{s, e})

	// Not found beyond the window.
	far := "Smith v. Jones" + strings.Repeat(" x", nameSearchWindow) + " 2 Mass. 420"
	s, _ = locateName(far, "Smith v. Jones", strings.Index(far, "2 Mass."))
	require.Equal(t, -1, s)

	// The window never starts inside a multi-byte rune.
	utf := strings.Repeat("é", nameSearchWindow) + "Smith v. Jones, 2 Mass. 420"
	s, e = locateName(utf, "Smith v. Jones", strings.Index(utf, "2 Mass."))
	require.Equal(t, "Smith v. Jones", utf[s:e])
}

func TestHighlightCitation(t *testing.T) {
	text := "See Smith v. Jones, 2 Mass. 420 & more"
	name := &DetectedName{Name: "Smith v. Jones", Source: "direct"}
	html, found := highlightCitation(text, "2 Mass. 420", name)
	require.True(t, found)
	require.Equal(t, `See <mark class="name">Smith v. Jones</mark>, <mark>2 Mass. 420</mark> &amp; more`, string(html))

	html, found = highlightCitation(text, "2 Mass. 420", nil)
	require.False(t, found)
	require.Equal(t, `See Smith v. Jones, <mark>2 Mass. 420</mark> &amp; more`, string(html))

	html, found = highlightCitation(text, "9 Wend. 1", name)
	require.False(t, found)
	require.NotContains(t, string(html), "<mark")
}
