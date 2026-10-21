package citations

import (
	"testing"

	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/stretchr/testify/assert"
)

// TestRemoveShadows_OverlappingVolumedReadings covers issue #368: when the
// separator between two citations is lost, the generic detector reads the
// first citation's page as the second's volume, and both readings were kept.
// The earlier one stands.
func TestRemoveShadows_OverlappingVolumedReadings(t *testing.T) {
	tests := []struct {
		name      string
		text      string
		detectors []Finder
		want      []string
	}{
		{
			name:      "lost separator",
			text:      "12 Mass. 345 Gray 7",
			detectors: []Finder{GenericDetector},
			want:      []string{"12 Mass. 345"},
		},
		{
			// The prose reading "345 and S. C. 2" begins inside the first
			// citation and is dropped; the second citation does not begin
			// inside the first, so it stands.
			name:      "prose bridging two citations takes neither with it",
			text:      "see 12 Mass. 345 and S. C. 2 Pick. 12.",
			detectors: []Finder{GenericDetector},
			want:      []string{"12 Mass. 345", "2 Pick. 12"},
		},
		{
			// A prose reading with no capital letter neither blocks nor is
			// blocked by anything in particular: "45 and 2" stands, for the
			// whitelist to discard, and so does "2 Pick. 12".
			name:      "prose without a capital letter blocks nothing",
			text:      "see Hob. 45 and 2 Pick. 12.",
			detectors: []Finder{GenericDetector, NewSingleVolDetector("Hob.", "Hob.")},
			want:      []string{"45 and 2", "2 Pick. 12", "Hob. 45"},
		},
		{
			// A bare year ahead of a year-cited reporter also reads as the
			// page of the citation before it. The year citation is the
			// better reading and is never dropped; the four-digit page is
			// left for the linker, as before.
			name:      "a year citation is never dropped",
			text:      "see 12 Mass. 1899 2 K. B. 1.",
			detectors: []Finder{GenericDetector, NewYearDetector("K.B.", "K. B.")},
			want:      []string{"12 Mass. 1899", "[1899] 2 K. B. 1"},
		},
		{
			name:      "separated citations are untouched",
			text:      "see 12 Mass. 345; 6 Gray 7.",
			detectors: []Finder{GenericDetector},
			want:      []string{"12 Mass. 345", "6 Gray 7"},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			doc := sources.NewDoc("test", tt.text)
			var found []*Citation
			for _, d := range tt.detectors {
				found = append(found, d.Detect(doc)...)
			}
			var got []string
			for _, c := range RemoveShadows(found) {
				got = append(got, c.CleanCite())
			}
			assert.Equal(t, tt.want, got)
		})
	}
}
