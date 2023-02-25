WITH ut2c AS (
	SELECT DISTINCT
		bibliographicid,
		"case"
	FROM (
		SELECT
			t.bibliographicid,
			c.moml_treatise AS psmid,
			c.case
		FROM
			linking.moml_06_treatise_to_case c
		LEFT JOIN moml.book_info bi ON c.moml_treatise = bi.psmid
		LEFT JOIN moml.us_treatises t ON bi.bibliographicid = t.bibliographicid) t2c
)
SELECT
	cites1.bibliographicid AS t1,
	cites2.bibliographicid AS t2,
	count(*) as n
FROM
	ut2c cites1
	LEFT JOIN ut2c cites2 ON cites1.case = cites2.case
WHERE cites1.bibliographicid != cites2.bibliographicid
GROUP BY cites1.bibliographicid, cites2.bibliographicid; 