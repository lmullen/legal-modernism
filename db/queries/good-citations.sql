WITH
	clean_citations AS (
		SELECT
			cites.id,
			cites.volume AS volume_found,
			cites.reporter_abbr AS reporter_found,
			cites.page AS page_found,
			clean.reporter_standard,
			cites.volume || ' ' || clean.reporter_standard || ' ' || cites.page AS cite_standard,
			cites.moml_treatise,
			cites.moml_page,
			cites.raw,
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
			cc.volume_found,
			cc.reporter_found,
			cc.reporter_standard,
			cc.page_found,
			cc.cite_standard,
			cc.moml_treatise,
			cc.moml_page,
			cc.raw,
			cc.uk,
			cc.statute,
			cc.junk,
			vols.cap_vol || ' ' || abbr.cap_abbr || ' ' || cc.page_found AS cite_altvol,
			abbr.cap_abbr,
			vols.cap_vol,
			abbr.reporter_title
		FROM
			clean_citations cc
			LEFT JOIN legalhist.reporters_alt_diffvols_abbreviations abbr ON cc.reporter_standard = abbr.alt_abbr
			LEFT JOIN legalhist.reporters_alt_diffvols_volumes vols ON abbr.reporter_title = vols.reporter_title
			AND cc.volume_found = vols.vol
	)
SELECT
	id,
	moml_treatise,
	moml_page,
	raw AS cite_found,
	volume_found AS cite_found_volume,
	reporter_found AS cite_found_reporter,
	page_found AS cite_found_page,
	cite_standard,
	volume_found AS cite_standard_volume,
	reporter_standard AS cite_standard_reporter,
	page_found AS cite_standard_page,
	cite_altvol AS cite_alternative,
	cap_vol AS cite_alternative_volume,
	cap_abbr AS cite_alternative_reporter,
	CASE
		WHEN cap_abbr IS NULL THEN NULL
		ELSE page_found
	END AS cite_alternative_page,
	uk,
	NULL AS case_id_er,
	NULL AS case_id_cap
FROM
	alternative_vols
WHERE
	NOT junk
	AND NOT statute
	AND cite_standard IS NOT NULL;
