package main

import (
	"context"
	"log/slog"

	"github.com/lmullen/legal-modernism/go/predictor"
)

// SendBatches identifies work to be done from the database and sends batches to
// Anthropic one at at time.
func (a *App) SendBatches(ctx context.Context) error {

	slog.Info("started sending batches to Anthropic",
		"max_batches", a.Config.MaxBatches)

	for i := range a.Config.MaxBatches {
		// Check whether the app has been canceled before sending each batch
		select {

		case <-ctx.Done():
			slog.Info("canceled sending batches to Anthropic")
			return nil

		default:
			// The work of sending each batch. We will return quickly on any error
			// until later we figure out whethere we can be resilient to some errors.
			slog.Debug("starting batch", "batch_number", i+1, "max_batches", a.Config.MaxBatches)

			// Get a batch of pages from the database
			slog.Debug("getting new batch from database")
			pages, err := a.SourcesStore.GetBatch(ctx, a.Config.BatchSize)
			if err != nil {
				slog.Error("error getting batch from database", "error", err)
				return err
			}
			batch := predictor.NewBatch(pages, "testing")
			slog.Debug("got new batch from database", batch.LogID()...)

			// Record the batch in the database so it will be tracked
			slog.Debug("recording batch to database", batch.LogID()...)
			err = a.PredictorStore.RecordBatch(ctx, batch)
			if err != nil {
				slog.Error("error recording batch in database", append(batch.LogID(), "error", err)...)
				return err
			}
			slog.Debug("recorded batch in database", batch.LogID()...)

			slog.Debug("sending batch to Anthropic", batch.LogID()...)
			err = batch.SendBatchToAnthropic(ctx, *a.AnthropicClient)
			if err != nil {
				slog.Error("error sending batch to Anthropic", append(batch.LogID(), "error", err)...)
				return err
			}
			slog.Debug("sent batch to Anthropic", batch.LogID()...)

			slog.Debug("updating batch in database", batch.LogID()...)
			err = a.PredictorStore.SentBatch(ctx, batch)
			if err != nil {
				slog.Error("error recording sent batch", append(batch.LogID(), "error", err)...)
				return err
			}
			slog.Debug("updated batch in database", batch.LogID()...)

			// Single log value when things are working
			slog.Info("successfully sent batch to Anthropic", batch.LogID()...)
		}

	}

	slog.Info("finished sending batches to Anthropic")
	return nil
}
