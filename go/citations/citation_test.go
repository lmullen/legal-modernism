package citations

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_normalizeReporter(t *testing.T) {
	var tests = []struct {
		description string
		input       string
		output      string
	}{

		{"removes multiple periods", "S.C..L.", "S.C.L."},
		{"doesn't screw up a good citation", "S.C.L.", "S.C.L."},
		{"fixes extra weird spacing", "S.   C. L.", "S. C. L."},
	}

	for i, tt := range tests {
		output := normalizeReporter(tt.input)
		assert.Equal(t, tt.output, output, fmt.Sprint("test", i, ": ", tt.description))
	}
}
