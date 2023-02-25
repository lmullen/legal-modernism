SELECT moml_treatise, moml_page, volume, cites.reporter_abbr, wl.reporter_standard, page
FROM output.moml_citations cites
LEFT JOIN legalhist.reporters_citation_to_cap wl ON cites.reporter_abbr = wl.reporter_found
WHERE wl.reporter_standard = 'Code Rep.';
