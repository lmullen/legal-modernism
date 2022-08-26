package citations

import (
	"context"

	"github.com/google/uuid"
)

// Store is an interface describing a data store for objects relating to citations.
type Store interface {
	SaveCitation(ctx context.Context, c *Citation) error
	GetSingleVolReporters(ctx context.Context) ([]string, error)
	GetCitationByID(ctx context.Context, ID uuid.UUID) (*Citation, error)
}
