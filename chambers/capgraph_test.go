package main

import (
	"net/http/httptest"
	"regexp"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestAgreementRatios(t *testing.T) {
	tests := []struct {
		name              string
		a                 agreement
		recall, precision string
	}{
		{"both sides", agreement{InBoth: 62, OursOnly: 18, TheirsOnly: 38}, "62%", "78%"},
		{"no edges", agreement{}, "—", "—"},
		{"only theirs", agreement{TheirsOnly: 5}, "0%", "—"},
		{"only ours", agreement{OursOnly: 5}, "—", "0%"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			require.Equal(t, tt.recall, tt.a.RecallPct())
			require.Equal(t, tt.precision, tt.a.PrecisionPct())
		})
	}

	row := newGraphRow(1900, "1900", "", agreement{InBoth: 1, OursOnly: 1, TheirsOnly: 3})
	require.InDelta(t, 0.25, *row.Recall, 1e-9)
	require.InDelta(t, 0.5, *row.Precision, 1e-9)
	require.Nil(t, newGraphRow(1, "", "", agreement{}).Recall)

	var total agreement
	total.add(agreement{1, 2, 3})
	total.add(agreement{10, 20, 30})
	require.Equal(t, agreement{11, 22, 33}, total)
	require.Equal(t, 33, total.Ours())
	require.Equal(t, 44, total.Theirs())
	require.Equal(t, 66, total.Edges())
}

func TestQuantiles(t *testing.T) {
	require.Equal(t, [4]int{2, 7, 20, 300}, quantiles([]int64{2, 7, 20}, 300))
	require.Equal(t, [4]int{0, 0, 0, 0}, quantiles(nil, 0))
}

func TestParseCite(t *testing.T) {
	tests := []struct {
		cite     string
		volume   int
		reporter string
		page     int
		ok       bool
	}{
		{"12 Wheat. 419", 12, "Wheat.", 419, true},
		{"16 N.Y. Crim. 281", 16, "N.Y. Crim.", 281, true},
		{"1827 U.S. LEXIS 398", 1827, "U.S. LEXIS", 398, true},
		{"SCDB 1827-039", 0, "", 0, false},
		{"6 L. Ed.", 0, "", 0, false},
	}
	for _, tt := range tests {
		t.Run(tt.cite, func(t *testing.T) {
			v, r, p, ok := parseCite(tt.cite)
			require.Equal(t, tt.ok, ok)
			require.Equal(t, tt.volume, v)
			require.Equal(t, tt.reporter, r)
			require.Equal(t, tt.page, p)
		})
	}
}

func TestSameReporterStem(t *testing.T) {
	tests := []struct {
		a, b string
		want bool
	}{
		{"N. Y.", "N.Y.", true},
		{"Pa. St.", "Pa.", true},
		{"Mo. l. c.", "Mo.", true},
		{"Texas", "Tex.", true},
		{"Wheat.", "Wheat.", true},
		{"Ga.", "Gill", false},
		{"Mass.", "Md.", false},
		{"", "Mo.", false},
	}
	for _, tt := range tests {
		t.Run(tt.a+"|"+tt.b, func(t *testing.T) {
			require.Equal(t, tt.want, sameReporterStem(tt.a, tt.b))
		})
	}
}

func TestCitePattern(t *testing.T) {
	tests := []struct {
		cite, text string
		want       bool
	}{
		{"19 Mo. 233", "State v. Chunn, 19 Mo. 233, is in point.", true},
		{"53 N.Y. 111", "Smith v. People, 53 N. Y. 111.", true},
		{"7 Tex. 208", "see 7 Tex., 208, and cases", true},
		{"19 Mo. 233", "119 Mo. 233", false},
		{"19 Mo. 233", "19 Mo. 2330", false},
		{"19 Mo. 233", "19 Mo. 234", false},
		{"19 Mo. 233", "19 Mo.233", true},
		{"19 Mo. 233", "19 Mo. App. 233", false},
		{"SCDB 1827-039", "anything", false},
	}
	for _, tt := range tests {
		t.Run(tt.cite+"|"+tt.text, func(t *testing.T) {
			re := citePattern(tt.cite)
			require.Equal(t, tt.want, re != nil && re.MatchString(tt.text))
		})
	}
}

func TestExplainTheirsOnly(t *testing.T) {
	ip := func(n int) *int { return &n }
	sp := func(s string) *string { return &s }
	status := func(s string) Chip { return Chip{Status: s} }

	// Brown v. Maryland, 12 Wheat. 419 (25 U.S. 419), pages 419 to 460.
	brown := capEdge{
		Cited:     CaseRef{Source: "cap", ID: "1429870"},
		FirstPage: ip(419), LastPage: ip(460),
		Cites: []string{"25 U.S. 419", "12 Wheat. 419", "6 L. Ed. 678"},
	}

	tests := []struct {
		name  string
		cits  []capCitation
		texts []string
		kind  string
		n     int
	}{
		{
			name: "a citation normalized to the case's cite, not linked to it",
			cits: []capCitation{
				{ID: "a", Raw: "12 Wheat. 419", Volume: ip(12), ReporterAbbr: "Wheat.", Page: 419,
					Chip: Chip{Status: "no_match", Tier: "us_page_ambiguous"}, CiteNormalized: sp("25 U.S. 419")},
				{ID: "b", Raw: "4 Mass. 1", Volume: ip(4), ReporterAbbr: "Mass.", Page: 1, Chip: status("linked_cap")},
			},
			kind: explainDetected, n: 1,
		},
		{
			name: "a pin cite under the nominative volume",
			cits: []capCitation{
				{ID: "a", Raw: "12 Wheat. 441", Volume: ip(12), ReporterAbbr: "Wheat.", Page: 441, Chip: status("no_match")},
			},
			kind: explainProbable, n: 1,
		},
		{
			name: "a spelling the whitelist lacks, under the official volume",
			cits: []capCitation{
				{ID: "a", Raw: "25 U. S. Rep. 430", Volume: ip(25), ReporterAbbr: "U. S. Rep.", Page: 430, Chip: status("skipped_not_whitelisted")},
			},
			kind: explainProbable, n: 1,
		},
		{
			name: "past the case's last page",
			cits: []capCitation{
				{ID: "a", Raw: "12 Wheat. 461", Volume: ip(12), ReporterAbbr: "Wheat.", Page: 461, Chip: status("no_match")},
			},
			texts: []string{"nothing here"},
			kind:  explainNotInText,
		},
		{
			name:  "the cite in the text, nothing detected",
			texts: []string{"no citation", "the doctrine of Brown v. Maryland, 12 Wheat., 419, governs"},
			kind:  explainInText,
		},
		{
			name:  "the cite nowhere in the opinions",
			texts: []string{"Brown v. Maryland is named, but not cited."},
			kind:  explainNotInText,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			x := explainTheirsOnly(brown, tt.cits, tt.texts)
			require.Equal(t, tt.kind, x.Kind)
			require.Len(t, x.Citations, tt.n)
			require.NotEmpty(t, x.Label())
			require.NotEmpty(t, x.Gloss())
		})
	}
}

// TestCorpora checks the two corpora the linking pages serve. The schema
// names are spliced into SQL, so they must be the two expected identifiers.
func TestCorpora(t *testing.T) {
	require.Len(t, corpora, 2)
	ident := regexp.MustCompile(`^[a-z_]+(\.[a-z_]+)?$`)
	seen := map[string]bool{}
	for _, c := range corpora {
		require.False(t, seen[c.Key], "corpus keys are distinct")
		seen[c.Key] = true
		require.Regexp(t, ident, c.schema)
		require.Regexp(t, ident, c.topReporters)
	}
	require.Equal(t, "moml_citations.linking_dashboard_summary", momlCorpus.rel("linking_dashboard_summary"))
	require.Equal(t, "opinion_citations.linking_dashboard_summary", capCorpus.rel("linking_dashboard_summary"))

	// The MOML URLs are the section's original ones.
	require.Equal(t, "/linking", momlCorpus.Base)
	require.Equal(t, "/linking/tiers", momlCorpus.TiersURL())
	require.Equal(t, "/linking/whitelist", momlCorpus.WhitelistURL())
	require.Equal(t, "/api/linking-dashboard", momlCorpus.DashboardAPI())
	require.Equal(t, "/api/tiers", momlCorpus.TiersAPI())
	require.Equal(t, "/api/whitelist-extender", momlCorpus.WhitelistAPI())
	require.Equal(t, "/linking/cap/tiers", capCorpus.TiersURL())
	require.Equal(t, "/api/linking-dashboard?corpus=cap", capCorpus.DashboardAPI())
	require.Equal(t, "/linking/whitelist?corpus=cap", capCorpus.WhitelistURL())

	for q, want := range map[string]string{"": "moml", "?corpus=moml": "moml", "?corpus=cap": "cap"} {
		c, ok := corpusParam(httptest.NewRequest("GET", "/api/tiers"+q, nil))
		require.True(t, ok, q)
		require.Equal(t, want, c.Key, q)
	}
	_, ok := corpusParam(httptest.NewRequest("GET", "/api/tiers?corpus=opinion_citations", nil))
	require.False(t, ok)

	p := newLinkingPage(capCorpus, "tiers", "Match tiers: CAP opinions", "Match tiers")
	links := p.CorpusLinks()
	require.Equal(t, []navLink{
		{Label: "MOML treatises", URL: "/linking/tiers"},
		{Label: "CAP opinions", URL: "/linking/cap/tiers", Active: true},
	}, links)
}
