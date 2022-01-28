package sources

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/pgxpool"
)

// PgxStore is a datastore for sources contained in a PostgreSQL database using
// the pgx driver.
type PgxStore struct {
	DB *pgxpool.Pool
}

// NewPgxStore creates a new datastore backed by the database
func NewPgxStore(db *pgxpool.Pool) *PgxStore {
	return &PgxStore{
		DB: db,
	}
}

// GetDocFromPath is not implemented for this datastore. It will always return an error.
func (p *PgxStore) GetDocFromPath(context.Context, string, string) (*Doc, error) {
	return nil, ErrNotImplemented
}

// GetTreatisePage gets a TreatisePage from the ID of the treatise and the page
func (p *PgxStore) GetTreatisePage(ctx context.Context, treatiseID string, pageID string) (*TreatisePage, error) {
	if treatiseID == "" || pageID == "" {
		return nil, ErrInvalidID
	}

	query := `
	SELECT psmid, pageid, ocrtext FROM moml.page_ocrtext
	WHERE psmid = $1 AND pageid = $2;`

	var dbID, dbTreatiseID, dbText string

	err := p.DB.QueryRow(ctx, query, treatiseID, pageID).Scan(&dbID, &dbTreatiseID, &dbText)
	if err == pgx.ErrNoRows {
		return nil, ErrNoDocument
	}
	if err != nil {
		return nil, fmt.Errorf("Problem getting treatise page: %w", err)
	}

	page := NewTreatisePage(dbID, dbTreatiseID, dbText)

	return page, nil
}
