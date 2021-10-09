package citations

import (
	"regexp"
	"strconv"
	"strings"

	"github.com/lmullen/legal-modernism/go/treatises"
)

var volume = regexp.MustCompile(`^\d+`)
var page = regexp.MustCompile(`\d+$`)
var abbr = regexp.MustCompile(`\s*[\w\.]+\s*`)

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
	r := `\d{1,4}\s+` + abbreviation + `\s+\d{1,4}`
	detector.regex = regexp.MustCompile(r)
	return detector
}

// Detect finds all the examples matching the reporter's abbreviation.
func (d *Detector) Detect(p *treatises.Page) []Citation {
	matches := d.regex.FindAllString(p.Text(), -1)
	citations := make([]Citation, len(matches))
	for i, m := range matches {
		// Get the raw string
		citations[i].Raw = m

		// Get the volume
		vol := volume.FindString(m)
		citations[i].Volume, _ = strconv.Atoi(vol)

		// Get the page
		pp := page.FindString(m)
		citations[i].Page, _ = strconv.Atoi(pp)

		// Trim the string down to the reporter abbreviation
		abbr := m
		abbr = strings.Replace(abbr, vol, "", 1)
		abbr = strings.Replace(abbr, pp, "", 1)
		abbr = strings.TrimSpace(abbr)
		citations[i].ReporterAbbr = abbr

		// Save the source
		citations[i].Source = p
	}
	return citations
}
