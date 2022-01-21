package citations

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_normalizeReporter(t *testing.T) {
	scl := "18 S.C.L. 104"
	bail := "2 Bail. 104"
	var tests = []struct {
		description string
		input       string
		output      string
	}{
		{"removes multiple periods", "18 S.C..L. 104", scl},
		{"doesn't screw up a good citation", scl, scl},
		{"fixes weird spacing", "18 S. C.L. 104", scl},
		{"fixes extra weird spacing", "18 S. C. L. 104", scl},
		{"fixes missing period in abbreviation", "18 S C. L. 104", scl},
		{"fixes missing period from longer abbreviation", "2 Bail 104", bail},
		{"fixes no initial capitalization", "2 bail 104", bail},
		{"fixes internal capitalization", "2 bAil. 104", bail},
		{"doesn't screw up a good citation", bail, bail},
	}

	for i, tt := range tests {
		output := normalizeReporter(tt.input)
		assert.Equal(t, tt.output, output, fmt.Sprint("test", i, ": ", tt.description))
	}
}
