package sources

import "context"

// Store describes a datastore for sources.
type Store interface {
	GetDocByID(ctx context.Context, id string) (*Doc, error)
}
