SELECT 
cases_cited.n,
cases_cited.volume,
cases_cited.reporter_standard,
cases_cited.page,
cases_cited.cleaner_cite,
cases_cited.altvol_cite,
cases_cited.cap_link_cite,
cap_cites."case" FROM linking.moml_03_link_cite AS cases_cited
LEFT JOIN (SELECT DISTINCT ON (cite) cite, "case" FROM cap.citations) cap_cites ON cases_cited.cap_link_cite = cap_cites.cite;