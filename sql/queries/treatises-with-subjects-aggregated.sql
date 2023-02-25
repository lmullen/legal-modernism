SELECT s.psmid, s.subject, bi.year, bc.displaytitle, bi.productlink FROM
(SELECT psmid, array_agg(subject) AS subject
FROM moml.book_subject
GROUP BY psmid
HAVING 'UK' != ALL(array_agg(subject))) s
LEFT JOIN moml.book_info bi ON s.psmid = bi.psmid
LEFT JOIN moml.book_citation bc ON s.psmid = bc.psmid
ORDER BY bi.year;