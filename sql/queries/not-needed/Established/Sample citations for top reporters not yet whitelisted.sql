SELECT cites.reporter_abbr, to_whitelist.n, cites.raw, cites.volume, cites.reporter_abbr, cites.page, bi.productlink, cites.moml_page FROM 
(SELECT * FROM output.top_reporters tr
LEFT JOIN legalhist.reporters_citation_to_cap wl ON tr.reporter_abbr = wl.reporter_found
WHERE wl.reporter_found IS NULL AND n > 1000
ORDER BY tr.n DESC) to_whitelist
LEFT JOIN (SELECT ROW_NUMBER() OVER (PARTITION BY reporter_abbr) AS r, c.* FROM output.moml_citations c) cites ON to_whitelist.reporter_abbr = cites.reporter_abbr
LEFT JOIN moml.book_info bi ON cites.moml_treatise = bi.psmid
WHERE cites.r <= 20 ORDER BY n DESC;