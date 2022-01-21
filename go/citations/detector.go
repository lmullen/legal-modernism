package citations

import (
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
)

var volume = regexp.MustCompile(`^\d+`)
var page = regexp.MustCompile(`\d+$`)
var abbr = regexp.MustCompile(`\s*[\w\.]+\s*`)
var space = regexp.MustCompile(`\s+`)

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

// Detect finds all the examples matching the reporter's abbreviation.
func (d *Detector) Detect(p *treatises.Page) []*Citation {
	matches := d.regex.FindAllString(p.Text(), -1)

	var citations []*Citation
	for _, m := range matches {
		c := &Citation{}
		c.ID = uuid.New()
		// Get the raw string
		c.Raw = m

		// Normalize all whitespace down to a single space
		m = space.ReplaceAllString(m, " ")

		// Get the volume
		vol := volume.FindString(m)
		c.Volume, _ = strconv.Atoi(vol)

		// Get the page
		pp := page.FindString(m)
		c.Page, _ = strconv.Atoi(pp)

		// Trim the string down to the reporter abbreviation
		abbr := m
		abbr = strings.Replace(abbr, vol, "", 1)
		abbr = strings.Replace(abbr, pp, "", 1)
		abbr = strings.TrimSpace(abbr)
		c.ReporterAbbr = abbr

		// Save the source
		c.Source = p

		// Timestamp
		c.CreatedAt = time.Now().UTC()

		citations = append(citations, c)
	}
	return citations
}
