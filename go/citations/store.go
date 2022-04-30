package citations

import "context"

// Store is an interface describing a data store for objects relating to citations.
type Store interface {
	SaveCitation(ctx context.Context, c *Citation) error
	GetSingleVolReporters(ctx context.Context) ([]string, error)
}
