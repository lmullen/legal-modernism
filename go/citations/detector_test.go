package citations

import (
	"fmt"
	"testing"

	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/stretchr/testify/assert"
)

func TestDetector_Detect(t *testing.T) {
	text := `
	This is a doc with 6 N. Y. Sup. Ct. 69 citations.
	This is a doc with citations (2 Kans. 416).
	This is a doc 71 N. C. 297 with citations.
	This is a doc with 71 N.C. 297 citations
	This doc has 39 N. Y. 436, 438 two page numbers.
	This doc has 39 N. Y. 436-438 a page range.
	`
	expected := []string{
		"6 N. Y. Sup. Ct. 69",
		"2 Kans. 416",
		"71 N. C. 297",
		"71 N.C. 297",
		"39 N. Y. 436",
		"39 N. Y. 436",
	}

	doc := sources.NewDoc("test", text)
	citations := GenericDetector.Detect(doc)
	assert.Equal(t, 6, len(citations))

	for i, v := range citations {
		assert.Equal(t, expected[i], v.CleanCite(), fmt.Sprintf("Citation %v", i))
	}
}
