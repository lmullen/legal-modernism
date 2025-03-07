package predictor

import "context"

// Store is an interface describing a data store for objects relating to citations.
type Store interface {
	RecordBatch(ctx context.Context, b *Batch) error
}
