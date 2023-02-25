SELECT cc.productlink, cc.psmid, cc.cite_id, cc.moml_treatise, cc.moml_page, cc.volume, cc.reporter_abbr, cc.reporter_cap, cc.page, cc.cleaner_cite, cases.id, cases.name_abbreviation, cases.decision_year, cases.frontend_url FROM 
(SELECT bi.productlink, bi.psmid, 
cites.id AS cite_id, cites.moml_treatise, cites.moml_page, cites.volume, cites.reporter_abbr, cnx.reporter_cap, cites.page,
cites.volume || ' ' || cnx.reporter_cap || ' ' || cites.page AS cleaner_cite, cites.created_at
FROM moml.book_info bi
LEFT JOIN output.moml_citations cites ON bi.psmid = cites.moml_treatise
LEFT JOIN reporters_citation_to_cap cnx ON cites.reporter_abbr = cnx.reporter_found
WHERE bi.webid = 'F0102826781'
) cc
LEFT JOIN (SELECT DISTINCT ON (cite) cite, "case" FROM cap.citations) cap_cites ON cleaner_cite = cap_cites.cite
LEFT JOIN cap.cases cases ON cap_cites.case = cases.id
ORDER BY moml_treatise, moml_page, cc.created_at;