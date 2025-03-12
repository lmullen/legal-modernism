package predictor

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v4/pgxpool"
)

// DBStore is a database store for citation objects
type PgxStore struct {
	DB *pgxpool.Pool
}

// NewDBStore returns a predictor repo using PostgreSQL with the pgx native interface.
func NewPgxStore(db *pgxpool.Pool) *PgxStore {
	return &PgxStore{
		DB: db,
	}
}

// RecordBatch saves a batch and its associated requests to the database
func (s *PgxStore) RecordBatch(ctx context.Context, b *Batch) error {
	batchQuery := `
	INSERT INTO
	predictor.batches (id, anthropic_id, created_at, last_checked, status, result)
	VALUES ($1, $2, $3, $4, $5, $6);
	`

	requestQuery := `
	INSERT INTO
	predictor.requests (id, batch_id, psmid, pageid, purpose, status, result)
	VALUES ($1, $2, $3, $4, $5, $6, $7);
	`

	tx, err := s.DB.Begin(ctx)
	if err != nil {
		return fmt.Errorf("error creating transaction recording batch in database: %w", err)
	}
	defer tx.Rollback(ctx)

	// Record the batch itself to the database
	_, err = tx.Exec(ctx, batchQuery, b.ID, b.AnthropicID, b.CreatedAt, b.LastChecked,
		b.Status, nil)
	if err != nil {
		tx.Rollback(ctx)
		return fmt.Errorf("error recording batch in database: %w", err)
	}

	// Record each request to the database
	for _, r := range b.Requests {
		select {
		case <-ctx.Done():
			tx.Rollback(context.TODO())
			return errors.New("transaction rolledback because context canceled")
		default:
			_, err := tx.Exec(ctx, requestQuery,
				r.ID, r.BatchID, r.PsmID(), r.PageID(), r.Purpose, r.Status, nil)
			if err != nil {
				tx.Rollback(ctx)
				return fmt.Errorf("error recording request in database: %w", err)
			}
		}
	}

	err = tx.Commit(ctx)
	if err != nil {
		tx.Rollback(ctx)
		return fmt.Errorf("error comitting transaction recording batches: %w", err)
	}

	return nil
}

func (s *PgxStore) SentBatch(ctx context.Context, b *Batch) error {
	batchQuery := `
	UPDATE predictor.batches
	SET anthropic_id = $1, status = $2
	WHERE id = $3;
	`

	requestQuery := `
	UPDATE predictor.requests 
	SET status = $1
	WHERE id = $2;
	`

	tx, err := s.DB.Begin(ctx)
	if err != nil {
		return fmt.Errorf("error creating transaction updating sent batch in database: %w", err)
	}
	defer tx.Rollback(ctx)

	// Update the batch itself in the database
	_, err = tx.Exec(ctx, batchQuery, b.AnthropicID, b.Status, b.ID)
	if err != nil {
		tx.Rollback(ctx)
		return fmt.Errorf("error updating batch in database: %w", err)
	}

	// Record each request to the database
	for _, r := range b.Requests {
		select {
		case <-ctx.Done():
			tx.Rollback(context.TODO())
			return errors.New("transaction rolledback because context canceled")
		default:
			_, err := tx.Exec(ctx, requestQuery, r.Status, r.ID)
			if err != nil {
				tx.Rollback(ctx)
				return fmt.Errorf("error updating request in database: %w", err)
			}
		}
	}

	err = tx.Commit(ctx)
	if err != nil {
		tx.Rollback(ctx)
		return fmt.Errorf("error comitting transaction updating batch: %w", err)
	}

	return nil
}

// BatchToCheck gets a single batch that was last checked longer ago than the
// delay. It will return the batch that was checked longest ago, which is likely
// the oldest batch created unless a batch has been checked before.
//
// An error value of sql.ErrNoRows will be returned if no such batch is available.
//
// The individual requests associated with the batch will not be returned.
func (s *PgxStore) BatchToCheck(ctx context.Context, delay time.Duration) (*Batch, error) {
	query := `SELECT id, anthropic_id, created_at, last_checked, status, result
	FROM predictor.batches
	WHERE last_checked < $1 AND (status = 'sent' OR status = 'in_progress')
	ORDER BY last_checked
	LIMIT 1;`

	var b Batch

	now := time.Now()
	checkBefore := now.Add(-delay)

	err := s.DB.QueryRow(ctx, query, checkBefore).Scan(
		&b.ID, &b.AnthropicID, &b.CreatedAt, &b.LastChecked, &b.Status, &b.Result,
	)
	if err != nil {
		return nil, err
	}

	return &b, nil
}

func (s *PgxStore) UpdateCheckedBatch(ctx context.Context, b *Batch) error {
	batchQuery := `UPDATE predictor.batches
	SET last_checked = $1,
			status = $2,
			result = $3
	WHERE id = $4;`

	itemQuery := `UPDATE predictor.requests
	SET status = $1,
	    result = $2
	WHERE id = $3`

	tx, err := s.DB.Begin(ctx)
	if err != nil {
		return fmt.Errorf("error creating transaction to update batch in database: %w", err)
	}

	_, err = tx.Exec(ctx, batchQuery, b.LastChecked, b.Status, b.Result, b.ID)
	if err != nil {
		tx.Rollback(ctx)
		return fmt.Errorf("error updating batch in database: %w", err)
	}

	for _, item := range b.ItemResults {
		_, err = tx.Exec(ctx, itemQuery, item.Status, item.Result, item.ID)
		if err != nil {
			tx.Rollback(ctx)
			return fmt.Errorf("error updating item result in database: %w", err)
		}
	}

	err = tx.Commit(ctx)
	if err != nil {
		tx.Rollback(ctx)
		return fmt.Errorf("error comitting transaction updating batch: %w", err)
	}

	return nil

}
