package sources

import "strings"

// OCRSubstitution represents an OCR correction that should be made to an input
// document via simple string substitution.
type OCRSubstitution struct {
	Mistake    string
	Correction string
}

// CorrectOCR takes a set of OCR mistakes to be corrected via substitution and
// and fixes them in the document.
func (d *Doc) CorrectOCR(subs []*OCRSubstitution) {
	d.FullText = fixOCRSubstitutions(d.FullText, subs)
}

// This helper function does the work of replacing OCR substitutions in an
// input document.
func fixOCRSubstitutions(input string, subs []*OCRSubstitution) string {
	for _, sub := range subs {
		input = strings.ReplaceAll(input, sub.Mistake, sub.Correction)
	}
	return input
}
