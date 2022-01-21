package citations

import (
	"github.com/google/uuid"
	"github.com/lmullen/legal-modernism/go/sources"
)

// Citation represents a citation from a Document to a particular case.
type Citation struct {
	ID           uuid.UUID
	Source       sources.Document
	Raw          string
	Volume       int
	ReporterAbbr string
	Page         int
}
