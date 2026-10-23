package linker

import (
	"testing"

	"github.com/google/uuid"
	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/stretchr/testify/assert"
)

// TestBuildAltCites_YearPrefix covers issue #372: the alternate-spelling
// probes of a reporter cited by year lead with the year, as every other probe
// of such a reporter does, and a year before cited_by_year_from stays out, as
// it does everywhere else.
func TestBuildAltCites_YearPrefix(t *testing.T) {
	std := "K.B."
	entry := &citations.WhitelistEntry{ReporterStandard: &std, CitedByYearFrom: 1901}
	alts := []string{"KB", "K. B."}

	cited := citations.UnlinkedCitation{Volume: ptr(2), ReporterAbbr: "K.B.", Page: 1, Year: ptr(1905)}
	assert.Equal(t, []string{"[1905] 2 KB 1", "[1905] 2 K. B. 1"}, buildAltCites(&cited, entry, alts))

	bare := citations.UnlinkedCitation{ReporterAbbr: "K.B.", Page: 1, Year: ptr(1905)}
	assert.Equal(t, []string{"[1905] KB 1", "[1905] K. B. 1"}, buildAltCites(&bare, entry, alts))

	early := citations.UnlinkedCitation{Volume: ptr(2), ReporterAbbr: "K.B.", Page: 1, Year: ptr(1890)}
	assert.Equal(t, []string{"2 KB 1", "2 K. B. 1"}, buildAltCites(&early, entry, alts),
		"a year before cited_by_year_from is decoration on a volume-cited citation")

	noYear := citations.UnlinkedCitation{Volume: ptr(2), ReporterAbbr: "K.B.", Page: 1}
	assert.Equal(t, []string{"2 KB 1", "2 K. B. 1"}, buildAltCites(&noYear, entry, alts))

	plain := &citations.WhitelistEntry{ReporterStandard: &std}
	assert.Equal(t, []string{"2 KB 1", "2 K. B. 1"}, buildAltCites(&cited, plain, alts),
		"a reporter never cited by year gets no prefix")

	assert.Nil(t, buildAltCites(&cited, entry, nil))
}

// A year-cited reporter on the US route reaches a CAP key under an alternate
// spelling only with the year in the string.
func TestLinkCitation_AltSpellingCarriesTheYear(t *testing.T) {
	std := "K.B."
	whitelist := map[string]*citations.WhitelistEntry{"K.B.": {ReporterStandard: &std, CitedByYearFrom: 1901}}
	capCites := map[string]int64{"[1905] 2 KB 1": 111}
	altAbbrs := map[string][]string{"K.B.": {"KB"}}
	tables := NewTables(whitelist, nil, capCites, nil, nil, altAbbrs, nil, nil, nil, Years{})

	c := citations.UnlinkedCitation{ID: uuid.New(), Volume: ptr(2), ReporterAbbr: "K.B.", Page: 1, Year: ptr(1905)}
	got := tables.Link(&c)
	assert.Equal(t, citations.StatusLinkedCAP, got.Status)
	assert.Equal(t, citations.TierCAPAltSpelling, got.MatchTier)
	assert.Equal(t, ptr("[1905] 2 KB 1"), got.CiteLinked)
}
