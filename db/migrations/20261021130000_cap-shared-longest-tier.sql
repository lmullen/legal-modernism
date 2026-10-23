-- migrate:up
SET ROLE = law_admin;

-- Admit 'cap_shared_longest' in both chk_citation_links_match_tier
-- constraints (issue #359).
--
-- LoadCAPCitations drops every cite that belongs to more than one CAP case,
-- and the linker used to report a citation to one as us_page_absent although
-- the cite is in cap.citations: 108,357 CAP-ledger citations, 9% of its
-- no_match pool, measured 2026-10-20, and 304,943 MOML citations (2026-10-23).
-- The cases that begin on one page are nearly always a decision of some
-- length and one or more memorandum decisions of a page or less, printed in
-- the space the longer one leaves (89 Ga. 645 is Reese v. Reese, nine pages,
-- beside Summers v. State, one). A citation to the page means the decision
-- that fills it, so the linker now loads the shared cites with each case's
-- page count and links to the longest of the cases the year gate (#319)
-- admits, with this tier. When the longest is not unique, as in a table of
-- one-page decisions, it is no_match us_page_ambiguous, which both
-- constraints already admit.
--
-- Widening the constraints needs no backfill: no current row carries the
-- value. Rows get it when citation_links is truncated and relinked.
ALTER TABLE moml_citations.citation_links
  DROP CONSTRAINT IF EXISTS chk_citation_links_match_tier;
ALTER TABLE moml_citations.citation_links
  ADD CONSTRAINT chk_citation_links_match_tier CHECK (
    match_tier IS NULL OR match_tier IN (
      -- no_match, US route (CAP -> FreeLaw -> alternate spellings -> code reporter)
      'us_reporter_absent',       -- no probed reporter spelling appears in any US source
      'us_diffvols_missing',      -- renumbers in CAP, but no reporters_diffvols row for this volume
      'us_volume_absent',         -- reporter present, this volume never appears
      'us_volume_missing',        -- #261: reporter present, but the citation carries no volume
      'us_page_absent',           -- reporter and volume present, page is not a first-page cite
      'us_page_ambiguous',        -- #242, #359: the page or cite belongs to two or more cases
      'us_page_gap',              -- #242: page falls inside no case span in a covered volume
      'us_anachronistic',         -- #319: every case found was decided after the citing document
      -- no_match, UK route (English Reports)
      'uk_reporter_absent',
      'uk_volume_absent',
      'uk_volume_missing',        -- #261
      'uk_page_absent',
      'uk_page_ambiguous',        -- #256
      'uk_page_gap',              -- #243
      'uk_anachronistic',         -- #319
      -- linked_*: which probe produced the link
      'cap_direct',               -- cap.citations, under the normalized cite
      'cap_shared_longest',       -- #359: a shared cap.citations cite, linked to the longest case
      'cap_freelaw',              -- freelaw.cite_to_cap, under the normalized cite
      'cap_alt_spelling',         -- cap.citations, under a reporters_abbreviations alternate
      'cap_freelaw_alt_spelling', -- freelaw.cite_to_cap, under an alternate
      'cap_page_interior',        -- #242: unique containment in a case's page span
      'code_direct',              -- legalhist.code_reporter, under the cleaned cite
      'er_direct',
      'er_page_interior',         -- #243
      'stub_direct'               -- #248: legalhist.stub_cases, under the cleaned cite
    )
  );

ALTER TABLE opinion_citations.citation_links
  DROP CONSTRAINT IF EXISTS chk_citation_links_match_tier;
ALTER TABLE opinion_citations.citation_links
  ADD CONSTRAINT chk_citation_links_match_tier CHECK (
    match_tier IS NULL OR match_tier IN (
      'us_reporter_absent',
      'us_diffvols_missing',
      'us_volume_absent',
      'us_volume_missing',
      'us_page_absent',
      'us_page_ambiguous',
      'us_page_gap',
      'us_anachronistic',
      'uk_reporter_absent',
      'uk_volume_absent',
      'uk_volume_missing',
      'uk_page_absent',
      'uk_page_ambiguous',
      'uk_page_gap',
      'uk_anachronistic',
      'cap_direct',
      'cap_shared_longest',
      'cap_freelaw',
      'cap_alt_spelling',
      'cap_freelaw_alt_spelling',
      'cap_page_interior',
      'code_direct',
      'er_direct',
      'er_page_interior',
      'stub_direct'
    )
  );

-- migrate:down
SET ROLE = law_admin;

-- A row with this tier is a link the previous linker would not have made, so
-- it cannot be relabelled. Refuse to narrow the constraints while any exist:
-- truncate citation_links and relink with the previous linker instead.
DO $$
DECLARE n bigint;
BEGIN
  SELECT (SELECT count(*) FROM moml_citations.citation_links WHERE match_tier = 'cap_shared_longest')
       + (SELECT count(*) FROM opinion_citations.citation_links WHERE match_tier = 'cap_shared_longest')
    INTO n;
  IF n > 0 THEN
    RAISE EXCEPTION 'cannot narrow chk_citation_links_match_tier: % rows carry cap_shared_longest; truncate citation_links and relink first', n;
  END IF;
END $$;

ALTER TABLE moml_citations.citation_links
  DROP CONSTRAINT IF EXISTS chk_citation_links_match_tier;
ALTER TABLE moml_citations.citation_links
  ADD CONSTRAINT chk_citation_links_match_tier CHECK (
    match_tier IS NULL OR match_tier IN (
      'us_reporter_absent',
      'us_diffvols_missing',
      'us_volume_absent',
      'us_volume_missing',
      'us_page_absent',
      'us_page_ambiguous',
      'us_page_gap',
      'us_anachronistic',
      'uk_reporter_absent',
      'uk_volume_absent',
      'uk_volume_missing',
      'uk_page_absent',
      'uk_page_ambiguous',
      'uk_page_gap',
      'uk_anachronistic',
      'cap_direct',
      'cap_freelaw',
      'cap_alt_spelling',
      'cap_freelaw_alt_spelling',
      'cap_page_interior',
      'code_direct',
      'er_direct',
      'er_page_interior',
      'stub_direct'
    )
  );

ALTER TABLE opinion_citations.citation_links
  DROP CONSTRAINT IF EXISTS chk_citation_links_match_tier;
ALTER TABLE opinion_citations.citation_links
  ADD CONSTRAINT chk_citation_links_match_tier CHECK (
    match_tier IS NULL OR match_tier IN (
      'us_reporter_absent',
      'us_diffvols_missing',
      'us_volume_absent',
      'us_volume_missing',
      'us_page_absent',
      'us_page_ambiguous',
      'us_page_gap',
      'us_anachronistic',
      'uk_reporter_absent',
      'uk_volume_absent',
      'uk_volume_missing',
      'uk_page_absent',
      'uk_page_ambiguous',
      'uk_page_gap',
      'uk_anachronistic',
      'cap_direct',
      'cap_freelaw',
      'cap_alt_spelling',
      'cap_freelaw_alt_spelling',
      'cap_page_interior',
      'code_direct',
      'er_direct',
      'er_page_interior',
      'stub_direct'
    )
  );
