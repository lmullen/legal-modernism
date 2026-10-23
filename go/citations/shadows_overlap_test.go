package citations

import (
	"testing"

	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/stretchr/testify/assert"
)

// TestRemoveShadows_NameBeforeACitation covers issue #367: a single-volume
// detector whose spelling is a surname matches the defendant of the citation
// that follows, "Jones, 12" in "Smith v. Jones, 12 Mass. 345", and the two
// spans overlap without either containing the other. The volume-less reading
// is dropped; the overlapping number can only be the second citation's volume.
func TestRemoveShadows_NameBeforeACitation(t *testing.T) {
	tests := []struct {
		name      string
		text      string
		detectors []Finder
		want      []string // CleanCite of every citation kept, in order
	}{
		{
			name:      "defendant is a single-volume spelling",
			text:      "Smith v. Jones, 12 Mass. 345.",
			detectors: []Finder{GenericDetector, NewSingleVolDetector("Jones", "Jones")},
			want:      []string{"12 Mass. 345"},
		},
		{
			// "Andrews" is reached through the stem of a longer spelling.
			name:      "defendant is reached through a stem",
			text:      "Smith v. Andrews, 12 Mass. 345.",
			detectors: []Finder{GenericDetector, NewSingleVolDetector("Andr", "Andrews")},
			want:      []string{"12 Mass. 345"},
		},
		{
			name:      "defendant ahead of a year-cited citation",
			text:      "Smith v. Jones, 1899 2 K. B. 1.",
			detectors: []Finder{NewYearDetector("K.B.", "K. B."), NewSingleVolDetector("Jones", "Jones")},
			want:      []string{"[1899] 2 K. B. 1"},
		},
		{
			// The two citations do not overlap, so both stand.
			name:      "a single-volume citation beside a volumed one",
			text:      "see Jones 45; 12 Mass. 345.",
			detectors: []Finder{GenericDetector, NewSingleVolDetector("Jones", "Jones")},
			want:      []string{"12 Mass. 345", "Jones 45"},
		},
		{
			// The generic detector reads the prose between the two numbers
			// as a citation too, "45 and 2", and that reading runs into
			// "Hob. 45" from behind. It has no capital letter, so it is not
			// the citation a name would stand ahead of, and "Hob. 45"
			// stands. The prose reading itself is kept, as it always was,
			// for the whitelist to discard.
			name:      "prose between two numbers does not take a citation with it",
			text:      "see Hob. 45 and 2 Pick. 12.",
			detectors: []Finder{GenericDetector, NewSingleVolDetector("Hob.", "Hob.")},
			want:      []string{"45 and 2", "2 Pick. 12", "Hob. 45"},
		},
		{
			// A year citation may lack a volume, but it is never a name: the
			// generic reading inside it is the shadow, as before.
			name:      "a year citation without a volume is kept",
			text:      "see 1899 K. B. 1.",
			detectors: []Finder{GenericDetector, NewYearDetector("K.B.", "K. B.")},
			want:      []string{"[1899] K. B. 1"},
		},
		{
			// The containment rule is unchanged: the tail of a volumed
			// citation is still dropped.
			name:      "single-volume reading inside a volumed citation",
			text:      "The rule in 123 Cal. 185 was different.",
			detectors: []Finder{GenericDetector, NewSingleVolDetector("Cal.", "Cal.")},
			want:      []string{"123 Cal. 185"},
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
