-- migrate:up
SET ROLE = law_admin;

-- Our CAP-to-CAP links set against CAP's own citation graph (issues #74, #349),
-- materialized for the chambers page /linking/cap. The comparison is the one
-- db/queries/opinion-citations-vs-cap-graph.sql made by hand; these views are
-- now its definition, and the script reads them.
--
-- cite-detector-cap and cite-linker-cap find and link citations in the text
-- of cap.opinions; opinion_citations.case_case_citations aggregates the links
-- to one row per citing case and cited case. CAP publishes its own
-- case-to-case graph, cap_citations.citations (cites_from, cites_to),
-- extracted from the same text by its own means. Neither is the truth: where
-- they agree each corroborates the other, and where they differ one found
-- what the other missed or made something up.
--
-- Three views, each reading the one before directly, so that db/maintenance.sh
-- (which follows only materialized views reading materialized views) refreshes
-- them in order: cap_graph_scope at level 0, cap_graph_edges at level 1 (it
-- also reads case_case_citations, level 0), and the two aggregates at level 2.
-- A plain view in between would hide the dependency and let an aggregate
-- refresh before the edges it counts.
--
-- Measured read-only on 2026-10-20 over the first --corpus cap run: the
-- scope's SELECT takes 20 s (1,058,387 cases); the edges' 63 s (7,413,891
-- edges: 3,884,023 in both, 1,153,832 ours only, 2,376,036 theirs only, the
-- totals on #74); an aggregate over them comes to 213,515 rows. Of the
-- ours-only edges 602,759 (52%) exist only through pin cites; no theirs-only
-- edge points at a case decided after the citing case. Built WITH NO DATA,
-- like the other materialized views; `make db-maintenance` finds and
-- refreshes them.

-- The citing cases the comparison covers: decided by 1920 (the detector's
-- --max-year in slurm/cite-detector-cap.sh), with at least one opinion, and
-- in cap_citations.metadata, whose ids are cap.cases ids. The two do not
-- coincide: about a quarter of the cases we detect over have no CAP edges to
-- compare against, and they are left out rather than counted as ours-only.
-- This is the only place the rule is stated.
CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.cap_graph_scope AS
SELECT c.id,
       c.decision_year,
       c.jurisdiction,
       c.court
FROM cap.cases c
WHERE c.decision_year <= 1920
  AND EXISTS (SELECT 1 FROM cap_citations.metadata m WHERE m.id = c.id)
  AND EXISTS (SELECT 1 FROM cap.opinions o WHERE o."case" = c.id)
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS cap_graph_scope_pkey
  ON opinion_citations.cap_graph_scope (id);

COMMENT ON MATERIALIZED VIEW opinion_citations.cap_graph_scope IS 'The citing CAP cases the comparison with CAP''s citation graph covers: decided by 1920, with an opinion, and in cap_citations.metadata (issue #349). Refreshed by make db-maintenance.';

-- One row per edge, a citing case and a cited CAP case, in either graph. ours
-- is the CAP-to-CAP rows of case_case_citations without self-cites (CAP's
-- graph has none); theirs is the distinct (cites_from, cites_to) pairs. Both
-- ends are in cap.cases, because our links can only point at its rows: the
-- join to cap.cases drops the CAP edges whose cited case it lacks.
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

-- The grain, and the edges of one citing case (the per-case page).
CREATE UNIQUE INDEX IF NOT EXISTS cap_graph_edges_uq
  ON opinion_citations.cap_graph_edges (citing_case_id, cited_case_id);
-- The disagreeing edges to a cited reporter, on one side (the reporter page).
CREATE INDEX IF NOT EXISTS cap_graph_edges_disagree_idx
  ON opinion_citations.cap_graph_edges (cited_reporter, in_ours, cited_case_id, citing_case_id)
  WHERE in_ours <> in_theirs;

COMMENT ON MATERIALIZED VIEW opinion_citations.cap_graph_edges IS 'One row per edge from a citing case in cap_graph_scope to a CAP case, in our links (case_case_citations, self-cites left out), in CAP''s graph (cap_citations.citations), or both (issue #349). cite_count and pincite_only are NULL on an edge we lack. Refreshed by make db-maintenance.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.in_ours IS 'True when our links have the edge.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.in_theirs IS 'True when CAP''s graph has the edge.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.pincite_only IS 'True when every one of our citations behind the edge linked through an interior page; NULL when we lack the edge.';
COMMENT ON COLUMN opinion_citations.cap_graph_edges.cited_reporter IS 'The cited case''s reporter, cap.reporters.id.';

-- The agreement at the grain of the citing case's year and jurisdiction and
-- the cited case's jurisdiction and reporter: small enough that every roll-up
-- the page shows is a scan of it. ours_only_pincite is the ours-only edges
-- that exist only through pin cites, which issue #242 found are often OCR
-- noise.
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

-- The agreement per citing case, every case in scope included, a case with
-- no edge on either side as zeros: how the disagreement is spread, and the
-- cases where it is heaviest.
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

-- After this migration the views are empty. Populate them with `make
-- db-maintenance`, or alone, in this order:
--   REFRESH MATERIALIZED VIEW opinion_citations.cap_graph_scope;
--   REFRESH MATERIALIZED VIEW opinion_citations.cap_graph_edges;
--   REFRESH MATERIALIZED VIEW opinion_citations.cap_graph_agreement;
--   REFRESH MATERIALIZED VIEW opinion_citations.cap_graph_case_agreement;

-- migrate:down
SET ROLE = law_admin;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_case_agreement;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_agreement;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_edges;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.cap_graph_scope;
