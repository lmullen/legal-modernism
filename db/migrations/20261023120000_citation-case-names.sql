-- migrate:up
SET ROLE = law_admin;

-- Record the case name printed before a citation (issue #387).
--
-- The detector reads the name the way eyecite does: from the citation it
-- walks backward through the words before it until a rule says the name has
-- ended, with the rules the treatises need added (the OCR's spellings of
-- "v.", the annotations printed between a name and its cite, parallel cites,
-- tables of cases). See go/citations/casename.go.
--
-- case_name is the name as printed, whitespace normalized, the versus
-- normalized to "v." ("Coryell v. Cain"), or "In re X" / "Ex parte X", or a
-- bare name; NULL when nothing was found, which is about a quarter of the
-- citations (statutes, institutional writers, cites by footnote number). One
-- column rather than plaintiff and defendant, because that is the form every
-- case table we link to holds: cap.cases.name_abbreviation,
-- english_reports.cases.er_name, legalhist.code_reporter.name_abbreviation,
-- legalhist.stub_case_metadata.party_names.
--
-- case_name_source says how the name was found, so the linker can weight it
-- as evidence the way match_tier records why a link was made:
--   direct    the scan found the name printed before this citation
--   parallel  this citation follows another with only punctuation between,
--             "Smith v. Jones, 2 Cromp. M. & R. 240; 3 Dowl. 751", and
--             inherited its name
--   table     a table of cases elides a repeated plaintiff, "Summers v.
--             Farish, 10 Cal. 847 170, v. Hoover, 42 Ind. 153", and the
--             plaintiff was taken from the row above
--
-- Neither column joins the unique index: the name is not part of what
-- identifies a citation, and two detectors finding the same span read the
-- same name. The columns are filled by the next full detection run; nothing
-- backfills existing rows.
ALTER TABLE moml_citations.citations_unlinked
  ADD COLUMN IF NOT EXISTS case_name text,
  ADD COLUMN IF NOT EXISTS case_name_source text;

ALTER TABLE moml_citations.citations_unlinked
  DROP CONSTRAINT IF EXISTS chk_citations_unlinked_case_name_source,
  DROP CONSTRAINT IF EXISTS chk_citations_unlinked_case_name_pair;
ALTER TABLE moml_citations.citations_unlinked
  ADD CONSTRAINT chk_citations_unlinked_case_name_source
    CHECK (case_name_source IS NULL OR case_name_source IN ('direct', 'parallel', 'table')),
  ADD CONSTRAINT chk_citations_unlinked_case_name_pair
    CHECK ((case_name IS NULL) = (case_name_source IS NULL));

COMMENT ON COLUMN moml_citations.citations_unlinked.case_name IS
  'The case name printed before the citation, as the detector read it: "Plaintiff v. Defendant", "In re X", or a bare name; NULL when none was found (issue #387).';
COMMENT ON COLUMN moml_citations.citations_unlinked.case_name_source IS
  'How case_name was found: direct (printed before this citation), parallel (inherited from the preceding parallel cite), table (plaintiff taken from the row above in a table of cases).';

-- The CAP ledger is the twin of the MOML one (issue #74) and is written by
-- the same code.
ALTER TABLE opinion_citations.citations_unlinked
  ADD COLUMN IF NOT EXISTS case_name text,
  ADD COLUMN IF NOT EXISTS case_name_source text;

ALTER TABLE opinion_citations.citations_unlinked
  DROP CONSTRAINT IF EXISTS chk_citations_unlinked_case_name_source,
  DROP CONSTRAINT IF EXISTS chk_citations_unlinked_case_name_pair;
ALTER TABLE opinion_citations.citations_unlinked
  ADD CONSTRAINT chk_citations_unlinked_case_name_source
    CHECK (case_name_source IS NULL OR case_name_source IN ('direct', 'parallel', 'table')),
  ADD CONSTRAINT chk_citations_unlinked_case_name_pair
    CHECK ((case_name IS NULL) = (case_name_source IS NULL));

COMMENT ON COLUMN opinion_citations.citations_unlinked.case_name IS
  'The case name printed before the citation, as the detector read it: "Plaintiff v. Defendant", "In re X", or a bare name; NULL when none was found (issue #387).';
COMMENT ON COLUMN opinion_citations.citations_unlinked.case_name_source IS
  'How case_name was found: direct (printed before this citation), parallel (inherited from the preceding parallel cite), table (plaintiff taken from the row above in a table of cases).';

-- migrate:down
SET ROLE = law_admin;

ALTER TABLE opinion_citations.citations_unlinked
  DROP CONSTRAINT IF EXISTS chk_citations_unlinked_case_name_pair,
  DROP CONSTRAINT IF EXISTS chk_citations_unlinked_case_name_source,
  DROP COLUMN IF EXISTS case_name_source,
  DROP COLUMN IF EXISTS case_name;

ALTER TABLE moml_citations.citations_unlinked
  DROP CONSTRAINT IF EXISTS chk_citations_unlinked_case_name_pair,
  DROP CONSTRAINT IF EXISTS chk_citations_unlinked_case_name_source,
  DROP COLUMN IF EXISTS case_name_source,
  DROP COLUMN IF EXISTS case_name;
