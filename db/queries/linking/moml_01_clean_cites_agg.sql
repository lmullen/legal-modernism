SELECT COUNT(*) AS n, cites.volume, clean.reporter_standard, cites.page, 
cites.volume || ' ' || clean.reporter_standard || ' ' || cites.page AS cleaner_cite
FROM output.moml_citations cites
LEFT JOIN legalhist.reporters_citation_to_cap clean ON cites.reporter_abbr = clean.reporter_found
WHERE clean.reporter_cap IS NOT NULL 
GROUP BY volume, clean.reporter_standard, page
HAVING COUNT(*) >= 10;