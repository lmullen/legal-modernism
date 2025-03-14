WITH
	clean_citations AS (
		SELECT
			cites.id,
			cites.volume AS cite_found_volume,
			cites.reporter_abbr AS cite_found_reporter,
			cites.page AS cite_found_page,
			clean.reporter_standard AS cite_standard_reporter,
			cites.volume || ' ' || clean.reporter_standard || ' ' || cites.page AS cite_standard,
			cites.moml_treatise,
			cites.moml_page,
			cites.raw AS cite_found,
			clean.uk,
			clean.statute,
			clean.junk
		FROM
			moml_citations.citations_unlinked cites
			LEFT JOIN legalhist.reporters_citation_to_cap clean ON cites.reporter_abbr = clean.reporter_found
		WHERE
			clean.reporter_standard IS NOT NULL
	),
	alternative_vols AS (
		SELECT
			cc.id,
			cc.cite_found,
			cc.cite_found_volume,
			cc.cite_found_reporter,
			cc.cite_found_page,
			cc.cite_standard_reporter,
			cc.cite_standard,
			cc.moml_treatise,
			cc.moml_page,
			cc.uk,
			cc.statute,
			cc.junk,
			vols.cap_vol AS cite_alternative_volume,
			abbr.cap_abbr AS cite_alternative_reporter,
			cc.cite_found_page AS cite_alternative_page,
			CASE
				WHEN vols.cap_vol IS NOT NULL
				AND abbr.cap_abbr IS NOT NULL THEN vols.cap_vol || ' ' || abbr.cap_abbr || ' ' || cc.cite_found_page
				ELSE NULL
			END AS cite_alternative
		FROM
			clean_citations cc
			LEFT JOIN legalhist.reporters_alt_diffvols_abbreviations abbr ON cc.cite_standard_reporter = abbr.alt_abbr
			LEFT JOIN legalhist.reporters_alt_diffvols_volumes vols ON abbr.reporter_title = vols.reporter_title
			AND cc.cite_found_volume = vols.vol
	)
SELECT
	id,
	moml_treatise,
	moml_page,
	cite_found,
	cite_found_volume,
	cite_found_reporter,
	cite_found_page,
	cite_standard,
	cite_found_volume AS cite_standard_volume,
	cite_standard_reporter,
	cite_found_page AS cite_standard_page,
	cite_alternative,
	cite_alternative_volume,
	cite_alternative_reporter,
	cite_alternative_page,
	uk,
	NULL AS case_id_er,
	NULL AS case_id_cap
FROM
	alternative_vols
WHERE
	cite_standard IS NOT NULL
	AND NOT junk
	AND NOT statute;
