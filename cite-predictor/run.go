package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"log/slog"
	"time"

	"github.com/lmullen/legal-modernism/go/predictor"
)

// SendBatches identifies work to be done from the database and sends batches to
// Anthropic one at at time.
func (a *App) SendBatches(ctx context.Context) error {

	var batchesSent int64

	slog.Info("started sending batches to Anthropic",
		"batches_sent", batchesSent, "max_batches", a.Config.MaxBatches)

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

			// If there are zero items in the batch, then there must not be any work
			// left in the database, and so we can exit this function
			if len(batch.Requests) == 0 {
				slog.Info("batch has zero items: no work left to do", batch.LogID()...)
				return nil
			}

			// Record the batch in the database so it will be tracked
			slog.Debug("recording batch to database", batch.LogID()...)
			err = a.PredictorStore.RecordBatch(ctx, batch)
			if err != nil {
				slog.Error("error recording batch in database", batch.LogID("error", err)...)
				return err
			}
			slog.Debug("recorded batch in database", batch.LogID()...)

			slog.Debug("sending batch to Anthropic", batch.LogID()...)
			err = batch.SendBatchToAnthropic(ctx, *a.AnthropicClient)
			if err != nil {
				slog.Error("error sending batch to Anthropic", batch.LogID("error", err)...)
				return err
			}
			slog.Debug("sent batch to Anthropic", batch.LogID()...)

			slog.Debug("updating batch in database", batch.LogID()...)
			err = a.PredictorStore.SentBatch(ctx, batch)
			if err != nil {
				slog.Error("error recording sent batch", batch.LogID("error", err)...)
				return err
			}
			slog.Debug("updated batch in database", batch.LogID()...)

			// Single log value when things are working
			slog.Info("successfully sent batch to Anthropic", batch.LogID()...)
			batchesSent++
		}

	}

	slog.Info("finished sending batches to Anthropic",
		"batches_sent", batchesSent, "max_batches", a.Config.MaxBatches)

	return nil
}

// GetBatches checks for batches that have been sent to Anthropic and retrives
// them.
func (a *App) GetBatches(ctx context.Context) error {

	slog.Info("started retrieving batches from Anthropic")

	// Keep checking for batches until told to stop via context cancellation
	for {
		select {
		case <-ctx.Done():
			slog.Info("canceled retrieving batches from Anthropic")
			return nil

		default:

			slog.Debug("getting a batch to retrieve from the database")
			b, err := a.PredictorStore.BatchToCheck(ctx, a.Config.PollDelay)
			// If there are no batches in the database, wait at least as long as the poll
			// delay before, then check again.
			if err == sql.ErrNoRows {
				time.Sleep(a.Config.PollDelay)
				continue
			}
			// This is an actual error, so quit this subprocess
			if err != nil {
				slog.Error("error getting batch to check from database", "error", err)
				return err
			}
			slog.Debug("got a batch to retrieve from the database", b.LogID()...)

			slog.Debug("checking batch status at Anthropic", b.LogID()...)
			out, err := a.AnthropicClient.Messages.Batches.Get(ctx, *b.Anthropic())
			if err != nil {
				slog.Error("error getting batch status from Anthropic", b.LogID("error", err)...)
				return err
			}
			slog.Debug("got batch status at Anthropic", b.LogID()...)

			// Update the details about the batch, which need to be recorded to the
			// database no matter what
			b.LastChecked = time.Now()
			b.Status = string(out.ProcessingStatus)
			bytes, err := json.Marshal(out)
			if err != nil {
				slog.Error("error unmarshalling batch result JSON", b.LogID("error", err)...)
				return err
			}
			b.Result = bytes

			// TODO: Actually get the batch results

			slog.Debug("updating batch status in database", b.LogID()...)
			err = a.PredictorStore.UpdateCheckedBatch(ctx, b)
			if err != nil {
				slog.Error("error updating batch in database", b.LogID("error", err)...)
				return err
			}

			return nil

		}

	}

}
