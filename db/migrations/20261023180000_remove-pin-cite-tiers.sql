-- migrate:up
SET ROLE = law_admin;

-- Remove pin-cite (page-range) linking from the database (issue #393).
--
-- Since issues #242 and #243 the linker resolved a citation to an interior
-- page of a case through a page-range index: the page was assigned to the
-- case whose span covers it, recorded as cap_page_interior or
-- er_page_interior, with us_page_gap and uk_page_gap for a page in a hole in
-- the corpus. The evaluation on #393 (2026-10-23) found those links mostly
-- wrong: the case name the detector read agrees with the linked case for 28%
-- of the treatises' cap_page_interior links and 33% of their er_page_interior
-- links, against 87% and 77% for the exact first-page tiers; in the opinions
-- ledger 76% and 50% against 96% and 89%. Of the edges they draw, 88% are
-- edges nothing else supports, and the name agrees on about a fifth of those.
-- The linker no longer builds the index, so the four tiers can no longer be
-- written, and a pin cite is a no_match at us_page_absent or uk_page_absent,
-- which is what it was before #242.
--
-- Three steps, in this order:
--
--   1. Rewrite the rows that carry the four tiers to the misses the current
--      linker would record. Measured 2026-10-23: moml_citations.citation_links
--      holds 2,962,303 cap_page_interior, 1,914,038 er_page_interior, 563,524
--      us_page_gap and 234,705 uk_page_gap rows; opinion_citations.citation_links
--      813,193, 65,408, 56,378 and 4,405. A pin-cite link never recorded
--      cite_linked (no cite string matched), so clearing it changes nothing.
--      The rewrite is what lets the narrowed constraints apply; the next
--      `./scripts/pipeline.sh --from truncate-links` (both corpora) derives
--      the same rows from scratch.
--   2. Narrow both chk_citation_links_match_tier constraints to the tiers the
--      linker still writes. The Go constants (go/citations/linker.go) are the
--      other copy of this list; go/citations/linker_tier_constraint_test.go
--      checks every constant against the migrations.
--   3. Rebuild the materialized views that carried a pin-cite column, without
--      it: edition_case_citations.pincite_only and the columns derived from it
--      (edition_citation_counts.cases_not_pincite_only,
--      case_edition_counts.editions_not_pincite_only and its index), and on
--      the CAP side case_case_citations.pincite_only,
--      cap_graph_edges.pincite_only and the ours_only_pincite of
--      cap_graph_agreement and cap_graph_case_agreement. work_citation_counts
--      reads edition_case_citations and edition_citation_counts and has to be
--      dropped and recreated with them; its definition is unchanged. The
--      definitions are those of 20260925180000, 20260926120000, 20260926130200
--      and 20261020120100 less the column. Every view is created WITH NO DATA;
--      `make db-maintenance` (db/maintenance.sh finds them from the catalog)
--      or the pipeline's maintenance phase populates them.
--
-- The UPDATE takes a few minutes over the 56M-row MOML table.

-- 1. The rows.
UPDATE moml_citations.citation_links
SET status = 'no_match',
    match_tier = CASE
      WHEN match_tier IN ('cap_page_interior', 'us_page_gap') THEN 'us_page_absent'
      ELSE 'uk_page_absent'
    END,
    cap_case_id = NULL,
    er_case_id = NULL,
    cite_linked = NULL
WHERE match_tier IN ('cap_page_interior', 'er_page_interior', 'us_page_gap', 'uk_page_gap');

UPDATE opinion_citations.citation_links
SET status = 'no_match',
    match_tier = CASE
      WHEN match_tier IN ('cap_page_interior', 'us_page_gap') THEN 'us_page_absent'
      ELSE 'uk_page_absent'
    END,
    cap_case_id = NULL,
    er_case_id = NULL,
    cite_linked = NULL
WHERE match_tier IN ('cap_page_interior', 'er_page_interior', 'us_page_gap', 'uk_page_gap');

-- 2. The constraints.
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
      'us_page_ambiguous',        -- #359: the cite belongs to two or more cases, none longest
      'us_anachronistic',         -- #319: every case found was decided after the citing document
      -- no_match, UK route (English Reports)
      'uk_reporter_absent',
      'uk_volume_absent',
      'uk_volume_missing',        -- #261
      'uk_page_absent',
      'uk_page_ambiguous',        -- #256
      'uk_anachronistic',         -- #319
      -- linked_*: which probe produced the link
      'cap_direct',               -- cap.citations, under the normalized cite
      'cap_shared_longest',       -- #359: a shared cap.citations cite, linked to the longest case
      'cap_freelaw',              -- freelaw.cite_to_cap, under the normalized cite
      'cap_alt_spelling',         -- cap.citations, under a reporters_abbreviations alternate
      'cap_freelaw_alt_spelling', -- freelaw.cite_to_cap, under an alternate
      'code_direct',              -- legalhist.code_reporter, under the cleaned cite
      'er_direct',
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
      'us_anachronistic',
      'uk_reporter_absent',
      'uk_volume_absent',
      'uk_volume_missing',
      'uk_page_absent',
      'uk_page_ambiguous',
      'uk_anachronistic',
      'cap_direct',
      'cap_shared_longest',
      'cap_freelaw',
      'cap_alt_spelling',
      'cap_freelaw_alt_spelling',
      'code_direct',
      'er_direct',
      'stub_direct'
    )
  );

-- 3. The views, dropped in dependency order (each reads the one below it)
--    and recreated in the reverse.
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_case_agreement;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_agreement;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_edges;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.case_case_citations;
DROP MATERIALIZED VIEW IF EXISTS moml_citations.case_edition_counts;
DROP MATERIALIZED VIEW IF EXISTS moml_citations.work_citation_counts;
DROP MATERIALIZED VIEW IF EXISTS moml_citations.edition_citation_counts;
DROP MATERIALIZED VIEW IF EXISTS moml_citations.edition_case_citations;

-- moml_citations.edition_case_citations (issue #213), as in 20260925180000
-- without pincite_only.
CREATE MATERIALIZED VIEW IF NOT EXISTS moml_citations.edition_case_citations AS
SELECT
  v.bibliographicid,
  CASE
    WHEN cl.cap_case_id IS NOT NULL THEN 'cap'
    WHEN cl.er_case_id IS NOT NULL THEN 'er'
    WHEN cl.code_reporter_id IS NOT NULL THEN 'code'
    ELSE 'stub'
  END AS source,
  cl.cap_case_id,
  cl.er_case_id,
  cl.code_reporter_id,
  cl.stub_cite,
  count(*) AS cite_count
FROM moml_citations.citation_links cl
JOIN moml_citations.citations_unlinked cu ON cu.id = cl.citation_id
JOIN moml.volumes v ON v.psmid = cu.moml_treatise
WHERE cl.status LIKE 'linked%'
GROUP BY v.bibliographicid, cl.cap_case_id, cl.er_case_id, cl.code_reporter_id, cl.stub_cite
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW moml_citations.edition_case_citations IS 'One row for each MOML edition and each case it cites, from the linked citations in citation_links (issue #213). Exactly one of cap_case_id, er_case_id, code_reporter_id and stub_cite is set. Refreshed by make db-maintenance.';
COMMENT ON COLUMN moml_citations.edition_case_citations.source IS 'Which column holds the case: cap, er, code or stub.';
COMMENT ON COLUMN moml_citations.edition_case_citations.cite_count IS 'Number of linked citations from the edition to the case.';

CREATE UNIQUE INDEX IF NOT EXISTS edition_case_citations_uq
  ON moml_citations.edition_case_citations
  (bibliographicid, cap_case_id, er_case_id, code_reporter_id, stub_cite) NULLS NOT DISTINCT;
CREATE INDEX IF NOT EXISTS edition_case_citations_cap_idx
  ON moml_citations.edition_case_citations (cap_case_id) WHERE cap_case_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS edition_case_citations_er_idx
  ON moml_citations.edition_case_citations (er_case_id) WHERE er_case_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS edition_case_citations_code_idx
  ON moml_citations.edition_case_citations (code_reporter_id) WHERE code_reporter_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS edition_case_citations_stub_idx
  ON moml_citations.edition_case_citations (stub_cite) WHERE stub_cite IS NOT NULL;

-- moml_citations.edition_citation_counts (issue #305), as in 20260926120000
-- without cases_not_pincite_only.
CREATE MATERIALIZED VIEW IF NOT EXISTS moml_citations.edition_citation_counts AS
WITH vols AS (
  SELECT v.bibliographicid,
         count(*)                     AS volumes,
         sum(v.total_pages)::bigint           AS pages,
         COALESCE(sum(tcc.n), 0)::bigint      AS cites,
         COALESCE(sum(tcc.linked), 0)::bigint AS linked
  FROM moml.volumes v
  LEFT JOIN moml_citations.treatise_citation_counts tcc ON tcc.moml_treatise = v.psmid
  GROUP BY v.bibliographicid
),
cases AS (
  SELECT bibliographicid, count(*) AS cases
  FROM moml_citations.edition_case_citations
  GROUP BY bibliographicid
)
SELECT t.bibliographicid,
       e.work_id,
       t.jurisdiction,
       t.year,
       t.title,
       e.author,
       t.vols,
       vols.volumes,
       vols.pages,
       e.derivative,
       vols.cites,
       vols.linked,
       COALESCE(cases.cases, 0) AS cases
FROM moml.treatises t
JOIN moml.editions e ON e.bibliographicid = t.bibliographicid
JOIN vols ON vols.bibliographicid = t.bibliographicid
LEFT JOIN cases ON cases.bibliographicid = t.bibliographicid
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW moml_citations.edition_citation_counts IS 'One row per treatise edition (moml.treatises, materialized) with its work, jurisdiction, year, title, volumes, pages, detected and linked citations, and the distinct cases it cites (issue #305). Refreshed by make db-maintenance.';

CREATE UNIQUE INDEX IF NOT EXISTS edition_citation_counts_uq
  ON moml_citations.edition_citation_counts (bibliographicid);
CREATE INDEX IF NOT EXISTS edition_citation_counts_work_idx
  ON moml_citations.edition_citation_counts (work_id);
CREATE INDEX IF NOT EXISTS edition_citation_counts_cites_idx
  ON moml_citations.edition_citation_counts (cites DESC);

-- moml_citations.work_citation_counts (issue #305), unchanged from
-- 20260926120000; recreated because it reads the two views above.
CREATE MATERIALIZED VIEW IF NOT EXISTS moml_citations.work_citation_counts AS
WITH cases AS (
  SELECT ecc.work_id,
         count(DISTINCT c.source || ':' || COALESCE(c.cap_case_id::text, c.er_case_id,
                                                    c.code_reporter_id::text, c.stub_cite)) AS cases
  FROM moml_citations.edition_case_citations c
  JOIN moml_citations.edition_citation_counts ecc ON ecc.bibliographicid = c.bibliographicid
  GROUP BY ecc.work_id
),
all_editions AS (
  SELECT work_id, count(*) AS n FROM moml.editions GROUP BY work_id
)
SELECT ecc.work_id,
       count(*)                                    AS editions,
       ae.n                                        AS all_editions,
       count(*) FILTER (WHERE ecc.derivative)      AS derivative_editions,
       min(ecc.year)                               AS first_year,
       max(ecc.year)                               AS last_year,
       bool_or(ecc.jurisdiction = 'US')            AS us,
       bool_or(ecc.jurisdiction = 'UK')            AS uk,
       sum(ecc.cites)::bigint                      AS cites,
       sum(ecc.linked)::bigint                     AS linked,
       COALESCE(max(cases.cases), 0)               AS cases
FROM moml_citations.edition_citation_counts ecc
JOIN all_editions ae ON ae.work_id = ecc.work_id
LEFT JOIN cases ON cases.work_id = ecc.work_id
GROUP BY ecc.work_id, ae.n
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW moml_citations.work_citation_counts IS 'One row per work with at least one treatise edition: its treatise editions, all its editions, the span of years, jurisdictions, citation totals and distinct cases cited (issue #305). Refreshed by make db-maintenance.';

CREATE UNIQUE INDEX IF NOT EXISTS work_citation_counts_uq
  ON moml_citations.work_citation_counts (work_id);
CREATE INDEX IF NOT EXISTS work_citation_counts_cites_idx
  ON moml_citations.work_citation_counts (cites DESC);

-- moml_citations.case_edition_counts (issue #305), as in 20260926120000
-- without editions_not_pincite_only and its index.
CREATE MATERIALIZED VIEW IF NOT EXISTS moml_citations.case_edition_counts AS
WITH agg AS (
  SELECT c.source, c.cap_case_id, c.er_case_id, c.code_reporter_id, c.stub_cite,
         count(*)                                   AS editions,
         count(DISTINCT ecc.work_id)                AS works,
         sum(c.cite_count)::bigint                  AS cites,
         count(*) FILTER (WHERE ecc.jurisdiction = 'US') AS us_editions,
         min(ecc.year)                              AS first_cited,
         max(ecc.year)                              AS last_cited
  FROM moml_citations.edition_case_citations c
  JOIN moml_citations.edition_citation_counts ecc ON ecc.bibliographicid = c.bibliographicid
  GROUP BY c.source, c.cap_case_id, c.er_case_id, c.code_reporter_id, c.stub_cite
)
SELECT a.source,
       a.source || ':' || COALESCE(a.cap_case_id::text, a.er_case_id,
                                   a.code_reporter_id::text, a.stub_cite) AS case_key,
       a.cap_case_id, a.er_case_id, a.code_reporter_id, a.stub_cite,
       COALESCE(cc.name_abbreviation, er.murrell_title, er.er_name, code.name, sm.party_names) AS name,
       COALESCE(cc.decision_year, er.murrell_year, er.er_year, code.decision_year, sm.year_decided) AS year,
       COALESCE(capcite.cite, er.er_cite, code.official_citation, a.stub_cite) AS cite,
       a.editions, a.works, a.cites,
       a.us_editions, a.first_cited, a.last_cited
FROM agg a
LEFT JOIN cap.cases cc ON cc.id = a.cap_case_id
LEFT JOIN LATERAL (
  SELECT ci.cite FROM cap.citations ci WHERE ci."case" = a.cap_case_id
  ORDER BY (ci.type = 'official') DESC, ci.cite LIMIT 1
) capcite ON true
LEFT JOIN english_reports.cases er ON er.id = a.er_case_id
LEFT JOIN legalhist.code_reporter code ON code.id = a.code_reporter_id
LEFT JOIN legalhist.stub_case_metadata sm ON sm.cite = a.stub_cite
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW moml_citations.case_edition_counts IS 'One row per case cited by treatise editions, with the case''s name, year and citation copied from its source, and the treatise editions, works and citations behind it (issue #305). case_key is source:id. Refreshed by make db-maintenance.';
COMMENT ON COLUMN moml_citations.case_edition_counts.works IS 'Distinct works the citing editions belong to.';

CREATE UNIQUE INDEX IF NOT EXISTS case_edition_counts_key_uq
  ON moml_citations.case_edition_counts (case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_editions_idx
  ON moml_citations.case_edition_counts (editions DESC, case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_source_editions_idx
  ON moml_citations.case_edition_counts (source, editions DESC, case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_works_idx
  ON moml_citations.case_edition_counts (works DESC, case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_cites_idx
  ON moml_citations.case_edition_counts (cites DESC, case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_cite_idx
  ON moml_citations.case_edition_counts (cite);
CREATE INDEX IF NOT EXISTS case_edition_counts_name_trgm_idx
  ON moml_citations.case_edition_counts USING gin (name gin_trgm_ops);

-- opinion_citations.case_case_citations (issue #74), as in 20260926130200
-- without pincite_only.
CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.case_case_citations AS
SELECT
  cu.cap_case AS citing_case_id,
  CASE
    WHEN cl.cap_case_id IS NOT NULL THEN 'cap'
    WHEN cl.er_case_id IS NOT NULL THEN 'er'
    WHEN cl.code_reporter_id IS NOT NULL THEN 'code'
    ELSE 'stub'
  END AS source,
  cl.cap_case_id,
  cl.er_case_id,
  cl.code_reporter_id,
  cl.stub_cite,
  count(*) AS cite_count,
  count(DISTINCT cu.cap_opinion) AS opinion_count,
  coalesce(cl.cap_case_id = cu.cap_case, false) AS self_cite
FROM opinion_citations.citation_links cl
JOIN opinion_citations.citations_unlinked cu ON cu.id = cl.citation_id
WHERE cl.status LIKE 'linked%'
GROUP BY cu.cap_case, cl.cap_case_id, cl.er_case_id, cl.code_reporter_id, cl.stub_cite
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW opinion_citations.case_case_citations IS 'One row for each CAP case and each case its opinions cite, from the linked citations in opinion_citations.citation_links (issue #74); the twin of moml_citations.edition_case_citations. Exactly one of cap_case_id, er_case_id, code_reporter_id and stub_cite is set. Refreshed by make db-maintenance.';
COMMENT ON COLUMN opinion_citations.case_case_citations.citing_case_id IS 'The citing case, cap.cases.id.';
COMMENT ON COLUMN opinion_citations.case_case_citations.source IS 'Which column holds the cited case: cap, er, code or stub.';
COMMENT ON COLUMN opinion_citations.case_case_citations.cite_count IS 'Number of linked citations from the citing case''s opinions to the case.';
COMMENT ON COLUMN opinion_citations.case_case_citations.opinion_count IS 'Number of the citing case''s opinions that cite the case.';
COMMENT ON COLUMN opinion_citations.case_case_citations.self_cite IS 'True when the cited CAP case is the citing case: an opinion citing its own case. Kept by the linker, left out of the comparison with CAP''s graph.';

CREATE UNIQUE INDEX IF NOT EXISTS case_case_citations_uq
  ON opinion_citations.case_case_citations
  (citing_case_id, cap_case_id, er_case_id, code_reporter_id, stub_cite) NULLS NOT DISTINCT;
CREATE INDEX IF NOT EXISTS case_case_citations_cap_idx
  ON opinion_citations.case_case_citations (cap_case_id) WHERE cap_case_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS case_case_citations_er_idx
  ON opinion_citations.case_case_citations (er_case_id) WHERE er_case_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS case_case_citations_code_idx
  ON opinion_citations.case_case_citations (code_reporter_id) WHERE code_reporter_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS case_case_citations_stub_idx
  ON opinion_citations.case_case_citations (stub_cite) WHERE stub_cite IS NOT NULL;

-- opinion_citations.cap_graph_edges, cap_graph_agreement and
-- cap_graph_case_agreement (issue #349), as in 20261020120100 without
-- pincite_only and ours_only_pincite. cap_graph_scope is untouched.
CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.cap_graph_edges AS
WITH ours AS (
  SELECT ccc.citing_case_id AS citing,
         ccc.cap_case_id AS cited,
         ccc.cite_count
  FROM opinion_citations.case_case_citations ccc
  JOIN opinion_citations.cap_graph_scope s ON s.id = ccc.citing_case_id
  WHERE ccc.source = 'cap' AND NOT ccc.self_cite
),
theirs AS (
  SELECT DISTINCT cc.cites_from::bigint AS citing, cc.cites_to::bigint AS cited
  FROM cap_citations.citations cc
  JOIN opinion_citations.cap_graph_scope s ON s.id = cc.cites_from
  WHERE cc.cites_from <> cc.cites_to
)
SELECT coalesce(o.citing, t.citing) AS citing_case_id,
       coalesce(o.cited, t.cited) AS cited_case_id,
       o.citing IS NOT NULL AS in_ours,
       t.citing IS NOT NULL AS in_theirs,
       o.cite_count,
       s.decision_year AS citing_year,
       s.jurisdiction AS citing_jurisdiction,
       k.decision_year AS cited_year,
       k.jurisdiction AS cited_jurisdiction,
       k.reporter AS cited_reporter
FROM ours o
FULL OUTER JOIN theirs t ON t.citing = o.citing AND t.cited = o.cited
JOIN opinion_citations.cap_graph_scope s ON s.id = coalesce(o.citing, t.citing)
JOIN cap.cases k ON k.id = coalesce(o.cited, t.cited)
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS cap_graph_edges_uq
  ON opinion_citations.cap_graph_edges (citing_case_id, cited_case_id);
CREATE INDEX IF NOT EXISTS cap_graph_edges_disagree_idx
  ON opinion_citations.cap_graph_edges (cited_reporter, in_ours, cited_case_id, citing_case_id)
  WHERE in_ours <> in_theirs;

COMMENT ON MATERIALIZED VIEW opinion_citations.cap_graph_edges IS 'One row per edge from a citing case in cap_graph_scope to a CAP case, in our links (case_case_citations, self-cites left out), in CAP''s graph (cap_citations.citations), or both (issue #349). cite_count is NULL on an edge we lack. Refreshed by make db-maintenance.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.in_ours IS 'True when our links have the edge.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.in_theirs IS 'True when CAP''s graph has the edge.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.cited_reporter IS 'The cited case''s reporter, cap.reporters.id.';

CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.cap_graph_agreement AS
SELECT citing_year,
       citing_jurisdiction,
       cited_jurisdiction,
       cited_reporter,
       count(*) FILTER (WHERE in_ours AND in_theirs) AS in_both,
       count(*) FILTER (WHERE in_ours AND NOT in_theirs) AS ours_only,
       count(*) FILTER (WHERE in_theirs AND NOT in_ours) AS theirs_only
FROM opinion_citations.cap_graph_edges
GROUP BY citing_year, citing_jurisdiction, cited_jurisdiction, cited_reporter
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS cap_graph_agreement_uq
  ON opinion_citations.cap_graph_agreement (citing_year, citing_jurisdiction, cited_jurisdiction, cited_reporter);
CREATE INDEX IF NOT EXISTS cap_graph_agreement_reporter_idx
  ON opinion_citations.cap_graph_agreement (cited_reporter);

COMMENT ON MATERIALIZED VIEW opinion_citations.cap_graph_agreement IS 'Edges in both graphs, ours only and theirs only, by the citing case''s year and jurisdiction and the cited case''s jurisdiction and reporter (issue #349). Refreshed by make db-maintenance.';

CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.cap_graph_case_agreement AS
SELECT s.id AS citing_case_id,
       s.decision_year AS citing_year,
       s.jurisdiction AS citing_jurisdiction,
       count(e.citing_case_id) FILTER (WHERE e.in_ours AND e.in_theirs) AS in_both,
       count(e.citing_case_id) FILTER (WHERE e.in_ours AND NOT e.in_theirs) AS ours_only,
       count(e.citing_case_id) FILTER (WHERE e.in_theirs AND NOT e.in_ours) AS theirs_only
FROM opinion_citations.cap_graph_scope s
LEFT JOIN opinion_citations.cap_graph_edges e ON e.citing_case_id = s.id
GROUP BY s.id, s.decision_year, s.jurisdiction
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS cap_graph_case_agreement_pkey
  ON opinion_citations.cap_graph_case_agreement (citing_case_id);
CREATE INDEX IF NOT EXISTS cap_graph_case_agreement_ours_idx
  ON opinion_citations.cap_graph_case_agreement (ours_only DESC);
CREATE INDEX IF NOT EXISTS cap_graph_case_agreement_theirs_idx
  ON opinion_citations.cap_graph_case_agreement (theirs_only DESC);

COMMENT ON MATERIALIZED VIEW opinion_citations.cap_graph_case_agreement IS 'Edges in both graphs, ours only and theirs only, for each citing case in cap_graph_scope, zeros included (issue #349). Refreshed by make db-maintenance.';

-- After this migration the eight views are empty. Populate them with `make
-- db-maintenance`, which follows their dependencies.

-- migrate:down
SET ROLE = law_admin;

-- The row rewrite in step 1 is not reversible: the pin-cite links are gone,
-- and only a truncate and relink with the previous linker
-- (`./scripts/pipeline.sh --from truncate-links`, both corpora) brings them
-- back. This restores the constraints and the views as they were, with their
-- pin-cite columns, which read as false until that relink.
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_case_agreement;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_agreement;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_edges;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.case_case_citations;
DROP MATERIALIZED VIEW IF EXISTS moml_citations.case_edition_counts;
DROP MATERIALIZED VIEW IF EXISTS moml_citations.work_citation_counts;
DROP MATERIALIZED VIEW IF EXISTS moml_citations.edition_citation_counts;
DROP MATERIALIZED VIEW IF EXISTS moml_citations.edition_case_citations;

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

CREATE MATERIALIZED VIEW IF NOT EXISTS moml_citations.edition_case_citations AS
SELECT
  v.bibliographicid,
  CASE
    WHEN cl.cap_case_id IS NOT NULL THEN 'cap'
    WHEN cl.er_case_id IS NOT NULL THEN 'er'
    WHEN cl.code_reporter_id IS NOT NULL THEN 'code'
    ELSE 'stub'
  END AS source,
  cl.cap_case_id,
  cl.er_case_id,
  cl.code_reporter_id,
  cl.stub_cite,
  count(*) AS cite_count,
  count(*) FILTER (WHERE cl.match_tier IN ('cap_page_interior', 'er_page_interior'))
    = count(*) AS pincite_only
FROM moml_citations.citation_links cl
JOIN moml_citations.citations_unlinked cu ON cu.id = cl.citation_id
JOIN moml.volumes v ON v.psmid = cu.moml_treatise
WHERE cl.status LIKE 'linked%'
GROUP BY v.bibliographicid, cl.cap_case_id, cl.er_case_id, cl.code_reporter_id, cl.stub_cite
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW moml_citations.edition_case_citations IS 'One row for each MOML edition and each case it cites, from the linked citations in citation_links (issue #213). Exactly one of cap_case_id, er_case_id, code_reporter_id and stub_cite is set. Refreshed by make db-maintenance.';
COMMENT ON COLUMN moml_citations.edition_case_citations.source IS 'Which column holds the case: cap, er, code or stub.';
COMMENT ON COLUMN moml_citations.edition_case_citations.cite_count IS 'Number of linked citations from the edition to the case.';
COMMENT ON COLUMN moml_citations.edition_case_citations.pincite_only IS 'True when every citation from the edition to the case was linked through an interior page (cap_page_interior or er_page_interior), so the link exists only because of a pin cite.';

CREATE UNIQUE INDEX IF NOT EXISTS edition_case_citations_uq
  ON moml_citations.edition_case_citations
  (bibliographicid, cap_case_id, er_case_id, code_reporter_id, stub_cite) NULLS NOT DISTINCT;
CREATE INDEX IF NOT EXISTS edition_case_citations_cap_idx
  ON moml_citations.edition_case_citations (cap_case_id) WHERE cap_case_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS edition_case_citations_er_idx
  ON moml_citations.edition_case_citations (er_case_id) WHERE er_case_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS edition_case_citations_code_idx
  ON moml_citations.edition_case_citations (code_reporter_id) WHERE code_reporter_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS edition_case_citations_stub_idx
  ON moml_citations.edition_case_citations (stub_cite) WHERE stub_cite IS NOT NULL;

CREATE MATERIALIZED VIEW IF NOT EXISTS moml_citations.edition_citation_counts AS
WITH vols AS (
  SELECT v.bibliographicid,
         count(*)                     AS volumes,
         sum(v.total_pages)::bigint           AS pages,
         COALESCE(sum(tcc.n), 0)::bigint      AS cites,
         COALESCE(sum(tcc.linked), 0)::bigint AS linked
  FROM moml.volumes v
  LEFT JOIN moml_citations.treatise_citation_counts tcc ON tcc.moml_treatise = v.psmid
  GROUP BY v.bibliographicid
),
cases AS (
  SELECT bibliographicid,
         count(*)                                 AS cases,
         count(*) FILTER (WHERE NOT pincite_only) AS cases_not_pincite_only
  FROM moml_citations.edition_case_citations
  GROUP BY bibliographicid
)
SELECT t.bibliographicid,
       e.work_id,
       t.jurisdiction,
       t.year,
       t.title,
       e.author,
       t.vols,
       vols.volumes,
       vols.pages,
       e.derivative,
       vols.cites,
       vols.linked,
       COALESCE(cases.cases, 0)                  AS cases,
       COALESCE(cases.cases_not_pincite_only, 0) AS cases_not_pincite_only
FROM moml.treatises t
JOIN moml.editions e ON e.bibliographicid = t.bibliographicid
JOIN vols ON vols.bibliographicid = t.bibliographicid
LEFT JOIN cases ON cases.bibliographicid = t.bibliographicid
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW moml_citations.edition_citation_counts IS 'One row per treatise edition (moml.treatises, materialized) with its work, jurisdiction, year, title, volumes, pages, detected and linked citations, and the distinct cases it cites (issue #305). Refreshed by make db-maintenance.';
COMMENT ON COLUMN moml_citations.edition_citation_counts.cases_not_pincite_only IS 'Cases the edition reaches other than only through pin cites (edition_case_citations.pincite_only is false).';

CREATE UNIQUE INDEX IF NOT EXISTS edition_citation_counts_uq
  ON moml_citations.edition_citation_counts (bibliographicid);
CREATE INDEX IF NOT EXISTS edition_citation_counts_work_idx
  ON moml_citations.edition_citation_counts (work_id);
CREATE INDEX IF NOT EXISTS edition_citation_counts_cites_idx
  ON moml_citations.edition_citation_counts (cites DESC);

CREATE MATERIALIZED VIEW IF NOT EXISTS moml_citations.work_citation_counts AS
WITH cases AS (
  SELECT ecc.work_id,
         count(DISTINCT c.source || ':' || COALESCE(c.cap_case_id::text, c.er_case_id,
                                                    c.code_reporter_id::text, c.stub_cite)) AS cases
  FROM moml_citations.edition_case_citations c
  JOIN moml_citations.edition_citation_counts ecc ON ecc.bibliographicid = c.bibliographicid
  GROUP BY ecc.work_id
),
all_editions AS (
  SELECT work_id, count(*) AS n FROM moml.editions GROUP BY work_id
)
SELECT ecc.work_id,
       count(*)                                    AS editions,
       ae.n                                        AS all_editions,
       count(*) FILTER (WHERE ecc.derivative)      AS derivative_editions,
       min(ecc.year)                               AS first_year,
       max(ecc.year)                               AS last_year,
       bool_or(ecc.jurisdiction = 'US')            AS us,
       bool_or(ecc.jurisdiction = 'UK')            AS uk,
       sum(ecc.cites)::bigint                      AS cites,
       sum(ecc.linked)::bigint                     AS linked,
       COALESCE(max(cases.cases), 0)               AS cases
FROM moml_citations.edition_citation_counts ecc
JOIN all_editions ae ON ae.work_id = ecc.work_id
LEFT JOIN cases ON cases.work_id = ecc.work_id
GROUP BY ecc.work_id, ae.n
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW moml_citations.work_citation_counts IS 'One row per work with at least one treatise edition: its treatise editions, all its editions, the span of years, jurisdictions, citation totals and distinct cases cited (issue #305). Refreshed by make db-maintenance.';

CREATE UNIQUE INDEX IF NOT EXISTS work_citation_counts_uq
  ON moml_citations.work_citation_counts (work_id);
CREATE INDEX IF NOT EXISTS work_citation_counts_cites_idx
  ON moml_citations.work_citation_counts (cites DESC);

CREATE MATERIALIZED VIEW IF NOT EXISTS moml_citations.case_edition_counts AS
WITH agg AS (
  SELECT c.source, c.cap_case_id, c.er_case_id, c.code_reporter_id, c.stub_cite,
         count(*)                                   AS editions,
         count(*) FILTER (WHERE NOT c.pincite_only) AS editions_not_pincite_only,
         count(DISTINCT ecc.work_id)                AS works,
         sum(c.cite_count)::bigint                  AS cites,
         count(*) FILTER (WHERE ecc.jurisdiction = 'US') AS us_editions,
         min(ecc.year)                              AS first_cited,
         max(ecc.year)                              AS last_cited
  FROM moml_citations.edition_case_citations c
  JOIN moml_citations.edition_citation_counts ecc ON ecc.bibliographicid = c.bibliographicid
  GROUP BY c.source, c.cap_case_id, c.er_case_id, c.code_reporter_id, c.stub_cite
)
SELECT a.source,
       a.source || ':' || COALESCE(a.cap_case_id::text, a.er_case_id,
                                   a.code_reporter_id::text, a.stub_cite) AS case_key,
       a.cap_case_id, a.er_case_id, a.code_reporter_id, a.stub_cite,
       COALESCE(cc.name_abbreviation, er.murrell_title, er.er_name, code.name, sm.party_names) AS name,
       COALESCE(cc.decision_year, er.murrell_year, er.er_year, code.decision_year, sm.year_decided) AS year,
       COALESCE(capcite.cite, er.er_cite, code.official_citation, a.stub_cite) AS cite,
       a.editions, a.editions_not_pincite_only, a.works, a.cites,
       a.us_editions, a.first_cited, a.last_cited
FROM agg a
LEFT JOIN cap.cases cc ON cc.id = a.cap_case_id
LEFT JOIN LATERAL (
  SELECT ci.cite FROM cap.citations ci WHERE ci."case" = a.cap_case_id
  ORDER BY (ci.type = 'official') DESC, ci.cite LIMIT 1
) capcite ON true
LEFT JOIN english_reports.cases er ON er.id = a.er_case_id
LEFT JOIN legalhist.code_reporter code ON code.id = a.code_reporter_id
LEFT JOIN legalhist.stub_case_metadata sm ON sm.cite = a.stub_cite
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW moml_citations.case_edition_counts IS 'One row per case cited by treatise editions, with the case''s name, year and citation copied from its source, and the treatise editions, works and citations behind it (issue #305). case_key is source:id. Refreshed by make db-maintenance.';
COMMENT ON COLUMN moml_citations.case_edition_counts.editions_not_pincite_only IS 'Citing editions that reach the case other than only through pin cites.';
COMMENT ON COLUMN moml_citations.case_edition_counts.works IS 'Distinct works the citing editions belong to.';

CREATE UNIQUE INDEX IF NOT EXISTS case_edition_counts_key_uq
  ON moml_citations.case_edition_counts (case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_editions_idx
  ON moml_citations.case_edition_counts (editions DESC, case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_source_editions_idx
  ON moml_citations.case_edition_counts (source, editions DESC, case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_works_idx
  ON moml_citations.case_edition_counts (works DESC, case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_cites_idx
  ON moml_citations.case_edition_counts (cites DESC, case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_not_pincite_idx
  ON moml_citations.case_edition_counts (editions_not_pincite_only DESC, case_key);
CREATE INDEX IF NOT EXISTS case_edition_counts_cite_idx
  ON moml_citations.case_edition_counts (cite);
CREATE INDEX IF NOT EXISTS case_edition_counts_name_trgm_idx
  ON moml_citations.case_edition_counts USING gin (name gin_trgm_ops);

CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.case_case_citations AS
SELECT
  cu.cap_case AS citing_case_id,
  CASE
    WHEN cl.cap_case_id IS NOT NULL THEN 'cap'
    WHEN cl.er_case_id IS NOT NULL THEN 'er'
    WHEN cl.code_reporter_id IS NOT NULL THEN 'code'
    ELSE 'stub'
  END AS source,
  cl.cap_case_id,
  cl.er_case_id,
  cl.code_reporter_id,
  cl.stub_cite,
  count(*) AS cite_count,
  count(DISTINCT cu.cap_opinion) AS opinion_count,
  count(*) FILTER (WHERE cl.match_tier IN ('cap_page_interior', 'er_page_interior'))
    = count(*) AS pincite_only,
  coalesce(cl.cap_case_id = cu.cap_case, false) AS self_cite
FROM opinion_citations.citation_links cl
JOIN opinion_citations.citations_unlinked cu ON cu.id = cl.citation_id
WHERE cl.status LIKE 'linked%'
GROUP BY cu.cap_case, cl.cap_case_id, cl.er_case_id, cl.code_reporter_id, cl.stub_cite
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW opinion_citations.case_case_citations IS 'One row for each CAP case and each case its opinions cite, from the linked citations in opinion_citations.citation_links (issue #74); the twin of moml_citations.edition_case_citations. Exactly one of cap_case_id, er_case_id, code_reporter_id and stub_cite is set. Refreshed by make db-maintenance.';
COMMENT ON COLUMN opinion_citations.case_case_citations.citing_case_id IS 'The citing case, cap.cases.id.';
COMMENT ON COLUMN opinion_citations.case_case_citations.source IS 'Which column holds the cited case: cap, er, code or stub.';
COMMENT ON COLUMN opinion_citations.case_case_citations.cite_count IS 'Number of linked citations from the citing case''s opinions to the case.';
COMMENT ON COLUMN opinion_citations.case_case_citations.opinion_count IS 'Number of the citing case''s opinions that cite the case.';
COMMENT ON COLUMN opinion_citations.case_case_citations.pincite_only IS 'True when every citation from the citing case to the case was linked through an interior page (cap_page_interior or er_page_interior), so the link exists only because of a pin cite.';
COMMENT ON COLUMN opinion_citations.case_case_citations.self_cite IS 'True when the cited CAP case is the citing case: an opinion citing its own case. Kept by the linker, left out of the comparison with CAP''s graph.';

CREATE UNIQUE INDEX IF NOT EXISTS case_case_citations_uq
  ON opinion_citations.case_case_citations
  (citing_case_id, cap_case_id, er_case_id, code_reporter_id, stub_cite) NULLS NOT DISTINCT;
CREATE INDEX IF NOT EXISTS case_case_citations_cap_idx
  ON opinion_citations.case_case_citations (cap_case_id) WHERE cap_case_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS case_case_citations_er_idx
  ON opinion_citations.case_case_citations (er_case_id) WHERE er_case_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS case_case_citations_code_idx
  ON opinion_citations.case_case_citations (code_reporter_id) WHERE code_reporter_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS case_case_citations_stub_idx
  ON opinion_citations.case_case_citations (stub_cite) WHERE stub_cite IS NOT NULL;

CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.cap_graph_edges AS
WITH ours AS (
  SELECT ccc.citing_case_id AS citing,
         ccc.cap_case_id AS cited,
         ccc.cite_count,
         ccc.pincite_only
  FROM opinion_citations.case_case_citations ccc
  JOIN opinion_citations.cap_graph_scope s ON s.id = ccc.citing_case_id
  WHERE ccc.source = 'cap' AND NOT ccc.self_cite
),
theirs AS (
  SELECT DISTINCT cc.cites_from::bigint AS citing, cc.cites_to::bigint AS cited
  FROM cap_citations.citations cc
  JOIN opinion_citations.cap_graph_scope s ON s.id = cc.cites_from
  WHERE cc.cites_from <> cc.cites_to
)
SELECT coalesce(o.citing, t.citing) AS citing_case_id,
       coalesce(o.cited, t.cited) AS cited_case_id,
       o.citing IS NOT NULL AS in_ours,
       t.citing IS NOT NULL AS in_theirs,
       o.cite_count,
       o.pincite_only,
       s.decision_year AS citing_year,
       s.jurisdiction AS citing_jurisdiction,
       k.decision_year AS cited_year,
       k.jurisdiction AS cited_jurisdiction,
       k.reporter AS cited_reporter
FROM ours o
FULL OUTER JOIN theirs t ON t.citing = o.citing AND t.cited = o.cited
JOIN opinion_citations.cap_graph_scope s ON s.id = coalesce(o.citing, t.citing)
JOIN cap.cases k ON k.id = coalesce(o.cited, t.cited)
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS cap_graph_edges_uq
  ON opinion_citations.cap_graph_edges (citing_case_id, cited_case_id);
CREATE INDEX IF NOT EXISTS cap_graph_edges_disagree_idx
  ON opinion_citations.cap_graph_edges (cited_reporter, in_ours, cited_case_id, citing_case_id)
  WHERE in_ours <> in_theirs;

COMMENT ON MATERIALIZED VIEW opinion_citations.cap_graph_edges IS 'One row per edge from a citing case in cap_graph_scope to a CAP case, in our links (case_case_citations, self-cites left out), in CAP''s graph (cap_citations.citations), or both (issue #349). cite_count and pincite_only are NULL on an edge we lack. Refreshed by make db-maintenance.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.in_ours IS 'True when our links have the edge.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.in_theirs IS 'True when CAP''s graph has the edge.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.pincite_only IS 'True when every one of our citations behind the edge linked through an interior page; NULL when we lack the edge.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.cited_reporter IS 'The cited case''s reporter, cap.reporters.id.';

CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.cap_graph_agreement AS
SELECT citing_year,
       citing_jurisdiction,
       cited_jurisdiction,
       cited_reporter,
       count(*) FILTER (WHERE in_ours AND in_theirs) AS in_both,
       count(*) FILTER (WHERE in_ours AND NOT in_theirs) AS ours_only,
       count(*) FILTER (WHERE in_theirs AND NOT in_ours) AS theirs_only,
       count(*) FILTER (WHERE in_ours AND NOT in_theirs AND pincite_only) AS ours_only_pincite
FROM opinion_citations.cap_graph_edges
GROUP BY citing_year, citing_jurisdiction, cited_jurisdiction, cited_reporter
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS cap_graph_agreement_uq
  ON opinion_citations.cap_graph_agreement (citing_year, citing_jurisdiction, cited_jurisdiction, cited_reporter);
CREATE INDEX IF NOT EXISTS cap_graph_agreement_reporter_idx
  ON opinion_citations.cap_graph_agreement (cited_reporter);

COMMENT ON MATERIALIZED VIEW opinion_citations.cap_graph_agreement IS 'Edges in both graphs, ours only and theirs only, by the citing case''s year and jurisdiction and the cited case''s jurisdiction and reporter (issue #349). Refreshed by make db-maintenance.';

CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.cap_graph_case_agreement AS
SELECT s.id AS citing_case_id,
       s.decision_year AS citing_year,
       s.jurisdiction AS citing_jurisdiction,
       count(e.citing_case_id) FILTER (WHERE e.in_ours AND e.in_theirs) AS in_both,
       count(e.citing_case_id) FILTER (WHERE e.in_ours AND NOT e.in_theirs) AS ours_only,
       count(e.citing_case_id) FILTER (WHERE e.in_theirs AND NOT e.in_ours) AS theirs_only,
       count(e.citing_case_id) FILTER (WHERE e.in_ours AND NOT e.in_theirs AND e.pincite_only) AS ours_only_pincite
FROM opinion_citations.cap_graph_scope s
LEFT JOIN opinion_citations.cap_graph_edges e ON e.citing_case_id = s.id
GROUP BY s.id, s.decision_year, s.jurisdiction
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS cap_graph_case_agreement_pkey
  ON opinion_citations.cap_graph_case_agreement (citing_case_id);
CREATE INDEX IF NOT EXISTS cap_graph_case_agreement_ours_idx
  ON opinion_citations.cap_graph_case_agreement (ours_only DESC);
CREATE INDEX IF NOT EXISTS cap_graph_case_agreement_theirs_idx
  ON opinion_citations.cap_graph_case_agreement (theirs_only DESC);

COMMENT ON MATERIALIZED VIEW opinion_citations.cap_graph_case_agreement IS 'Edges in both graphs, ours only and theirs only, for each citing case in cap_graph_scope, zeros included (issue #349). Refreshed by make db-maintenance.';
