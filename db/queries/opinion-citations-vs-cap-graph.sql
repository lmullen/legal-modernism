-- Our links from the CAP opinions to CAP cases, set against CAP's own
-- citation graph (issue #74).
--
-- cite-detector-cap finds citations in the text of cap.opinions and
-- cite-linker-cap links them; opinion_citations.case_case_citations
-- aggregates the links to one row per citing case and cited case. CAP
-- publishes its own case-to-case graph, cap_citations.citations (cites_from,
-- cites_to), extracted from the same text by its own means. Where the two
-- agree, each corroborates the other; where they differ, one has found what
-- the other missed, or made something up, and the difference is what to look
-- at. Neither is the truth, so a low number on either side is a lead, not a
-- verdict.
--
-- The comparison is materialized (issue #349,
-- db/migrations/20261020120100_opinion-citations-cap-graph.sql), and the
-- views are its definition: opinion_citations.cap_graph_scope is the citing
-- cases it covers, cap_graph_edges every edge in either graph with in_ours and
-- in_theirs, and cap_graph_agreement and cap_graph_case_agreement their
-- aggregates by year, jurisdiction and reporter and by citing case. The
-- chambers page /linking/cap reads the same views.
--
-- Scope. A citing case counts when it was decided by 1920 (the detector's
-- --max-year), has at least one opinion, and is in both cap.cases and
-- cap_citations.metadata. metadata.id is the cap.cases.id space, but the two
-- do not coincide: measured 2026-09-26, 4,367 of metadata's 5,084,607 ids are
-- not in cap.cases, and of the 1,408,784 cases with cap.cases.decision_year
-- <= 1920 metadata holds 1,059,076, of which 1,058,387 have an opinion. So
-- about a quarter of the cases we detect over have no CAP edges to compare
-- against, and they are left out rather than counted as ours-only. On the
-- cited side both endpoints must be in cap.cases, because our links can only
-- point at cap.cases rows: a cites_to outside it is unreachable for us and is
-- left out of theirs.
--
-- ours is the CAP-to-CAP rows of case_case_citations, without self-cites (an
-- opinion citing its own case, which CAP's graph does not record either).
-- theirs is the distinct (cites_from, cites_to) pairs. Both are sets of edges:
-- a case that cites another twice is one edge on either side.
--
-- The first --corpus cap run (2026-09-26, results on #74): 3,884,023 edges in
-- both, 1,153,832 ours only, 2,376,036 theirs only; recall 62.0%, precision
-- 77.1%. Of the ours-only edges, 602,759 (52%) existed only through pin
-- cites, which the linker no longer resolves (issue #393).
-- Of the theirs-only edges, most cite a case none of whose cites occurs in the
-- opinion text at all: 924 of 942 in a sample of 400 citing cases in scope
-- (2026-10-20, the chambers page /linking/cap/cases/{id} sorts each one), so
-- CAP's graph draws on text that cap.opinions does not hold, and recall
-- against it is bounded by that more than by the detector.
--
-- Read-only; run with LAW_CLAUDE. Queries 1 to 4 read the views, so they need
-- make db-maintenance after a cite-linker-cap run, and take seconds; queries
-- 5 and 6 read the ledger itself.
SET statement_timeout = '30min';

-- 1 and 2. Agreement between the two graphs, overall (the first row, with a
--    NULL year) and by the citing case's decision year. in_both: edges in
--    ours and in theirs; ours_only and theirs_only: in one and not the other.
--    recall = in_both / theirs, how much of CAP's graph we find; precision =
--    in_both / ours, how much of what we find CAP also has.
SELECT citing_year AS decision_year,
       sum(in_both) AS in_both,
       sum(ours_only) AS ours_only,
       sum(theirs_only) AS theirs_only,
       round(100.0 * sum(in_both) / nullif(sum(in_both) + sum(theirs_only), 0), 2) AS recall_pct,
       round(100.0 * sum(in_both) / nullif(sum(in_both) + sum(ours_only), 0), 2) AS precision_pct
FROM opinion_citations.cap_graph_agreement
GROUP BY GROUPING SETS ((citing_year), ())
ORDER BY citing_year NULLS FIRST;

-- 3. Disagreement by the cited case's reporter. A reporter with many
--    theirs_only edges is one our detector or the whitelist misses (a
--    spelling the treatises never used, a renumbered series, a reporter cited
--    by year); one with many ours_only edges is where we find what CAP's
--    extractor did not, or link a cite to the wrong case.
SELECT r.short_name AS reporter, r.id AS reporter_id,
       sum(a.in_both) AS in_both,
       sum(a.ours_only) AS ours_only,
       sum(a.theirs_only) AS theirs_only
FROM opinion_citations.cap_graph_agreement a
JOIN cap.reporters r ON r.id = a.cited_reporter
GROUP BY r.id, r.short_name
ORDER BY sum(a.ours_only + a.theirs_only) DESC, r.short_name
LIMIT 50;

-- 4. How the disagreement is spread over the citing cases: percentiles and
--    the maximum of each count per case, over every case in scope (a case
--    with no edge on either side counts as zeros). A few cases with many
--    ours_only edges point at a runaway detection, such as a list of
--    authorities in the text; the same total spread thinly is systematic.
SELECT count(*) AS citing_cases,
       count(*) FILTER (WHERE in_both + ours_only + theirs_only = 0) AS no_edges,
       count(*) FILTER (WHERE ours_only = 0 AND theirs_only = 0 AND in_both > 0) AS agreeing,
       percentile_cont(ARRAY[0.5, 0.9, 0.99]) WITHIN GROUP (ORDER BY in_both) AS in_both_p50_p90_p99,
       max(in_both) AS in_both_max,
       percentile_cont(ARRAY[0.5, 0.9, 0.99]) WITHIN GROUP (ORDER BY ours_only) AS ours_only_p50_p90_p99,
       max(ours_only) AS ours_only_max,
       percentile_cont(ARRAY[0.5, 0.9, 0.99]) WITHIN GROUP (ORDER BY theirs_only) AS theirs_only_p50_p90_p99,
       max(theirs_only) AS theirs_only_max
FROM opinion_citations.cap_graph_case_agreement;

-- 5. The spellings the linker skipped as not whitelisted, by count, from the
--    ledger. opinion_citations.top_reporters holds the same counts for the
--    chambers whitelist extender (/linking/whitelist?corpus=cap) and the CAP
--    dashboard, read against the whitelist as it stands. A spelling high on this list is
--    a reporter the courts cite that the whitelist, built from the treatises,
--    does not know, or a court's spelling of one it does.
SELECT cu.reporter_abbr,
       count(*) AS citations,
       count(DISTINCT cu.cap_case) AS citing_cases
FROM opinion_citations.citation_links cl
JOIN opinion_citations.citations_unlinked cu ON cu.id = cl.citation_id
WHERE cl.status = 'skipped_not_whitelisted'
GROUP BY cu.reporter_abbr
ORDER BY citations DESC, cu.reporter_abbr
LIMIT 50;

-- 6. Links to a case decided later in the same year as the citing case: what
--    a date-granular anachronism gate would refuse. The linker's gate compares
--    years (issue #319), so an opinion of March cannot link to a case decided
--    the next year, but can to one decided that December. Self-cites are left
--    out; a link to a later year would be a failure of the gate and is counted
--    apart as a check. The overall row comes first, then by tier.
SELECT cl.match_tier,
       count(*) AS links,
       count(*) FILTER (WHERE k.decision_year = c.decision_year
                          AND k.decision_date > c.decision_date) AS same_year_later_date,
       round(100.0 * count(*) FILTER (WHERE k.decision_year = c.decision_year
                                        AND k.decision_date > c.decision_date)
             / count(*), 2) AS pct,
       count(DISTINCT cu.cap_case) FILTER (WHERE k.decision_year = c.decision_year
                                             AND k.decision_date > c.decision_date) AS citing_cases,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY k.decision_date - c.decision_date)
         FILTER (WHERE k.decision_year = c.decision_year
                   AND k.decision_date > c.decision_date) AS median_days_later,
       count(*) FILTER (WHERE k.decision_year > c.decision_year) AS later_year
FROM opinion_citations.citation_links cl
JOIN opinion_citations.citations_unlinked cu ON cu.id = cl.citation_id
JOIN cap.cases c ON c.id = cu.cap_case
JOIN cap.cases k ON k.id = cl.cap_case_id
WHERE cl.status = 'linked_cap'
  AND cl.cap_case_id <> cu.cap_case
GROUP BY GROUPING SETS ((cl.match_tier), ())
ORDER BY cl.match_tier NULLS FIRST;
