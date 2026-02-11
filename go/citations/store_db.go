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
	moml_citations.citations_unlinked (id, moml_treatise, moml_page, raw, volume, reporter_abbr, page, created_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	ON CONFLICT DO NOTHING;
	`
	_, err := r.DB.Exec(ctx, query, c.ID, c.Source.ParentID(), c.Source.ID(),
		c.Raw, c.Volume, c.ReporterAbbr, c.Page, time.Now())
	return err
}

// GetSingleVolReporters gets the abbreviations for all the single volume
// reporters in the database.
func (r *DBStore) GetSingleVolReporters(ctx context.Context) ([]string, error) {
	query := `SELECT alt_abbr FROM legalhist.reporters_single_volume_abbr;`
	var abbreviations []string

	rows, err := r.DB.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var abbr string
	for rows.Next() {
		err = rows.Scan(&abbr)
		if err != nil {
			return nil, err
		}
		abbreviations = append(abbreviations, abbr)
	}

	return abbreviations, nil
}
