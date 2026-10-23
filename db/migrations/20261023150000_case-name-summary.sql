-- migrate:up
SET ROLE = law_admin;

-- How far the detected case names (citations_unlinked.case_name, issue #387)
-- reach, for the linking dashboards (issue #392): one row per link status,
-- match tier and case_name_source, with the citations in it, for each corpus.
-- A NULL case_name_source is a citation with no name; a NULL status is one
-- with no link row yet, named 'unprocessed' as linking_tier_summary does.
-- Chambers' /linking and /linking/cap read these for their Case names
-- section: the share of citations with a name by status and by tier, and the
-- source mix.
--
-- One pass over the join of the two tables, like linking_dashboard_tiers.
-- Built WITH NO DATA; `make db-maintenance` (db/maintenance.sh) finds and
-- refreshes them, at level 0.

CREATE MATERIALIZED VIEW IF NOT EXISTS moml_citations.case_name_summary AS
 SELECT COALESCE(cl.status, 'unprocessed') AS status,
        cl.match_tier,
        cu.case_name_source,
        count(*) AS n
   FROM moml_citations.citations_unlinked cu
   LEFT JOIN moml_citations.citation_links cl ON cl.citation_id = cu.id
  GROUP BY 1, 2, 3
  WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS case_name_summary_uq
  ON moml_citations.case_name_summary USING btree (status, match_tier, case_name_source) NULLS NOT DISTINCT;

COMMENT ON MATERIALIZED VIEW moml_citations.case_name_summary IS 'Citations per link status, match tier and case_name_source over the MOML corpus; a NULL source is a citation with no detected case name (issues #387, #392). Refreshed by make db-maintenance.';

CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.case_name_summary AS
 SELECT COALESCE(cl.status, 'unprocessed') AS status,
        cl.match_tier,
        cu.case_name_source,
        count(*) AS n
   FROM opinion_citations.citations_unlinked cu
   LEFT JOIN opinion_citations.citation_links cl ON cl.citation_id = cu.id
  GROUP BY 1, 2, 3
  WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS case_name_summary_uq
  ON opinion_citations.case_name_summary USING btree (status, match_tier, case_name_source) NULLS NOT DISTINCT;

COMMENT ON MATERIALIZED VIEW opinion_citations.case_name_summary IS 'Citations per link status, match tier and case_name_source over the CAP corpus; the twin of moml_citations.case_name_summary (issues #387, #392). Refreshed by make db-maintenance.';

-- After this migration the views are empty. Populate them with `make
-- db-maintenance`, or alone with REFRESH MATERIALIZED VIEW on each.

-- migrate:down
SET ROLE = law_admin;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.case_name_summary;
DROP MATERIALIZED VIEW IF EXISTS moml_citations.case_name_summary;
