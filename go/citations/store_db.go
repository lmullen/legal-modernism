package citations

import (
	"context"
	"time"

	"github.com/jackc/pgx/v4/pgxpool"
)

// DBStore is a database store for citation objects
type DBStore struct {
	DB *pgxpool.Pool
}

// NewDBStore returns an citation repo using PostgreSQL with the pgx native interface.
func NewDBStore(db *pgxpool.Pool) *DBStore {
	return &DBStore{
		DB: db,
	}
}

// SaveCitation save a citation to the database
func (r *DBStore) SaveCitation(ctx context.Context, c *Citation) error {
	query := `
	INSERT INTO
	output.moml_citations (id, moml_treatise, moml_page, raw, volume, reporter_abbr, page, created_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	ON CONFLICT DO NOTHING;
	`
	_, err := r.DB.Exec(ctx, query, c.ID, c.Source.ParentID(), c.Source.ID(),
		c.Raw, c.Volume, c.ReporterAbbr, c.Page, time.Now())
	return err
}
