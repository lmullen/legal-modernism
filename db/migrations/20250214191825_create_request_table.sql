-- migrate:up
SET ROLE = law_admin;
CREATE TABLE IF NOT EXISTS predictor.requests (
  "id" uuid,
  "created_at" timestamp with time zone NOT NULL,
  "psmid" text,
  "pageid" text,
	"purpose" text,
	"parent" uuid REFERENCES predictor.requests(id),
	"status" text,
  "last_checked" timestamp with time zone,
  PRIMARY KEY ("id"),
  CONSTRAINT fk_moml_ocrtext FOREIGN KEY (psmid, pageid) REFERENCES moml.page_ocrtext (psmid, pageid)
);

-- migrate:down
SET ROLE = law_admin;
DROP TABLE IF EXISTS predictor.requests;
