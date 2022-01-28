package sources

import (
	"encoding/csv"
	"fmt"
	"os"
	"strings"
)

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

// OCRSubstitutionsFromCSV reads OCR substitutions from a CSV file.
func OCRSubstitutionsFromCSV(path string) ([]*OCRSubstitution, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("Error opening CSV: %w", err)
	}
	defer f.Close()

	r := csv.NewReader(f)
	r.FieldsPerRecord = 2
	inputs, err := r.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("Error reading CSV: %w", err)
	}

	output := make([]*OCRSubstitution, len(inputs))

	for i, input := range inputs {
		output[i] = &OCRSubstitution{Mistake: input[0], Correction: input[1]}
	}

	return output, nil
}
