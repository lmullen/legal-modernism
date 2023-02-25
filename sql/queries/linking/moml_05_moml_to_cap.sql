SELECT 
moml_w_clean_cite.id, 
moml_w_clean_cite.moml_treatise,
moml_w_clean_cite.moml_page,
moml_w_clean_cite.cite_in_moml,
with_links.cap_link_cite,
with_links.case
 FROM (SELECT
	cites.id,
	cites.moml_treatise,
	cites.moml_page,
	cites.volume || ' '::text || clean.reporter_standard || ' '::text || cites.page AS cite_in_moml
FROM
	output.moml_citations cites
	LEFT JOIN legalhist.reporters_citation_to_cap clean ON cites.reporter_abbr = clean.reporter_found) AS moml_w_clean_cite
	LEFT JOIN linking.moml_04_cap_case with_links ON cite_in_moml = with_links.cleaner_cite
WHERE with_links."case" IS NOT NULL;