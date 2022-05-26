-- Create the key CAP metadata tables
BEGIN;
CREATE TABLE cap.cases (
  id bigint PRIMARY KEY,
  name text NOT NULL,
  name_abbreviation text NOT NULL,
  decision_date_raw text NOT NULL,
  decision_date date,
  docket_number text NOT NULL,
  first_page_raw text NOT NULL,
  last_page_raw text NOT NULL,
  first_page int,
  last_page int,
  volume jsonb NOT NULL,
  reporter bigint NOT NULL,
  court bigint NOT NULL,
  jurisdiction bigint NOT NULL,
  url text NOT NULL,
  frontend_url text NOT NULL,
  frontend_pdf_url text NOT NULL,
  analysis jsonb NOT NULL,
  last_updated timestamp with time zone NOT NULL,
  provenance jsonb NOT NULL,
  imported timestamp with time zone NOT NULL
);
CREATE TABLE cap.citations (
  cite text PRIMARY KEY,
  type text NOT NULL,
  "case" bigint NOT NULL
);
CREATE TABLE cap.courts (
  id bigint PRIMARY KEY,
  name text NOT NULL,
  name_abbreviation text NOT NULL,
  slug text NOT NULL,
  url text NOT NULL
);
CREATE TABLE cap.jurisdictions (
  id bigint PRIMARY KEY,
  name text NOT NULL,
  name_long text NOT NULL,
  slug text NOT NULL,
  whitelisted bool NOT NULL,
  url text NOT NULL
);
ALTER TABLE cap.cases
  ADD CONSTRAINT cap_cases_reporter_fk FOREIGN KEY (reporter) REFERENCES cap.reporters (id);
ALTER TABLE cap.cases
  ADD CONSTRAINT cap_cases_court_fk FOREIGN KEY (court) REFERENCES cap.courts (id);
ALTER TABLE cap.cases
  ADD CONSTRAINT cap_cases_jurisdiction_fk FOREIGN KEY (jurisdiction) REFERENCES cap.jurisdictions (id);
ALTER TABLE cap.citations
  ADD CONSTRAINT cap_citations_case_fk FOREIGN KEY ("case") REFERENCES cap.cases (id);
COMMIT;

