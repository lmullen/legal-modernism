SELECT * 
FROM    legalhist.reporters_citation_to_cap cleanup
LEFT JOIN cap.reporters cap
ON      cleanup.reporter_cap = cap.short_name
WHERE   cap.short_name IS NULL AND NOT cleanup.statute AND NOT cleanup.uk AND cleanup.reporter_cap IS NOT NULL