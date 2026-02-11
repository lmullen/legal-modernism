-- migrate:up
SET ROLE = law_admin;

CREATE TABLE IF NOT EXISTS legalhist.code_reporter (
    "id" bigint GENERATED ALWAYS AS IDENTITY,
    "name" text NOT NULL,
    "name_abbreviation" text NOT NULL,
    "decision_year" int NOT NULL,
    "first_page" int NOT NULL,
    "last_page" int NOT NULL,
    "volume_number" int NOT NULL,
    "official_citation" text NOT NULL,
    "parallel_citation" text,
    "reporter" text,
    "court_name" text,
    "court_cap_id" bigint,
    "jurisdiction" text,
    "jurisdiction_slug" text,
    "author" text,
    "text" text,
    PRIMARY KEY ("id")
);

ALTER TABLE ONLY legalhist.code_reporter
    ADD CONSTRAINT code_reporter_court_cap_id_fk
    FOREIGN KEY (court_cap_id) REFERENCES cap.courts(id);

CREATE INDEX "code_reporter_decision_year_idx" ON "legalhist"."code_reporter"("decision_year");
CREATE INDEX "code_reporter_court_cap_id_idx" ON "legalhist"."code_reporter"("court_cap_id");
CREATE INDEX "code_reporter_official_citation_idx" ON "legalhist"."code_reporter"("official_citation");
CREATE INDEX "code_reporter_volume_number_idx" ON "legalhist"."code_reporter"("volume_number");

-- migrate:down
SET ROLE = law_admin;
DROP TABLE IF EXISTS legalhist.code_reporter;
