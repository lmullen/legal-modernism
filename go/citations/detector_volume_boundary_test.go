package citations

import (
	"testing"

	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/stretchr/testify/assert"
)

// TestDetector_VolumeIsNotTheTailOfANumber covers issue #365. The starting
// places are \d{1,3}\s found leftmost and non-overlapping, so "1850 Mass. 12"
// had its one starting place at the "8" and was recorded as volume 850. A
// start whose previous byte is a letter or digit is now refused, as
// YearDetector has always refused one after a digit.
func TestDetector_VolumeIsNotTheTailOfANumber(t *testing.T) {
	tests := []struct {
		name string
		text string
		want []string // CleanCite of every citation found, in order
	}{
		{
			name: "year ahead of a reporter",
			text: "In 1850 Mass. 12 the court held",
			want: nil,
		},
		{
			name: "year at a line end, reporter on the next line",
			text: "decided 1850\n\t\t\tPick. 12 and so on",
			want: nil,
		},
		{
			name: "OCR letter glued to the volume",
			text: "see l2 Mass. 12 for the rule",
			want: nil,
		},
		{
			name: "a real citation after the refused one is still found",
			text: "In 1850 Mass. 12; see 2 Pick. 34",
			want: []string{"2 Pick. 34"},
		},
		{
			name: "punctuation ahead of the volume is a boundary",
			text: "cases (2 Kans. 416), §12 Mass. 34; p.5 Pick. 6",
			want: []string{"2 Kans. 416", "12 Mass. 34", "5 Pick. 6"},
		},
		{
			name: "a non-ASCII character ahead of the volume is a boundary",
			text: "Résumé—12 Mass. 34",
			want: []string{"12 Mass. 34"},
		},
		{
			name: "text begins with the volume",
			text: "12 Mass. 34",
			want: []string{"12 Mass. 34"},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var got []string
			for _, c := range GenericDetector.Detect(sources.NewDoc("test", tt.text)) {
				got = append(got, c.CleanCite())
			}
			assert.Equal(t, tt.want, got)
		})
	}
}

// The OCR-digit detector shares Detect, so it is bounded the same way.
func TestOCRDigitDetector_VolumeIsNotTheTailOfANumber(t *testing.T) {
	doc := sources.NewDoc("test", "In 1850 F1ed. 12 and 2 F1ed. 34")
	var got []string
	for _, c := range GenericOCRDigitDetector.Detect(doc) {
		got = append(got, c.CleanCite())
	}
	assert.Equal(t, []string{"2 F1ed. 34"}, got)
}
