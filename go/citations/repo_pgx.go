package citations

import (
	"context"

	"github.com/jackc/pgx/v4/pgxpool"
)

// Repo is a data store using PostgreSQL with the pgx native interface.
type Repo struct {
	db *pgxpool.Pool
}

// NewPgxRepo returns an citation repo using PostgreSQL with the pgx native interface.
func NewPgxRepo(db *pgxpool.Pool) *Repo {
	return &Repo{
		db: db,
	}
}

// Save serializes a citation to the database.
func (r *Repo) Save(ctx context.Context, c *Citation) error {
	query := `
	INSERT INTO 
	output.moml_citations (id, moml_treatise, moml_page, raw, volume, reporter_abbr, page, created_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	ON CONFLICT DO NOTHING;
	`
	_, err := r.db.Exec(ctx, query, c.ID, c.Source.DocID, c.Source.PageID,
		c.Raw, c.Volume, c.ReporterAbbr, c.Page, c.CreatedAt)
	return err
}
