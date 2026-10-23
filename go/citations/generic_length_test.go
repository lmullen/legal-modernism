package citations

import (
	"testing"

	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/stretchr/testify/assert"
)

// TestGenericDetector_LongSpellings covers issue #369. The abbreviation was
// capped at 16 characters, and a longer spelling was not truncated but lost,
// since nothing shorter than the whole spelling is followed by the page.
func TestGenericDetector_LongSpellings(t *testing.T) {
	tests := []struct {
		name string
		text string
		want []string
	}{
		{name: "19 characters", text: "see 12 N. Y. Sup. Ct. Rep. 345 for", want: []string{"12 N. Y. Sup. Ct. Rep. 345"}},
		{name: "17 characters", text: "see 12 Smedes & Marshall 345 for", want: []string{"12 Smedes & Marshall 345"}},
		{name: "21 characters", text: "see 12 Am. & Eng. R. R. Cas. 345 for", want: []string{"12 Am. & Eng. R. R. Cas. 345"}},
		{name: "20 characters with parentheses", text: "see 12 Am. Law Reg. (N. S.) 345 for", want: []string{"12 Am. Law Reg. (N. S.) 345"}},
		{name: "16 characters, found before", text: "see 12 Pa. Superior Ct. 345 for", want: []string{"12 Pa. Superior Ct. 345"}},
		{name: "24 characters is the cap", text: "see 12 Abcd. Efgh. Ijkl. Mnop. Q 345 for", want: nil},
		{name: "edition suffix after a long spelling", text: "see 12 Am. & Eng. Enc. Law, 4th ed. 345 for", want: []string{"12 Am. & Eng. Enc. Law, 4th ed. 345"}},
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
