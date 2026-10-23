package citations

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestDetector_VolumeZero covers issue #374: \d{1,3} admits a volume of 0,
// which no reporter has.
func TestDetector_VolumeZero(t *testing.T) {
	assert.Nil(t, cleanCites(GenericDetector, "see 0 Mass. 12 for"))
	assert.Nil(t, cleanCites(GenericDetector, "see 00 Mass. 12 for"))
	assert.Equal(t, []string{"12 Mass. 34"}, cleanCites(GenericDetector, "see 012 Mass. 34 for"))
	assert.Equal(t, []string{"10 Mass. 34"}, cleanCites(GenericDetector, "see 10 Mass. 34 for"))
	assert.Nil(t, cleanCites(GenericOCRDigitDetector, "see 0 F1ed. 12 for"))
}
