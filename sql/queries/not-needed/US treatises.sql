SELECT subs.psmid, info.year, citation.displaytitle FROM moml.book_subject subs
LEFT JOIN moml.book_info info ON subs.psmid = info.psmid
LEFT JOIN moml.book_citation citation ON subs.psmid = citation.psmid
WHERE subject = 'US'
ORDER BY year, psmid;
