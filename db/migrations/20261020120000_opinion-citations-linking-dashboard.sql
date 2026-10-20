-- migrate:up
SET ROLE = law_admin;

-- The linking dashboard's views for the CAP corpus (issue #347): the twins of
-- moml_citations.linking_dashboard_summary, _reporters, _tiers and
-- linking_tier_summary, and of legalhist.top_reporters, over
-- opinion_citations.citations_unlinked and citation_links. Chambers reads them
-- for /linking/cap, /linking/cap/tiers and the whitelist extender's CAP
-- spellings. Each is the MOML definition with the schema swapped; the CAP
-- linker writes the same statuses and tiers, so nothing else changes.
--
-- Measured read-only on 2026-10-20 over the first --corpus cap run (9,763,117
-- citations): the summary's SELECT takes 2.0 s, the tiers' 5.7 s (3,770
-- rows), the spellings' 1.0 s (127,487 rows). Built WITH NO DATA, like the
-- other materialized views; `make db-maintenance` (db/maintenance.sh) finds and
-- refreshes them, all at level 0.

-- One row per metric: the citations detected, the citations under each
-- status, and those with no link row yet.
CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.linking_dashboard_summary AS
 SELECT 'total_raw_cites'::text AS metric,
        count(*) AS n
   FROM opinion_citations.citations_unlinked
UNION ALL
 SELECT status AS metric,
        count(*) AS n
   FROM opinion_citations.citation_links
  GROUP BY status
UNION ALL
 SELECT 'unprocessed'::text AS metric,
        (SELECT count(*) FROM opinion_citations.citations_unlinked)
      - (SELECT count(*) FROM opinion_citations.citation_links) AS n
  WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS linking_dashboard_summary_uq
  ON opinion_citations.linking_dashboard_summary USING btree (metric);

COMMENT ON MATERIALIZED VIEW opinion_citations.linking_dashboard_summary IS 'Citation counts by linking status for the CAP corpus, with total_raw_cites and unprocessed; the twin of moml_citations.linking_dashboard_summary (issue #347). Refreshed by make db-maintenance.';

-- One row per reporter standard: its whitelisted, non-junk, non-statute
-- citations that linked, failed to match, or have not been linked.
CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.linking_dashboard_reporters AS
 SELECT wl.reporter_standard,
        count(*) FILTER (WHERE cl.status LIKE 'linked%') AS linked,
        count(*) FILTER (WHERE cl.status = 'no_match') AS no_match,
        count(*) FILTER (WHERE cl.status IS NULL) AS unprocessed,
        COALESCE(bool_or(r.jurisdiction LIKE 'uk:%'), false) AS uk
   FROM opinion_citations.citations_unlinked cu
   JOIN legalhist.whitelist wl ON cu.reporter_abbr = wl.reporter_found
   JOIN legalhist.reporters r ON r.reporter_standard = wl.reporter_standard
   LEFT JOIN opinion_citations.citation_links cl ON cl.citation_id = cu.id
  WHERE wl.reporter_standard IS NOT NULL
    AND wl.junk = false
    AND COALESCE(r.type, '') <> 'statute'
  GROUP BY wl.reporter_standard
  WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS linking_dashboard_reporters_uq
  ON opinion_citations.linking_dashboard_reporters USING btree (reporter_standard);

COMMENT ON MATERIALIZED VIEW opinion_citations.linking_dashboard_reporters IS 'Linked, no_match and unprocessed citations per reporter standard for the CAP corpus; the twin of moml_citations.linking_dashboard_reporters (issue #347). Refreshed by make db-maintenance.';

-- One row per reporter standard, status and match tier.
CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.linking_dashboard_tiers AS
 SELECT wl.reporter_standard,
        cl.status,
        cl.match_tier,
        count(*) AS n
   FROM opinion_citations.citations_unlinked cu
   JOIN legalhist.whitelist wl ON cu.reporter_abbr = wl.reporter_found
   LEFT JOIN opinion_citations.citation_links cl ON cl.citation_id = cu.id
  WHERE wl.reporter_standard IS NOT NULL
    AND wl.junk = false
  GROUP BY wl.reporter_standard, cl.status, cl.match_tier
  WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS linking_dashboard_tiers_uq
  ON opinion_citations.linking_dashboard_tiers USING btree (reporter_standard, status, match_tier) NULLS NOT DISTINCT;

COMMENT ON MATERIALIZED VIEW opinion_citations.linking_dashboard_tiers IS 'Whitelisted, non-junk citations per reporter standard, status and match tier for the CAP corpus; the twin of moml_citations.linking_dashboard_tiers (issue #347). Refreshed by make db-maintenance.';

-- The corpus-wide status x tier breakdown. A plain view: it is a small
-- aggregate of linking_dashboard_tiers, and no materialized view reads it.
CREATE OR REPLACE VIEW opinion_citations.linking_tier_summary AS
 SELECT COALESCE(status, 'unprocessed') AS status,
        match_tier,
        sum(n) AS n,
        round(100.0 * sum(n) / sum(sum(n)) OVER (PARTITION BY status), 2) AS pct_of_status
   FROM opinion_citations.linking_dashboard_tiers
  GROUP BY status, match_tier
  ORDER BY sum(n) DESC;

COMMENT ON VIEW opinion_citations.linking_tier_summary IS 'Citations per status and match tier over the CAP corpus, with each tier''s share of its status; the twin of moml_citations.linking_tier_summary (issue #347).';

-- One row per spelling the detector found in the opinions, with its count and
-- the number of citing cases. The whitelist extender reads it for the CAP
-- spellings the whitelist does not know.
CREATE MATERIALIZED VIEW IF NOT EXISTS opinion_citations.top_reporters AS
 SELECT reporter_abbr,
        count(*) AS n,
        count(DISTINCT cap_case) AS citing_cases
   FROM opinion_citations.citations_unlinked
  GROUP BY reporter_abbr
  WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS top_reporters_reporter_abbr_uq
  ON opinion_citations.top_reporters USING btree (reporter_abbr);
CREATE INDEX IF NOT EXISTS top_reporters_n_idx
  ON opinion_citations.top_reporters USING btree (n DESC);

COMMENT ON MATERIALIZED VIEW opinion_citations.top_reporters IS 'Each reporter spelling detected in the CAP opinions, with its citations and citing cases; the twin of legalhist.top_reporters (issue #347). Refreshed by make db-maintenance.';

-- After this migration the views are empty. Populate them with `make
-- db-maintenance`, or alone with REFRESH MATERIALIZED VIEW on each.

-- migrate:down
SET ROLE = law_admin;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.top_reporters;
DROP VIEW IF EXISTS opinion_citations.linking_tier_summary;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.linking_dashboard_tiers;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.linking_dashboard_reporters;
DROP MATERIALIZED VIEW IF EXISTS opinion_citations.linking_dashboard_summary;
