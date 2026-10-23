package citations

import (
	"testing"

	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/stretchr/testify/assert"
)

// cleanCites runs one finder over a text and returns the CleanCite of every
// citation it found, in order; nil when it found none.
func cleanCites(f Finder, text string) []string {
	var got []string
	for _, c := range f.Detect(sources.NewDoc("test", text)) {
		got = append(got, c.CleanCite())
	}
	return got
}

// TestDetector_PageIsNotTheHeadOfANumber covers issue #366. The page pattern
// \d{1,4} has no boundary after it, so a longer run of digits was cut and its
// first four digits recorded as the page. A match that a digit follows is now
// refused.
func TestDetector_PageIsNotTheHeadOfANumber(t *testing.T) {
	tests := []struct {
		name string
		text string
		want []string
	}{
		{name: "five-digit page", text: "see 12 Mass. 12345 for", want: nil},
		{name: "page glued to a following number", text: "see 12 Mass. 3451850", want: nil},
		{name: "four-digit page at the end of the text", text: "see 12 Mass. 1234", want: []string{"12 Mass. 1234"}},
		{name: "page followed by punctuation", text: "see 12 Mass. 345, 6 Pick. 7.", want: []string{"12 Mass. 345", "6 Pick. 7"}},
		{name: "page range keeps its first page", text: "39 N. Y. 436-438", want: []string{"39 N. Y. 436"}},
		{name: "page followed by a letter is kept", text: "13 N. Y. 215b", want: []string{"13 N. Y. 215"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.want, cleanCites(GenericDetector, tt.text))
		})
	}
}

func TestOCRDigitDetector_PageIsNotTheHeadOfANumber(t *testing.T) {
	assert.Nil(t, cleanCites(GenericOCRDigitDetector, "see 12 F1ed. 12345 for"))
	assert.Equal(t, []string{"12 F1ed. 1234"}, cleanCites(GenericOCRDigitDetector, "see 12 F1ed. 1234 for"))
}

func TestSingleVolDetector_PageIsNotTheHeadOfANumber(t *testing.T) {
	hob := NewSingleVolDetector("Hob.", "Hob.")
	assert.Nil(t, cleanCites(hob, "see Hob. 12345 for"))
	assert.Equal(t, []string{"Hob. 423"}, cleanCites(hob, "see Hob. 423 for"))
}

func TestYearDetector_PageIsNotTheHeadOfANumber(t *testing.T) {
	kb := NewYearDetector("K.B.", "K. B.")
	assert.Nil(t, cleanCites(kb, "see [1905] 2 K. B. 12345 for"))
	assert.Equal(t, []string{"[1905] 2 K. B. 123"}, cleanCites(kb, "see [1905] 2 K. B. 123."))
}
