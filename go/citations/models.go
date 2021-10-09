package citations

import (
	"github.com/lmullen/legal-modernism/go/treatises"
)

// Citation represents a citation from a page to a particular case.
type Citation struct {
	Source       *treatises.Page
	Raw          string
	Volume       int
	ReporterAbbr string
	Page         int
}
