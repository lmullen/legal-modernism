-- migrate:up
SET ROLE = law_admin;

CREATE TABLE IF NOT EXISTS predictor.batches (
  "id" uuid,
  "anthropic_id" text UNIQUE,
  "created_at" timestamp with time zone NOT NULL,
  "last_checked" timestamp with time zone NOT NULL,
  "status" text NOT NULL,
  "result" jsonb,
  PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS predictor.requests (
  "id" uuid,
  "batch_id" uuid NOT NULL,
  "psmid" text NOT NULL,
  "pageid" text NOT NULL,
	"purpose" text NOT NULL,
	"status" text NOT NULL,
  "result" jsonb,
  PRIMARY KEY ("id"),
  CONSTRAINT fk_moml_ocrtext FOREIGN KEY (psmid, pageid) REFERENCES moml.page_ocrtext (psmid, pageid),
  CONSTRAINT fk_predictor_batches FOREIGN KEY (batch_id) REFERENCES predictor.batches (id)
);

CREATE INDEX "requests_batch_id_idx" ON predictor.requests("batch_id");

-- migrate:down
SET ROLE = law_admin;
DROP TABLE IF EXISTS predictor.requests;
DROP TABLE IF EXISTS predictor.batches;
