package citations

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestDetector_OrdinalIsNotAPage covers issue #370. A single-volume detector
// has no edition group and nothing checked what followed the page, so "Hob.
// 4th ed. 123" was recorded as "Hob. 4". The generic detector's edition group
// is only tried when the shorter reading fails, so "12 Mass. 4th ed." with no
// page after it was recorded as "12 Mass. 4".
func TestDetector_OrdinalIsNotAPage(t *testing.T) {
	hob := NewSingleVolDetector("Hob.", "Hob.")

	// The single-volume pattern has no edition group, so the citation is
	// lost rather than misread. A wrong page links to a wrong case; a lost
	// citation links to nothing.
	assert.Nil(t, cleanCites(hob, "see Hob. 4th ed. 123"))
	assert.Nil(t, cleanCites(hob, "see Hob. 2d ed. 123"))
	assert.Equal(t, []string{"Hob. 423"}, cleanCites(hob, "see Hob. 423 for"))

	tests := []struct {
		name string
		text string
		want []string
	}{
		{name: "edition with no page after it", text: "see 12 Mass. 4th ed. for the rule", want: nil},
		{name: "legal 2d ordinal", text: "see 12 Mass. 2d ed.", want: nil},
		{name: "edition group still reaches the page", text: "This has an edition 1 Leach, 4th ed. 484 associated with it.", want: []string{"1 Leach, 4th ed. 484"}},
		// The generic edition group knows "2nd" and "3rd" but not the legal
		// "2d" and "3d", so this citation is now lost rather than misread as
		// page 2; widening the group is a separate change.
		{name: "legal 2d edition is refused, not misread", text: "see 12 Enc. Law, 2d ed. 345 for", want: nil},
		{name: "page followed by a letter that is no ordinal", text: "13 N. Y. 215b", want: []string{"13 N. Y. 215"}},
		{name: "ordinal separated by a space is not a suffix", text: "see 12 Mass. 345 d", want: []string{"12 Mass. 345"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.want, cleanCites(GenericDetector, tt.text))
		})
	}
}
