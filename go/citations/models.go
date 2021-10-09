package citations

import (
	"context"
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

// Repository is an interface describing a data store for objects relating to citations.
type Repository interface {
	Save(ctx context.Context, c *Citation) error
}
