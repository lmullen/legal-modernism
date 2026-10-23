package main

import (
	"testing"

	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/stretchr/testify/require"
)

func TestLocateCitations(t *testing.T) {
	text := "See 2 Mass. 420 and 3 Mo. 391; also 2 Mass. 420 again, and 7 Ad. & El.\n\t540 there."
	cites := []PageCitation{
		{orig: "7 Ad. & El. 540"}, // whitespace differs from the text: relaxed match
		{orig: "2 Mass. 420"},     // occurs twice: first occurrence
		{orig: "9 Wend. 1"},       // absent
		{orig: "3 Mo. 391"},
		{orig: "2 Mass. 420"}, // second occurrence
	}
	got := locateCitations(text, cites)
	var order []string
	for _, c := range got {
		order = append(order, c.orig)
	}
	require.Equal(t, []string{"2 Mass. 420", "3 Mo. 391", "2 Mass. 420", "7 Ad. & El. 540", "9 Wend. 1"}, order)
	require.True(t, got[0].Found)
	require.True(t, got[3].Found, "a cite broken across a line is found with its whitespace relaxed")
	require.False(t, got[4].Found)
	require.Less(t, got[0].pos, got[2].pos, "duplicates claim successive occurrences")
	for i, c := range got {
		require.Equal(t, i+1, c.Index)
	}

	html := string(highlightSpans(text, got))
	require.Contains(t, html, `<mark id="cite-1">2 Mass. 420</mark>`)
	require.Contains(t, html, `<mark id="cite-3">2 Mass. 420</mark>`)
	require.Contains(t, html, "<mark id=\"cite-4\">7 Ad. &amp; El.\n\t540</mark>")
	require.NotContains(t, html, "cite-5", "an unfound citation gets no mark")
}

// TestHighlightSpansNames marks the case name read before each citation,
// once when two citations share it, and never over a citation.
func TestHighlightSpansNames(t *testing.T) {
	text := "Smith v. Jones, 2 Mass. 420; 3 Mo. 391. Brown v. Green, 7 Ad. & El. 540."
	cites := locateCitations(text, []PageCitation{
		{orig: "2 Mass. 420", Name: &DetectedName{Name: "Smith v. Jones", Source: "direct"}},
		{orig: "3 Mo. 391", Name: &DetectedName{Name: "Smith v. Jones", Source: "parallel"}},
		{orig: "7 Ad. & El. 540", Name: &DetectedName{Name: "Brown v. Green", Source: "direct"}},
	})
	require.True(t, cites[0].NameFound)
	require.True(t, cites[1].NameFound, "the parallel cite's name is the span before the first cite")
	require.Equal(t, cites[0].namePos, cites[1].namePos)
	require.True(t, cites[2].NameFound)

	html := string(highlightSpans(text, cites))
	require.Equal(t, 1, countOf(html, "Smith v. Jones</mark>"), "a shared name is marked once")
	require.Contains(t, html, `<mark class="name" id="name-1">Smith v. Jones</mark>, <mark id="cite-1">2 Mass. 420</mark>; <mark id="cite-2">3 Mo. 391</mark>.`)
	require.Contains(t, html, `<mark class="name" id="name-3">Brown v. Green</mark>, <mark id="cite-3">7 Ad. &amp; El. 540</mark>.`)

	// A name that would overlap a citation gives way to it.
	text = "Taylor 1, 2 Mass. 420"
	cites = locateCitations(text, []PageCitation{
		{orig: "Taylor 1"},
		{orig: "2 Mass. 420", Name: &DetectedName{Name: "Taylor 1", Source: "direct"}},
	})
	html = string(highlightSpans(text, cites))
	require.Equal(t, `<mark id="cite-1">Taylor 1</mark>, <mark id="cite-2">2 Mass. 420</mark>`, html)
}

func TestHighlightSpansNested(t *testing.T) {
	text := "cited at 1 L. R. Ch. 100 <here>"
	cites := locateCitations(text, []PageCitation{{orig: "L. R. Ch. 100"}, {orig: "1 L. R. Ch. 100"}})
	html := string(highlightSpans(text, cites))
	require.Equal(t, 1, countOf(html, "<mark"), "a span inside a longer one is not nested")
	require.Contains(t, html, `<mark id="cite-1">1 L. R. Ch. 100</mark> &lt;here&gt;`)
}

func countOf(s, sub string) int {
	n := 0
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			n++
		}
	}
	return n
}

func TestDetectorText(t *testing.T) {
	rep := sources.NewOCRReplacer([]*sources.OCRSubstitution{{Mistake: "(N. 8.)", Correction: "(N. S.)"}})
	got := detectorText(rep, "1 How. Pr. (N. 8.) 28; L. R. 5 Ch. 100")
	require.Equal(t, "1 How. Pr. (N. S.) 28; 5 L. R. Ch. 100", got)
	require.Equal(t, "as is", detectorText(nil, "as is"), "a nil replacer leaves the text alone")
}

func TestGroupLoCHeadings(t *testing.T) {
	rows := []locRow{
		{"a", "Law"}, {"z", "United States"}, {"v", "Cases."},
		{"a", "Contracts"}, {"x", "History"},
		{"a", ""},
		{"a", "Evidence (Law)"},
	}
	require.Equal(t, []string{
		"Law — United States — Cases",
		"Contracts — History",
		"Evidence (Law)",
	}, groupLoCHeadings(rows))
}
