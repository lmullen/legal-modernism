SELECT 
	cites.moml_treatise,
	cites.moml_page,
	cites.raw,
	cites.volume,
	cites.reporter_abbr,
	cites.page,
	reporters.full_name,
	cases.case_id,
	cases.name_abbreviation,
	cases.decision_date
 FROM output.moml_citations cites
LEFT JOIN reporters_citation_to_cap cleanup ON cites.reporter_abbr = cleanup.reporter_found
LEFT JOIN cap.reporters reporters ON cleanup.reporter_cap = reporters.short_name
LEFT JOIN cap.cases cases ON cites.volume::varchar(510) = cases.volume_number AND reporters.full_name = cases.reporter_full_name AND cites.page::varchar(510) = cases.first_page
WHERE cites.moml_treatise = '19004617901' AND cleanup.reporter_standard = 'N.Y.'
ORDER BY cites.moml_page;
