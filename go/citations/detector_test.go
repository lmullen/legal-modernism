package citations

import (
	"fmt"
	"testing"

	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestDetector_Detect(t *testing.T) {
	text := `
	This is a doc with 6 N. Y. Sup. Ct. 69 citations.
	This is a doc with citations (2 Kans. 416).
	This is a doc 71 N. C. 297 with citations.
	This is a doc with 71 N.C. 297 citations
	This doc has 39 N. Y. 436, 438 two page numbers.
	This doc has 39 N. Y. 436-438 a page range.
	This doc has 6 Watts & S. 314 as a citation.
	This doc has a two character reporter 43 Md. 295 as a citation.
	This doc has parentheses 1 C. R. (N. S.) 413 as a citation.
	This doc has something that looks like a citation 6 Ex parte Wray, 30 but isn't.
	This doc has something that looks like a citation 6 Rex v. Osborn, 30 but isn't.
	This has a citation 30 Missis. 673 that is pretty clear.
	6 Ex parte Wray, 30 Missis. 673; Street v. Tle State, 43 Missis. 1.
	This has an edition 1 Leach, 4th ed. 484 associated with it.
	This has an edition 25 Biznes, 3rd ed. 484 associated with it.
	`
	expected := []string{
		"6 N. Y. Sup. Ct. 69",
		"2 Kans. 416",
		"71 N. C. 297",
		"71 N.C. 297",
		"39 N. Y. 436",
		"39 N. Y. 436",
		"6 Watts & S. 314",
		"43 Md. 295",
		"1 C. R. (N. S.) 413",
		"30 Missis. 673",
		"30 Missis. 673",
		"43 Missis. 1",
		"1 Leach, 4th ed. 484",
		"25 Biznes, 3rd ed. 484",
	}

	doc := sources.NewDoc("test", text)
	citations := GenericDetector.Detect(doc)

	fmt.Println(citations)

	require.Equal(t, len(expected), len(citations))

	for i := range expected {
		assert.Equal(t, expected[i], citations[i].CleanCite(), fmt.Sprintf("Citation %v", i))
	}
}
