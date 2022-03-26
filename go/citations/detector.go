package citations

import (
	"regexp"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/lmullen/legal-modernism/go/sources"
)

// Detector contains a reporter and its abbreviation, and implements a detector.
type Detector struct {
	Reporter     string
	Abbreviation string
	regex        *regexp.Regexp
}

// NewDetector creates a new citation detector and initializes its regular expression.
func NewDetector(reporter string, abbreviation string) *Detector {
	detector := &Detector{
		Reporter:     reporter,
		Abbreviation: abbreviation,
	}
	r := `\d{1,3}\s+` + abbreviation + `\s+\d{1,4}`
	detector.regex = regexp.MustCompile(r)
	return detector
}

// NewSingleVolDetector creates a new citation detector and initializes its
// regular expression. The detector will not look for a volume number
func NewSingleVolDetector(reporter string, abbreviation string) *Detector {
	detector := &Detector{
		Reporter:     reporter,
		Abbreviation: abbreviation,
	}
	r := abbreviation + `\s+\d{1,4}`
	detector.regex = regexp.MustCompile(r)
	return detector
}

// Detect finds all the examples matching the reporter's abbreviation.
func (d *Detector) Detect(doc sources.Document) []*Citation {
	matches := d.regex.FindAllString(doc.Text(), -1)

	var citations []*Citation
	for _, m := range matches {
		c := &Citation{}
		c.ID = uuid.New()
		// Get the raw string
		c.Raw = m

		// Normalize all whitespace down to a single space
		m = reSpace.ReplaceAllString(m, " ")

		// Get the volume
		vol := reVolume.FindString(m)
		c.Volume, _ = strconv.Atoi(vol)

		// Get the page
		pp := rePage.FindString(m)
		c.Page, _ = strconv.Atoi(pp)

		// Trim the string down to the reporter abbreviation
		abbr := m
		abbr = strings.Replace(abbr, vol, "", 1)
		abbr = strings.Replace(abbr, pp, "", 1)
		abbr = strings.TrimSpace(abbr)
		c.ReporterAbbr = abbr

		// Save the source
		c.Source = doc

		citations = append(citations, c)
	}
	return citations
}
