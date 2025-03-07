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

	slog.Debug("recording batch to database", "batch_id", batch.ID, "anthropic_id", batch.Anthropic(), "num_requests", batch.NumRequests())
	err = a.PredictorStore.RecordBatch(ctx, batch)
	if err != nil {
		return err
	}

	slog.Debug("sending batch to anthropic", "batch_id", batch.ID, "anthropic_id", batch.Anthropic(), "num_requests", batch.NumRequests())
	err = batch.SendAnthropicBatch(ctx, *a.AnthropicClient)
	if err != nil {
		slog.Error("error sending batch to Anthropic", "batch_id", batch.ID, "anthropic_id", batch.Anthropic(), "num_requests", batch.NumRequests(), "error", err)
		return err
	}
	slog.Debug("batch successfully sent to Anthropic", "batch_id", batch.ID, "anthropic_id", batch.Anthropic(), "num_requests", batch.NumRequests())

	slog.Debug("updating batch in database", "batch_id", batch.ID, "anthropic_id", batch.Anthropic(), "num_requests", batch.NumRequests())
	err = a.PredictorStore.SentBatch(ctx, batch)
	if err != nil {
		return err
	}

	return nil
}
