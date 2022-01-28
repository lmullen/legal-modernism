package sources

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

var input = "This is a stringy with the same stringy error twice, plus a teh."
var want = "This is a string with the same string error twice, plus a the."

var subS = &OCRSubstitution{Mistake: "stringy", Correction: "string"}
var subT = &OCRSubstitution{Mistake: "teh", Correction: "the"}
var subs = []*OCRSubstitution{subS, subT}

func Test_fixOCRSubstitutions(t *testing.T) {
	got := fixOCRSubstitutions(input, subs)
	assert.Equal(t, want, got, "Corrects multiple errors")
}

func TestDoc_CorrectOCR(t *testing.T) {
	doc := NewDoc("ID", input)
	doc.CorrectOCR(subs)
	assert.Equal(t, want, doc.Text(), "Can be applied to a document")
}
