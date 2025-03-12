-- migrate:up
CREATE INDEX "batches_last_checked_idx" ON "predictor"."batches"("last_checked");
CREATE INDEX "batches_status_idx" ON "predictor"."batches"("status");

-- migrate:down
DROP INDEX IF EXISTS predictor.batches_last_checked_idx;
DROP INDEX IF EXISTS predictor.batches_status_idx;
