package linker

import (
	"testing"

	"github.com/google/uuid"
	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestLinkCitation_StandardSpellingProbe covers issue #371: when the CAP probe
// is built from reporter_cap or a diffvols translation, the standard spelling
// was never probed against CAP or FreeLaw, although CAP keys nominative cites
// under it ("1 Allen 456" beside "83 Mass. 456"). It is probed now, after the
// translated form and before the alternates.
func TestLinkCitation_StandardSpellingProbe(t *testing.T) {
	allen := "Allen"
	mass := "Mass."
	cite := func() citations.UnlinkedCitation {
		return citations.UnlinkedCitation{ID: uuid.New(), Volume: ptr(1), ReporterAbbr: "Allen", Page: 456}
	}

	tests := []struct {
		name       string
		cite       citations.UnlinkedCitation
		whitelist  map[string]*citations.WhitelistEntry
		diffvols   map[string]map[int]*citations.DiffVolEntry
		capCites   map[string]int64
		freelaw    map[string]int64
		altAbbrs   map[string][]string
		years      Years
		wantStatus string
		wantTier   string
		wantCAPID  *int64
		wantLinked *string
	}{
		{
			name:       "reporter_cap set, CAP holds the standard-spelled key",
			cite:       cite(),
			whitelist:  map[string]*citations.WhitelistEntry{"Allen": {ReporterStandard: &allen, ReporterCAP: &mass}},
			capCites:   map[string]int64{"1 Allen 456": 111},
			wantStatus: citations.StatusLinkedCAP,
			wantTier:   citations.TierCAPDirect,
			wantCAPID:  ptr(int64(111)),
			wantLinked: ptr("1 Allen 456"),
		},
		{
			name:      "a translated hit still wins over the standard spelling",
			cite:      cite(),
			whitelist: map[string]*citations.WhitelistEntry{"Allen": {ReporterStandard: &allen, ReporterCAP: &mass, CAPDifferent: true}},
			diffvols:  map[string]map[int]*citations.DiffVolEntry{"Allen": {1: {CAPVol: 83, CAPReporter: "Mass."}}},
			capCites: map[string]int64{
				"83 Mass. 456": 111,
				"1 Allen 456":  222, // would be the same case in CAP; here a different id shows which probe won
			},
			wantStatus: citations.StatusLinkedCAP,
			wantTier:   citations.TierCAPDirect,
			wantCAPID:  ptr(int64(111)),
			wantLinked: ptr("83 Mass. 456"),
		},
		{
			name:       "CAP misses both forms, FreeLaw holds the standard-spelled key",
			cite:       cite(),
			whitelist:  map[string]*citations.WhitelistEntry{"Allen": {ReporterStandard: &allen, ReporterCAP: &mass}},
			capCites:   map[string]int64{},
			freelaw:    map[string]int64{"1 Allen 456": 333},
			wantStatus: citations.StatusLinkedCAP,
			wantTier:   citations.TierCAPFreelaw,
			wantCAPID:  ptr(int64(333)),
			wantLinked: ptr("1 Allen 456"),
		},
		{
			name:       "the standard spelling outranks an alternate",
			cite:       cite(),
			whitelist:  map[string]*citations.WhitelistEntry{"Allen": {ReporterStandard: &allen, ReporterCAP: &mass}},
			capCites:   map[string]int64{"1 Allen 456": 111, "1 Allen (Mass.) 456": 444},
			altAbbrs:   map[string][]string{"Allen": {"Allen (Mass.)"}},
			wantStatus: citations.StatusLinkedCAP,
			wantTier:   citations.TierCAPDirect,
			wantCAPID:  ptr(int64(111)),
			wantLinked: ptr("1 Allen 456"),
		},
		{
			name: "a standard-spelled hit is still refused as anachronistic",
			cite: func() citations.UnlinkedCitation {
				c := cite()
				c.SourceYear = ptr(1850)
				return c
			}(),
			whitelist:  map[string]*citations.WhitelistEntry{"Allen": {ReporterStandard: &allen, ReporterCAP: &mass}},
			capCites:   map[string]int64{"1 Allen 456": 111},
			years:      Years{CAP: map[int64]int{111: 1900}},
			wantStatus: citations.StatusNoMatch,
			wantTier:   citations.TierUSAnachronistic,
		},
		{
			// Without reporter_cap the two forms are one string, probed once
			// as before.
			name:       "no reporter_cap: the standard form is the only form",
			cite:       cite(),
			whitelist:  map[string]*citations.WhitelistEntry{"Allen": {ReporterStandard: &allen}},
			capCites:   map[string]int64{"1 Allen 456": 111},
			wantStatus: citations.StatusLinkedCAP,
			wantTier:   citations.TierCAPDirect,
			wantCAPID:  ptr(int64(111)),
			wantLinked: ptr("1 Allen 456"),
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tables := NewTables(tt.whitelist, tt.diffvols, tt.capCites, nil, tt.freelaw, tt.altAbbrs, nil, nil, nil, tt.years)
			got := tables.Link(&tt.cite)
			require.NotNil(t, got)
			assert.Equal(t, tt.wantStatus, got.Status)
			assert.Equal(t, tt.wantTier, got.MatchTier)
			assert.Equal(t, tt.wantCAPID, got.CAPCaseID)
			assert.Equal(t, tt.wantLinked, got.CiteLinked)
			if got.CiteLinked != nil && got.CiteCleaned != nil && got.CiteNormalized != nil {
				// What tells a standard-spelled link from a translated one.
				assert.True(t, *got.CiteLinked == *got.CiteCleaned || *got.CiteLinked == *got.CiteNormalized)
			}
		})
	}
}
