package main

import "regexp"

// CiteDetector contains a reporter and its abbreviation, and implements a detector.
type CiteDetector struct {
	Reporter     string
	Abbreviation string
	regex        *regexp.Regexp
}

// NewCiteDetector creates a new citation detector and initializes its regular expression.
func NewCiteDetector(reporter string, abbreviation string) *CiteDetector {
	detector := &CiteDetector{
		Reporter:     reporter,
		Abbreviation: abbreviation,
	}

	r := `\d{1,4}\s+` + abbreviation + `\s+\d{1,4}`
	detector.regex = regexp.MustCompile(r)

	return detector
}

// Detect finds all the examples matching the reporter's abbreviation.
func (cd *CiteDetector) Detect(doc Document) []string {
	return cd.regex.FindAllString(doc.Text(), -1)
}
