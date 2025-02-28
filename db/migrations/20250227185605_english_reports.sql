-- migrate:up
SET ROLE = law_admin;

CREATE SCHEMA IF NOT EXISTS english_reports;

CREATE TABLE IF NOT EXISTS english_reports.cases (
    "id" text,
    "er_name" text,
    "er_year" int NOT NULL,
    "er_date" date NOT NULL,
    "er_cite" text NOT NULL,
    "er_cite_disambiguated" text NOT NULL,
    "er_parallel_cite" text,
    "murrell_uid" text,
    "murrell_year" int,
    "murrell_title" text,
    "er_filename" text NOT NULL,
    "er_url" text,
    "court" text,
    "word_count" int,
    PRIMARY KEY ("id")
);

CREATE INDEX "er_cases_er_year_idx" ON "english_reports"."cases"("er_year");
CREATE INDEX "er_cases_er_cite_idx" ON "english_reports"."cases"("er_cite");
CREATE INDEX "er_cases_er_parallel_cite_idx" ON "english_reports"."cases"("er_parallel_cite");

-- migrate:down
SET ROLE = law_admin;
DROP TABLE IF EXISTS english_reports.cases;
DROP SCHEMA IF EXISTS english_reports;
