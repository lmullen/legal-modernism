package citations

import (
	"time"

	"github.com/google/uuid"
	"github.com/lmullen/legal-modernism/go/treatises"
)

// Citation represents a citation from a page to a particular case.
type Citation struct {
	ID           uuid.UUID
	Source       *treatises.Page
	Raw          string
	Volume       int
	ReporterAbbr string
	Page         int
	CreatedAt    time.Time
}
