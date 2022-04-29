package sources

import "context"

// Store describes a datastore for sources.
type Store interface {
	GetDocFromPath(ctx context.Context, id string) (*Doc, error)
	GetTreatisePage(ctx context.Context, treatiseID string, pageID string) (*TreatisePage, error)
	GetAllTreatisePageIDs(ctx context.Context) ([]*TreatisePage, error)
	GetOCRSubstitutions(ctx context.Context) ([]*OCRSubstitution, error)
}
