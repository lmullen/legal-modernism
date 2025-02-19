package main

import (
	"context"
	"log/slog"

	"github.com/lmullen/legal-modernism/go/predictor"
)

// Run does the primary work of the application
func (a *App) Run(ctx context.Context) error {
	pages, err := a.SourcesStore.GetBatchOfUnprocessedPages(ctx, a.Config.BatchSize)
	if err != nil {
		return err
	}
	batch := predictor.NewBatch(pages, "testing")
	slog.Info("recording batch to database", "batch_id", batch.ID, "anthropic_id", batch.Anthropic(), "num_requests", batch.NumRequests())
	err = a.PredictorStore.RecordBatch(ctx, batch)
	if err != nil {
		return err
	}

	return nil
}
