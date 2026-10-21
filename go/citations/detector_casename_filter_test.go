package citations

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestDetector_CaseNameFilter covers issue #373. The filter rejected a match
// containing " v. " or "Ex parte" and nothing else, so a party name joined
// by "v", "vs." or "In re" was recorded as a citation to a reporter called
// "Smith v Jones". Those rows never link; they only swell the not-whitelisted
// pool.
func TestDetector_CaseNameFilter(t *testing.T) {
	rejected := []string{
		"6 Rex v. Osborn, 30",
		"6 Smith v Jones, 30",
		"6 Smith vs. Jones, 30",
		"6 Smith vs Jones, 30",
		"6 Ex parte Wray, 30",
		"6 ex parte Wray, 30",
		"6 In re Smith, 30",
		"6 in re Smith, 30",
		"6 Ex rel. Smith, 30",
		"6 State ex rel. Smith, 30",
	}
	for _, text := range rejected {
		assert.Nil(t, cleanCites(GenericDetector, text), text)
	}

	tests := []struct {
		name string
		text string
		want []string
	}{
		{
			// The prose reading "345 See 2" is refused; the citations on
			// either side of it stand.
			name: "a signal between two citations",
			text: "see 12 Mass. 345 See 2 Pick. 12.",
			want: []string{"12 Mass. 345", "2 Pick. 12"},
		},
		{
			name: "citing between two citations",
			text: "12 Mass. 345 citing 2 Pick. 12",
			want: []string{"12 Mass. 345", "2 Pick. 12"},
		},
		{
			// Case matters: an upper-case "V." is a reporter's initial.
			name: "Vesey and Beames is not a case name",
			text: "see 12 V. & B. 345 for",
			want: []string{"12 V. & B. 345"},
		},
		{
			// A word is matched whole: "Ves." and "Sel." are not "v" and "See".
			name: "reporters that begin with a stop word's letters",
			text: "see 12 Ves. 345; 3 Sel. Cas. 4",
			want: []string{"12 Ves. 345", "3 Sel. Cas. 4"},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.want, cleanCites(GenericDetector, tt.text))
		})
	}
}
