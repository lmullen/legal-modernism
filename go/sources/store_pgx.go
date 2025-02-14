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

	err := p.DB.QueryRow(ctx, query, treatiseID, pageID).Scan(&dbTreatiseID, &dbID, &dbText)
	if err == pgx.ErrNoRows {
		return nil, ErrNoDocument
	}
	if err != nil {
		return nil, fmt.Errorf("problem getting treatise page: %w", err)
	}

	page := NewTreatisePage(dbID, dbTreatiseID, dbText)

	return page, nil
}

// GetAllTreatisePageIDs gets all the IDs (both document and page) for the treatises.
// However, the full text will be empty.
func (p *PgxStore) GetAllTreatisePageIDs(ctx context.Context) ([]*TreatisePage, error) {
	query := `SELECT psmid, pageid FROM moml.page_ocrtext;`
	var pages []*TreatisePage

	rows, err := p.DB.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var docID, pageID string
	for rows.Next() {
		err = rows.Scan(&docID, &pageID)
		if err != nil {
			return nil, err
		}
		page := NewTreatisePage(pageID, docID, "")
		pages = append(pages, page)
	}

	return pages, nil
}

// GetOCRSubstitutions gets a complete list of OCR substitutions from the database
func (p *PgxStore) GetOCRSubstitutions(ctx context.Context) ([]*OCRSubstitution, error) {
	query := `SELECT mistake, correction FROM legalhist.ocr_corrections;`
	var subs []*OCRSubstitution

	rows, err := p.DB.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		sub := OCRSubstitution{}
		err = rows.Scan(&sub.Mistake, &sub.Correction)
		if err != nil {
			return nil, err
		}
		subs = append(subs, &sub)
	}

	return subs, nil
}

// GetBatchOfUnprocessedPages get a set number of OCR pages from the database.
// Note that this is limited to the body pages of U.S. treatises.
func (p *PgxStore) GetBatchOfUnprocessedPages(ctx context.Context, batchSize int) ([]*TreatisePage, error) {

	if batchSize < 0 {
		return nil, ErrBatchSize
	}

	query := `
	SELECT po.psmid, po.pageid, po.ocrtext
	FROM moml.page_ocrtext po
	JOIN moml.book_info bi ON po.psmid = bi.psmid
	WHERE NOT EXISTS (
    SELECT 1 
    FROM moml.book_subject bs 
    WHERE bs.psmid = po.psmid 
    AND bs.subject IN ('UK', 'Biography', 'Collected Essays', 'Trials')
	)
	AND NOT EXISTS (
    SELECT 1 
    FROM predictor.requests r 
    WHERE r.psmid = po.psmid 
    AND r.pageid = po.pageid
	)
	LIMIT $1;
	`

	pages := make([]*TreatisePage, 0, batchSize)

	rows, err := p.DB.Query(ctx, query, batchSize)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var docID, pageID, ocrText string
	for rows.Next() {
		err = rows.Scan(&docID, &pageID, &ocrText)
		if err != nil {
			return nil, err
		}
		page := NewTreatisePage(pageID, docID, ocrText)
		pages = append(pages, page)
	}

	return pages, nil
}
