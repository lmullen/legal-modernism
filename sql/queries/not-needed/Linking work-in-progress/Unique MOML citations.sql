--CREATE TABLE output.moml_cases_cited_top AS
SELECT cases_cited.volume, cases_cited.reporter_cap, cases_cited.page, cases_cited.n, cases_cited.cleaner_cite, cases_cited.cleaner_cite AS corrected_cite,
cap_cites.case AS case_id
FROM (
SELECT cites.volume, clean.reporter_cap, cites.page, COUNT(*) AS n,
cites.volume || ' ' || clean.reporter_cap || ' ' || cites.page AS cleaner_cite
FROM output.moml_citations cites
LEFT JOIN legalhist.reporters_citation_to_cap clean ON cites.reporter_abbr = clean.reporter_found
WHERE clean.reporter_cap IS NOT NULL 
GROUP BY volume, clean.reporter_cap, page
HAVING COUNT(*) >= 10
) cases_cited
LEFT JOIN (SELECT DISTINCT ON (cite) cite, "case" FROM cap.citations) cap_cites ON cases_cited.cleaner_cite = cap_cites.cite
ORDER BY n DESC;