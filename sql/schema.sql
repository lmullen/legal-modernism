--
-- PostgreSQL database dump
--

-- Dumped from database version 14.7 (Homebrew)
-- Dumped by pg_dump version 14.7 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cap; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA cap;


--
-- Name: cap_citations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA cap_citations;


--
-- Name: legalhist; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA legalhist;


--
-- Name: linking; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA linking;


--
-- Name: moml; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA moml;


--
-- Name: networks; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA networks;


--
-- Name: output; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA output;


--
-- Name: stats; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA stats;


--
-- Name: to_delete; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA to_delete;


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cases; Type: TABLE; Schema: cap; Owner: -
--

CREATE TABLE cap.cases (
    id bigint NOT NULL,
    name_abbreviation text NOT NULL,
    name text NOT NULL,
    decision_year integer,
    decision_date date,
    first_page integer,
    last_page integer,
    volume text NOT NULL,
    reporter bigint NOT NULL,
    court bigint NOT NULL,
    jurisdiction bigint NOT NULL,
    url text NOT NULL,
    frontend_url text NOT NULL,
    frontend_pdf_url text NOT NULL,
    decision_date_raw text NOT NULL,
    docket_number text,
    first_page_raw text NOT NULL,
    last_page_raw text NOT NULL,
    analysis jsonb NOT NULL,
    provenance jsonb NOT NULL,
    judges jsonb NOT NULL,
    parties jsonb NOT NULL,
    attorneys jsonb NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    imported timestamp with time zone NOT NULL
);


--
-- Name: citations; Type: TABLE; Schema: cap; Owner: -
--

CREATE TABLE cap.citations (
    cite text NOT NULL,
    type text NOT NULL,
    "case" bigint NOT NULL
);


--
-- Name: courts; Type: TABLE; Schema: cap; Owner: -
--

CREATE TABLE cap.courts (
    id bigint NOT NULL,
    name text NOT NULL,
    name_abbreviation text NOT NULL,
    slug text NOT NULL,
    url text NOT NULL
);


--
-- Name: jurisdictions; Type: TABLE; Schema: cap; Owner: -
--

CREATE TABLE cap.jurisdictions (
    id bigint NOT NULL,
    name_long text NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    whitelisted boolean NOT NULL,
    url text NOT NULL
);


--
-- Name: opinions; Type: TABLE; Schema: cap; Owner: -
--

CREATE TABLE cap.opinions (
    "case" bigint NOT NULL,
    type text NOT NULL,
    author jsonb NOT NULL,
    text text NOT NULL
);


--
-- Name: reporters; Type: TABLE; Schema: cap; Owner: -
--

CREATE TABLE cap.reporters (
    id bigint NOT NULL,
    url text,
    full_name text,
    short_name text,
    start_year integer,
    end_year integer,
    frontend_url text
);


--
-- Name: reporters_to_jurisdictions; Type: TABLE; Schema: cap; Owner: -
--

CREATE TABLE cap.reporters_to_jurisdictions (
    reporter integer,
    jurisdiction integer
);


--
-- Name: volumes; Type: TABLE; Schema: cap; Owner: -
--

CREATE TABLE cap.volumes (
    barcode text NOT NULL,
    reporter text,
    volume_number integer,
    url text,
    volume_number_raw text,
    title text,
    publisher text,
    publication_year integer,
    start_year integer,
    end_year integer,
    nominative_volume_number text,
    nominative_name text,
    series_volume_number text,
    reporter_url text,
    pdf_url text,
    frontend_url text
);


--
-- Name: volumes_to_jurisdictions; Type: TABLE; Schema: cap; Owner: -
--

CREATE TABLE cap.volumes_to_jurisdictions (
    barcode text,
    jurisdiction integer
);


--
-- Name: citations; Type: TABLE; Schema: cap_citations; Owner: -
--

CREATE TABLE cap_citations.citations (
    cites_from integer,
    cites_to integer
);


--
-- Name: metadata; Type: TABLE; Schema: cap_citations; Owner: -
--

CREATE TABLE cap_citations.metadata (
    id integer NOT NULL,
    frontend_url text,
    jurisdiction_name text,
    jurisdiction_id integer,
    court_name_abbreviation text,
    court_id integer,
    reporter__short_name text,
    reporter_id integer,
    name_abbreviation text,
    decision_date_original text,
    cites text,
    decision_year integer,
    decision_date date
);


--
-- Name: pagerank; Type: TABLE; Schema: cap_citations; Owner: -
--

CREATE TABLE cap_citations.pagerank (
    id integer,
    raw_score double precision,
    percentile double precision
);


--
-- Name: page_ocrtext; Type: TABLE; Schema: moml; Owner: -
--

CREATE TABLE moml.page_ocrtext (
    pageid character varying(510) NOT NULL,
    psmid character varying(510) NOT NULL,
    ocrtext text
);


--
-- Name: all_page_id; Type: MATERIALIZED VIEW; Schema: legalhist; Owner: -
--

CREATE MATERIALIZED VIEW legalhist.all_page_id AS
 SELECT page_ocrtext.psmid,
    page_ocrtext.pageid
   FROM moml.page_ocrtext
  WITH NO DATA;


--
-- Name: ocr_corrections; Type: TABLE; Schema: legalhist; Owner: -
--

CREATE TABLE legalhist.ocr_corrections (
    mistake text,
    correction text
);


--
-- Name: reporters_alt_diffvols_abbreviations; Type: TABLE; Schema: legalhist; Owner: -
--

CREATE TABLE legalhist.reporters_alt_diffvols_abbreviations (
    cap_abbr text,
    alt_abbr text,
    reporter_title text
);


--
-- Name: TABLE reporters_alt_diffvols_abbreviations; Type: COMMENT; Schema: legalhist; Owner: -
--

COMMENT ON TABLE legalhist.reporters_alt_diffvols_abbreviations IS 'The mapping between abbreviations and CAP reporters and our alternative reporters';


--
-- Name: reporters_alt_diffvols_reporters; Type: TABLE; Schema: legalhist; Owner: -
--

CREATE TABLE legalhist.reporters_alt_diffvols_reporters (
    reporter_title text NOT NULL,
    level text,
    jurisdiction text,
    single_vol boolean NOT NULL,
    year_start integer,
    year_end integer
);


--
-- Name: TABLE reporters_alt_diffvols_reporters; Type: COMMENT; Schema: legalhist; Owner: -
--

COMMENT ON TABLE legalhist.reporters_alt_diffvols_reporters IS 'Alternative reporters to reporters in CAP, where the volume numbers are different from CAP';


--
-- Name: reporters_alt_diffvols_volumes; Type: TABLE; Schema: legalhist; Owner: -
--

CREATE TABLE legalhist.reporters_alt_diffvols_volumes (
    reporter_title text,
    vol integer,
    cap_vol integer,
    cap_reporter text NOT NULL
);


--
-- Name: TABLE reporters_alt_diffvols_volumes; Type: COMMENT; Schema: legalhist; Owner: -
--

COMMENT ON TABLE legalhist.reporters_alt_diffvols_volumes IS 'The mapping between volumes from our alternative reporters to the CAP reporter volume numbers';


--
-- Name: reporters_alt_samevols_abbreviations; Type: TABLE; Schema: legalhist; Owner: -
--

CREATE TABLE legalhist.reporters_alt_samevols_abbreviations (
    cap_abbr text NOT NULL,
    alt_abbr text NOT NULL
);


--
-- Name: TABLE reporters_alt_samevols_abbreviations; Type: COMMENT; Schema: legalhist; Owner: -
--

COMMENT ON TABLE legalhist.reporters_alt_samevols_abbreviations IS 'Alternative reporters to reporters in CAP, where the volume numbers are the same as CAP but abbreviations/names are different';


--
-- Name: reporters_citation_to_cap; Type: TABLE; Schema: legalhist; Owner: -
--

CREATE TABLE legalhist.reporters_citation_to_cap (
    reporter_found text NOT NULL,
    reporter_standard text,
    reporter_cap text,
    statute boolean NOT NULL,
    uk boolean NOT NULL,
    junk boolean NOT NULL,
    cap_different boolean
);


--
-- Name: reporters_single_volume_abbr; Type: VIEW; Schema: legalhist; Owner: -
--

CREATE VIEW legalhist.reporters_single_volume_abbr AS
 SELECT a.alt_abbr,
    a.cap_abbr,
    r.reporter_title
   FROM (legalhist.reporters_alt_diffvols_reporters r
     LEFT JOIN legalhist.reporters_alt_diffvols_abbreviations a ON ((r.reporter_title = a.reporter_title)))
  WHERE (r.single_vol = true);


--
-- Name: VIEW reporters_single_volume_abbr; Type: COMMENT; Schema: legalhist; Owner: -
--

COMMENT ON VIEW legalhist.reporters_single_volume_abbr IS 'Abbreviations for single volume reporters';


--
-- Name: moml_citations; Type: TABLE; Schema: output; Owner: -
--

CREATE TABLE output.moml_citations (
    id uuid NOT NULL,
    moml_treatise text NOT NULL,
    moml_page text NOT NULL,
    raw text NOT NULL,
    volume integer NOT NULL,
    reporter_abbr text NOT NULL,
    page integer NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: moml_01_clean_cites_agg; Type: VIEW; Schema: linking; Owner: -
--

CREATE VIEW linking.moml_01_clean_cites_agg AS
 SELECT count(*) AS n,
    cites.volume,
    clean.reporter_standard,
    cites.page,
    ((((cites.volume || ' '::text) || clean.reporter_standard) || ' '::text) || cites.page) AS cleaner_cite
   FROM (output.moml_citations cites
     LEFT JOIN legalhist.reporters_citation_to_cap clean ON ((cites.reporter_abbr = clean.reporter_found)))
  WHERE (clean.reporter_cap IS NOT NULL)
  GROUP BY cites.volume, clean.reporter_standard, cites.page
 HAVING (count(*) >= 10);


--
-- Name: VIEW moml_01_clean_cites_agg; Type: COMMENT; Schema: linking; Owner: -
--

COMMENT ON VIEW linking.moml_01_clean_cites_agg IS 'Aggregated cites in MOML';


--
-- Name: moml_02_nominate_vols; Type: VIEW; Schema: linking; Owner: -
--

CREATE VIEW linking.moml_02_nominate_vols AS
 SELECT cites.n,
    cites.volume,
    cites.reporter_standard,
    cites.page,
    cites.cleaner_cite,
    ((((vols.cap_vol || ' '::text) || abbr.cap_abbr) || ' '::text) || cites.page) AS altvol_cite
   FROM ((linking.moml_01_clean_cites_agg cites
     LEFT JOIN legalhist.reporters_alt_diffvols_abbreviations abbr ON ((cites.reporter_standard = abbr.alt_abbr)))
     LEFT JOIN legalhist.reporters_alt_diffvols_volumes vols ON (((abbr.reporter_title = vols.reporter_title) AND (cites.volume = vols.vol))));


--
-- Name: moml_03_link_cite; Type: VIEW; Schema: linking; Owner: -
--

CREATE VIEW linking.moml_03_link_cite AS
 SELECT moml_02_nominate_vols.n,
    moml_02_nominate_vols.volume,
    moml_02_nominate_vols.reporter_standard,
    moml_02_nominate_vols.page,
    moml_02_nominate_vols.cleaner_cite,
    moml_02_nominate_vols.altvol_cite,
    COALESCE(moml_02_nominate_vols.altvol_cite, moml_02_nominate_vols.cleaner_cite) AS cap_link_cite
   FROM linking.moml_02_nominate_vols;


--
-- Name: moml_04_cap_case; Type: VIEW; Schema: linking; Owner: -
--

CREATE VIEW linking.moml_04_cap_case AS
 SELECT cases_cited.n,
    cases_cited.volume,
    cases_cited.reporter_standard,
    cases_cited.page,
    cases_cited.cleaner_cite,
    cases_cited.altvol_cite,
    cases_cited.cap_link_cite,
    cap_cites."case"
   FROM (linking.moml_03_link_cite cases_cited
     LEFT JOIN ( SELECT DISTINCT ON (citations.cite) citations.cite,
            citations."case"
           FROM cap.citations) cap_cites ON ((cases_cited.cap_link_cite = cap_cites.cite)));


--
-- Name: moml_05_moml_to_cap; Type: MATERIALIZED VIEW; Schema: linking; Owner: -
--

CREATE MATERIALIZED VIEW linking.moml_05_moml_to_cap AS
 SELECT moml_w_clean_cite.id,
    moml_w_clean_cite.moml_treatise,
    moml_w_clean_cite.moml_page,
    moml_w_clean_cite.cite_in_moml,
    with_links.cap_link_cite,
    with_links."case"
   FROM (( SELECT cites.id,
            cites.moml_treatise,
            cites.moml_page,
            ((((cites.volume || ' '::text) || clean.reporter_standard) || ' '::text) || cites.page) AS cite_in_moml
           FROM (output.moml_citations cites
             LEFT JOIN legalhist.reporters_citation_to_cap clean ON ((cites.reporter_abbr = clean.reporter_found)))) moml_w_clean_cite
     LEFT JOIN linking.moml_04_cap_case with_links ON ((moml_w_clean_cite.cite_in_moml = with_links.cleaner_cite)))
  WHERE (with_links."case" IS NOT NULL)
  WITH NO DATA;


--
-- Name: moml_06_treatise_to_case; Type: VIEW; Schema: linking; Owner: -
--

CREATE VIEW linking.moml_06_treatise_to_case AS
 SELECT moml_05_moml_to_cap.moml_treatise,
    moml_05_moml_to_cap."case",
    count(*) AS n
   FROM linking.moml_05_moml_to_cap
  GROUP BY moml_05_moml_to_cap.moml_treatise, moml_05_moml_to_cap."case";


--
-- Name: book_citation; Type: TABLE; Schema: moml; Owner: -
--

CREATE TABLE moml.book_citation (
    psmid character varying(510),
    author_role character varying(510),
    author_composed character varying(510),
    author_first character varying(510),
    author_middle character varying(510),
    author_last character varying(510),
    author_birthdate character varying(510),
    author_deathdate character varying(510),
    fulltitle text,
    displaytitle text,
    varianttitle text,
    edition character varying(510),
    editionstatement character varying(510),
    currentvolume character varying(510),
    volume character varying(510),
    totalvolume character varying(510),
    imprintfull character varying(510),
    imprintpublisher character varying(510),
    book_collation character varying(510),
    publicationplacecity character varying(510),
    publicationplacecomposed character varying(510),
    totalpages character varying(510)
);


--
-- Name: book_info; Type: TABLE; Schema: moml; Owner: -
--

CREATE TABLE moml.book_info (
    psmid character varying(510) NOT NULL,
    contenttype character varying(510),
    id character varying(510),
    faid character varying(510),
    colid character varying(510),
    ocr character varying(510),
    assetid character varying(510),
    assetidetoc character varying(510),
    dvicollectionid character varying(510),
    bibliographicid character varying(510),
    bibliographicid_type character varying(510),
    unit character varying(510),
    ficherange character varying(510),
    mcode character varying(510),
    pubdate_year character varying(510),
    pubdate_composed character varying(510),
    pubdate_pubdatestart character varying(510),
    releasedate character varying(510),
    sourcelibrary_libraryname character varying(510),
    sourcelibrary_librarylocation character varying(510),
    language character varying(510),
    language_ocr character varying(510),
    language_primary character varying(510),
    documenttype character varying(510),
    notes character varying(510),
    categorycode character varying(510),
    categorycode_source character varying(510),
    productlink text,
    webid text,
    year integer
);


--
-- Name: book_locsubjecthead; Type: TABLE; Schema: moml; Owner: -
--

CREATE TABLE moml.book_locsubjecthead (
    psmid character varying(510),
    type character varying(510),
    subfield character varying(510),
    locsubject character varying(510)
);


--
-- Name: book_subject; Type: TABLE; Schema: moml; Owner: -
--

CREATE TABLE moml.book_subject (
    psmid character varying(510),
    subject character varying(510),
    source character varying(510)
);


--
-- Name: book_volumeset; Type: TABLE; Schema: moml; Owner: -
--

CREATE TABLE moml.book_volumeset (
    psmid character varying(510),
    volumeid character varying(510),
    assetid character varying(510),
    filmedvolume character varying(510)
);


--
-- Name: legal_treatises_metadata; Type: TABLE; Schema: moml; Owner: -
--

CREATE TABLE moml.legal_treatises_metadata (
    psmid character varying(510) NOT NULL,
    author_by_line text,
    title text,
    edition text,
    current_volume character varying(510),
    imprint character varying(510),
    book_collation character varying(510),
    pages character varying(510)
);


--
-- Name: page; Type: TABLE; Schema: moml; Owner: -
--

CREATE TABLE moml.page (
    pageid character varying(510) NOT NULL,
    psmid character varying(510) NOT NULL,
    type character varying(510),
    firstpage character varying(510),
    assetid character varying(510),
    ocrlanguage character varying(510),
    sourcepage character varying(510),
    ocr character varying(510),
    imagelink_pageindicator character varying(510),
    imagelink_width character varying(510),
    imagelink_height character varying(510),
    imagelink_type character varying(510),
    imagelink_colorimage character varying(510),
    imagelink character varying(510)
);


--
-- Name: page_content; Type: TABLE; Schema: moml; Owner: -
--

CREATE TABLE moml.page_content (
    pageid character varying(510),
    psmid character varying(510),
    sectionheader_type character varying(510),
    sectionheader character varying(510)
);


--
-- Name: treatises; Type: VIEW; Schema: moml; Owner: -
--

CREATE VIEW moml.treatises AS
 SELECT bi.bibliographicid,
    min(bi.year) AS year,
    (array_agg(DISTINCT bc.displaytitle))[1] AS title,
        CASE
            WHEN (max((bc.currentvolume)::integer) = 0) THEN 1
            ELSE max((bc.currentvolume)::integer)
        END AS vols,
    array_agg(DISTINCT bs.subject) AS subjects,
    array_agg(DISTINCT bi.psmid) AS psmid
   FROM ((moml.book_info bi
     LEFT JOIN moml.book_citation bc ON (((bi.psmid)::text = (bc.psmid)::text)))
     LEFT JOIN moml.book_subject bs ON (((bi.psmid)::text = (bs.psmid)::text)))
  GROUP BY bi.bibliographicid
  ORDER BY (min(bi.year)), (array_agg(DISTINCT bc.displaytitle))[1];


--
-- Name: VIEW treatises; Type: COMMENT; Schema: moml; Owner: -
--

COMMENT ON VIEW moml.treatises IS 'Treatises aggregated from their individual volumes';


--
-- Name: us_treatises; Type: VIEW; Schema: moml; Owner: -
--

CREATE VIEW moml.us_treatises AS
 SELECT treatises.bibliographicid,
    treatises.year,
    treatises.title,
    treatises.vols,
    treatises.subjects,
    treatises.psmid
   FROM moml.treatises
  WHERE (('UK'::text <> ALL ((treatises.subjects)::text[])) AND ('Biography'::text <> ALL ((treatises.subjects)::text[])) AND ('Collected Essays'::text <> ALL ((treatises.subjects)::text[])) AND ('Trials'::text <> ALL ((treatises.subjects)::text[])) AND (NOT (treatises.title ~* '\Woration\W'::text)) AND (NOT (treatises.title ~* '\Wremarks of\W'::text)) AND (NOT (treatises.title ~* '\Waddress\W'::text)));


--
-- Name: treatise_bibliocouple; Type: MATERIALIZED VIEW; Schema: networks; Owner: -
--

CREATE MATERIALIZED VIEW networks.treatise_bibliocouple AS
 WITH ut2c AS (
         SELECT DISTINCT t2c.bibliographicid,
            t2c."case"
           FROM ( SELECT t.bibliographicid,
                    c.moml_treatise AS psmid,
                    c."case"
                   FROM ((linking.moml_06_treatise_to_case c
                     LEFT JOIN moml.book_info bi ON ((c.moml_treatise = (bi.psmid)::text)))
                     LEFT JOIN moml.us_treatises t ON (((bi.bibliographicid)::text = (t.bibliographicid)::text)))) t2c
        )
 SELECT cites1.bibliographicid AS t1,
    cites2.bibliographicid AS t2,
    count(*) AS n
   FROM (ut2c cites1
     LEFT JOIN ut2c cites2 ON ((cites1."case" = cites2."case")))
  WHERE ((cites1.bibliographicid)::text <> (cites2.bibliographicid)::text)
  GROUP BY cites1.bibliographicid, cites2.bibliographicid
  WITH NO DATA;


--
-- Name: top_reporters; Type: MATERIALIZED VIEW; Schema: output; Owner: -
--

CREATE MATERIALIZED VIEW output.top_reporters AS
 SELECT moml_citations.reporter_abbr,
    count(*) AS n
   FROM output.moml_citations
  GROUP BY moml_citations.reporter_abbr
  ORDER BY (count(*)) DESC
  WITH NO DATA;


--
-- Name: top_reporters_not_whitelisted; Type: VIEW; Schema: output; Owner: -
--

CREATE VIEW output.top_reporters_not_whitelisted AS
 SELECT tr.reporter_abbr AS reporter_found,
    wl.reporter_standard,
    wl.reporter_cap,
    wl.statute,
    wl.uk,
    wl.junk,
    tr.n
   FROM (output.top_reporters tr
     LEFT JOIN legalhist.reporters_citation_to_cap wl ON ((tr.reporter_abbr = wl.reporter_found)))
  WHERE (wl.reporter_found IS NULL)
  ORDER BY tr.n DESC;


--
-- Name: cap_to_cap_citations; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.cap_to_cap_citations AS
 SELECT c.cites_from AS from_id,
    f.cites AS from_case_name,
    f.jurisdiction_name AS from_jurisdiction,
    f.jurisdiction_id AS from_jurisdiction_id,
    f.decision_year AS from_year,
    f.court_name_abbreviation AS from_court,
    f.court_id AS from_court_id,
    c.cites_to AS to_id,
    t.cites AS to_case_name,
    t.jurisdiction_name AS to_jurisdiction,
    t.jurisdiction_id AS to_jurisdiction_id,
    t.decision_year AS to_year,
    t.court_name_abbreviation AS to_court,
    t.court_id AS to_court_id
   FROM ((cap_citations.citations c
     LEFT JOIN cap_citations.metadata f ON ((c.cites_from = f.id)))
     LEFT JOIN cap_citations.metadata t ON ((c.cites_to = t.id)))
  WITH NO DATA;


--
-- Name: database_size; Type: VIEW; Schema: stats; Owner: -
--

CREATE VIEW stats.database_size AS
 SELECT pg_size_pretty(pg_database_size('lmullen'::name)) AS pg_size_pretty;


--
-- Name: table_sizes; Type: VIEW; Schema: stats; Owner: -
--

CREATE VIEW stats.table_sizes AS
 SELECT (n.nspname)::text AS namespace,
    (c.relname)::text AS tablename,
    c.relkind AS type,
    pg_size_pretty(pg_total_relation_size((c.oid)::regclass)) AS total_size,
    pg_total_relation_size((c.oid)::regclass) AS size
   FROM (pg_class c
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE ((n.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])) AND (c.relkind <> 'i'::"char") AND (n.nspname !~ '^pg_toast'::text))
  ORDER BY (pg_total_relation_size((c.oid)::regclass)) DESC;


--
-- Name: reporters_citation_to_cap_bak; Type: TABLE; Schema: to_delete; Owner: -
--

CREATE TABLE to_delete.reporters_citation_to_cap_bak (
    reporter_found text,
    reporter_standard text,
    reporter_cap text,
    statute boolean,
    uk boolean,
    junk boolean
);


--
-- Name: cases cases_pkey; Type: CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (id);


--
-- Name: courts courts_pkey; Type: CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.courts
    ADD CONSTRAINT courts_pkey PRIMARY KEY (id);


--
-- Name: jurisdictions jurisdictions_pkey; Type: CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.jurisdictions
    ADD CONSTRAINT jurisdictions_pkey PRIMARY KEY (id);


--
-- Name: reporters reporters_pkey; Type: CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.reporters
    ADD CONSTRAINT reporters_pkey PRIMARY KEY (id);


--
-- Name: volumes volumes_pkey; Type: CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.volumes
    ADD CONSTRAINT volumes_pkey PRIMARY KEY (barcode);


--
-- Name: metadata metadata_pkey1; Type: CONSTRAINT; Schema: cap_citations; Owner: -
--

ALTER TABLE ONLY cap_citations.metadata
    ADD CONSTRAINT metadata_pkey1 PRIMARY KEY (id);


--
-- Name: ocr_corrections ocr_corrections_unique; Type: CONSTRAINT; Schema: legalhist; Owner: -
--

ALTER TABLE ONLY legalhist.ocr_corrections
    ADD CONSTRAINT ocr_corrections_unique UNIQUE (mistake, correction);


--
-- Name: reporters_alt_samevols_abbreviations reporter_alt_abbr_unique; Type: CONSTRAINT; Schema: legalhist; Owner: -
--

ALTER TABLE ONLY legalhist.reporters_alt_samevols_abbreviations
    ADD CONSTRAINT reporter_alt_abbr_unique UNIQUE (cap_abbr, alt_abbr);


--
-- Name: reporters_alt_diffvols_abbreviations reporter_alt_diff_vols_abbr_unique; Type: CONSTRAINT; Schema: legalhist; Owner: -
--

ALTER TABLE ONLY legalhist.reporters_alt_diffvols_abbreviations
    ADD CONSTRAINT reporter_alt_diff_vols_abbr_unique UNIQUE (cap_abbr, alt_abbr);


--
-- Name: reporters_alt_diffvols_reporters reporters_alt_diff_vols_pkey; Type: CONSTRAINT; Schema: legalhist; Owner: -
--

ALTER TABLE ONLY legalhist.reporters_alt_diffvols_reporters
    ADD CONSTRAINT reporters_alt_diff_vols_pkey PRIMARY KEY (reporter_title);


--
-- Name: reporters_citation_to_cap reporters_citation_to_cap_pkey; Type: CONSTRAINT; Schema: legalhist; Owner: -
--

ALTER TABLE ONLY legalhist.reporters_citation_to_cap
    ADD CONSTRAINT reporters_citation_to_cap_pkey PRIMARY KEY (reporter_found);


--
-- Name: book_info book_info_pkey; Type: CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.book_info
    ADD CONSTRAINT book_info_pkey PRIMARY KEY (psmid);


--
-- Name: legal_treatises_metadata legal_treatises_metadata_pkey; Type: CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.legal_treatises_metadata
    ADD CONSTRAINT legal_treatises_metadata_pkey PRIMARY KEY (psmid);


--
-- Name: page_ocrtext moml_page_ocrtext_pk; Type: CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.page_ocrtext
    ADD CONSTRAINT moml_page_ocrtext_pk PRIMARY KEY (psmid, pageid);


--
-- Name: page page_pkey; Type: CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.page
    ADD CONSTRAINT page_pkey PRIMARY KEY (pageid, psmid);


--
-- Name: moml_citations moml_citations_id_key; Type: CONSTRAINT; Schema: output; Owner: -
--

ALTER TABLE ONLY output.moml_citations
    ADD CONSTRAINT moml_citations_id_key UNIQUE (id);


--
-- Name: moml_citations moml_citations_pkey; Type: CONSTRAINT; Schema: output; Owner: -
--

ALTER TABLE ONLY output.moml_citations
    ADD CONSTRAINT moml_citations_pkey PRIMARY KEY (moml_treatise, moml_page, volume, reporter_abbr, page);


--
-- Name: cap_case_first_page_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX cap_case_first_page_idx ON cap.cases USING btree (first_page);


--
-- Name: cap_case_jurisdiction_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX cap_case_jurisdiction_idx ON cap.cases USING btree (jurisdiction);


--
-- Name: cap_case_last_page_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX cap_case_last_page_idx ON cap.cases USING btree (last_page);


--
-- Name: cap_case_reporter_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX cap_case_reporter_idx ON cap.cases USING btree (reporter);


--
-- Name: cap_case_volume_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX cap_case_volume_idx ON cap.cases USING btree (volume);


--
-- Name: cap_case_year_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX cap_case_year_idx ON cap.cases USING btree (decision_year);


--
-- Name: cap_citations_case_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX cap_citations_case_idx ON cap.citations USING btree ("case");


--
-- Name: cap_citations_cite_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX cap_citations_cite_idx ON cap.citations USING btree (cite);


--
-- Name: cap_reporters_to_jurisdictions_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE UNIQUE INDEX cap_reporters_to_jurisdictions_idx ON cap.reporters_to_jurisdictions USING btree (reporter, jurisdiction);


--
-- Name: cap_volumes_to_jurisdictions_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE UNIQUE INDEX cap_volumes_to_jurisdictions_idx ON cap.volumes_to_jurisdictions USING btree (barcode, jurisdiction);


--
-- Name: reporters_short_name_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX reporters_short_name_idx ON cap.reporters USING btree (short_name);


--
-- Name: volumes_volume_number_idx; Type: INDEX; Schema: cap; Owner: -
--

CREATE INDEX volumes_volume_number_idx ON cap.volumes USING btree (volume_number);


--
-- Name: metadata_decision_year_idx; Type: INDEX; Schema: cap_citations; Owner: -
--

CREATE INDEX metadata_decision_year_idx ON cap_citations.metadata USING btree (decision_year);


--
-- Name: metadata_jurisdiction__name_idx; Type: INDEX; Schema: cap_citations; Owner: -
--

CREATE INDEX metadata_jurisdiction__name_idx ON cap_citations.metadata USING btree (jurisdiction_name);


--
-- Name: reporter_alt_same_vols_alt_abbr_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporter_alt_same_vols_alt_abbr_idx ON legalhist.reporters_alt_samevols_abbreviations USING btree (alt_abbr);


--
-- Name: reporter_alt_same_vols_cap_abbr_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporter_alt_same_vols_cap_abbr_idx ON legalhist.reporters_alt_samevols_abbreviations USING btree (cap_abbr);


--
-- Name: reporters_alt_diff_vols_single_vol_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporters_alt_diff_vols_single_vol_idx ON legalhist.reporters_alt_diffvols_reporters USING btree (single_vol);


--
-- Name: reporters_alt_diffvols_abbreviations_alt_abbr_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporters_alt_diffvols_abbreviations_alt_abbr_idx ON legalhist.reporters_alt_diffvols_abbreviations USING btree (alt_abbr);


--
-- Name: reporters_alt_diffvols_abbreviations_cap_abbr_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporters_alt_diffvols_abbreviations_cap_abbr_idx ON legalhist.reporters_alt_diffvols_abbreviations USING btree (cap_abbr);


--
-- Name: reporters_alt_diffvols_abbreviations_reporter_title_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporters_alt_diffvols_abbreviations_reporter_title_idx ON legalhist.reporters_alt_diffvols_abbreviations USING btree (reporter_title);


--
-- Name: reporters_alt_diffvols_volumes_cap_reporter_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporters_alt_diffvols_volumes_cap_reporter_idx ON legalhist.reporters_alt_diffvols_volumes USING btree (cap_reporter);


--
-- Name: reporters_alt_diffvols_volumes_vol_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporters_alt_diffvols_volumes_vol_idx ON legalhist.reporters_alt_diffvols_volumes USING btree (vol);


--
-- Name: reporters_citation_to_cap_reporter_cap_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporters_citation_to_cap_reporter_cap_idx ON legalhist.reporters_citation_to_cap USING btree (reporter_cap);


--
-- Name: reporters_citation_to_cap_reporter_standard_idx; Type: INDEX; Schema: legalhist; Owner: -
--

CREATE INDEX reporters_citation_to_cap_reporter_standard_idx ON legalhist.reporters_citation_to_cap USING btree (reporter_standard);


--
-- Name: moml_05_moml_to_cap_case_idx; Type: INDEX; Schema: linking; Owner: -
--

CREATE INDEX moml_05_moml_to_cap_case_idx ON linking.moml_05_moml_to_cap USING btree ("case");


--
-- Name: moml_05_moml_to_cap_moml_treatise_idx; Type: INDEX; Schema: linking; Owner: -
--

CREATE INDEX moml_05_moml_to_cap_moml_treatise_idx ON linking.moml_05_moml_to_cap USING btree (moml_treatise);


--
-- Name: moml_05_moml_to_cap_moml_treatise_moml_page_idx; Type: INDEX; Schema: linking; Owner: -
--

CREATE INDEX moml_05_moml_to_cap_moml_treatise_moml_page_idx ON linking.moml_05_moml_to_cap USING btree (moml_treatise, moml_page);


--
-- Name: book_info_webid_idx; Type: INDEX; Schema: moml; Owner: -
--

CREATE INDEX book_info_webid_idx ON moml.book_info USING btree (webid);


--
-- Name: book_subject_subject_idx; Type: INDEX; Schema: moml; Owner: -
--

CREATE INDEX book_subject_subject_idx ON moml.book_subject USING btree (subject);


--
-- Name: cases cap_cases_court_fk; Type: FK CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cap_cases_court_fk FOREIGN KEY (court) REFERENCES cap.courts(id);


--
-- Name: cases cap_cases_jurisdiction_fk; Type: FK CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cap_cases_jurisdiction_fk FOREIGN KEY (jurisdiction) REFERENCES cap.jurisdictions(id);


--
-- Name: cases cap_cases_reporter_fk; Type: FK CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cap_cases_reporter_fk FOREIGN KEY (reporter) REFERENCES cap.reporters(id);


--
-- Name: cases cap_cases_volume_fk; Type: FK CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cap_cases_volume_fk FOREIGN KEY (volume) REFERENCES cap.volumes(barcode);


--
-- Name: citations cap_citations_case_fk; Type: FK CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.citations
    ADD CONSTRAINT cap_citations_case_fk FOREIGN KEY ("case") REFERENCES cap.cases(id);


--
-- Name: opinions cap_opinions_case_fk; Type: FK CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.opinions
    ADD CONSTRAINT cap_opinions_case_fk FOREIGN KEY ("case") REFERENCES cap.cases(id);


--
-- Name: reporters_to_jurisdictions reporters_to_jurisdictions_reporter_fkey; Type: FK CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.reporters_to_jurisdictions
    ADD CONSTRAINT reporters_to_jurisdictions_reporter_fkey FOREIGN KEY (reporter) REFERENCES cap.reporters(id);


--
-- Name: volumes_to_jurisdictions volumes_to_jurisdictions_barcode_fkey; Type: FK CONSTRAINT; Schema: cap; Owner: -
--

ALTER TABLE ONLY cap.volumes_to_jurisdictions
    ADD CONSTRAINT volumes_to_jurisdictions_barcode_fkey FOREIGN KEY (barcode) REFERENCES cap.volumes(barcode);


--
-- Name: citations citations_cites_from_fkey; Type: FK CONSTRAINT; Schema: cap_citations; Owner: -
--

ALTER TABLE ONLY cap_citations.citations
    ADD CONSTRAINT citations_cites_from_fkey FOREIGN KEY (cites_from) REFERENCES cap_citations.metadata(id);


--
-- Name: citations citations_cites_to_fkey; Type: FK CONSTRAINT; Schema: cap_citations; Owner: -
--

ALTER TABLE ONLY cap_citations.citations
    ADD CONSTRAINT citations_cites_to_fkey FOREIGN KEY (cites_to) REFERENCES cap_citations.metadata(id);


--
-- Name: pagerank pagerank_id_fkey; Type: FK CONSTRAINT; Schema: cap_citations; Owner: -
--

ALTER TABLE ONLY cap_citations.pagerank
    ADD CONSTRAINT pagerank_id_fkey FOREIGN KEY (id) REFERENCES cap_citations.metadata(id);


--
-- Name: reporters_alt_diffvols_abbreviations reporters_alt_diffvols_abbreviations_reporter_title_fkey; Type: FK CONSTRAINT; Schema: legalhist; Owner: -
--

ALTER TABLE ONLY legalhist.reporters_alt_diffvols_abbreviations
    ADD CONSTRAINT reporters_alt_diffvols_abbreviations_reporter_title_fkey FOREIGN KEY (reporter_title) REFERENCES legalhist.reporters_alt_diffvols_reporters(reporter_title);


--
-- Name: reporters_alt_diffvols_volumes reporters_alt_diffvols_volumes_reporter_title_fkey; Type: FK CONSTRAINT; Schema: legalhist; Owner: -
--

ALTER TABLE ONLY legalhist.reporters_alt_diffvols_volumes
    ADD CONSTRAINT reporters_alt_diffvols_volumes_reporter_title_fkey FOREIGN KEY (reporter_title) REFERENCES legalhist.reporters_alt_diffvols_reporters(reporter_title);


--
-- Name: book_citation book_citation_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.book_citation
    ADD CONSTRAINT book_citation_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: book_locsubjecthead book_locsubjecthead_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.book_locsubjecthead
    ADD CONSTRAINT book_locsubjecthead_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: book_subject book_subject_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.book_subject
    ADD CONSTRAINT book_subject_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: book_volumeset book_volumeset_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.book_volumeset
    ADD CONSTRAINT book_volumeset_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: page_content page_content_pageid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.page_content
    ADD CONSTRAINT page_content_pageid_fkey FOREIGN KEY (pageid, psmid) REFERENCES moml.page(pageid, psmid);


--
-- Name: page_ocrtext page_ocrtext_pageid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.page_ocrtext
    ADD CONSTRAINT page_ocrtext_pageid_fkey FOREIGN KEY (pageid, psmid) REFERENCES moml.page(pageid, psmid);


--
-- Name: page_ocrtext page_ocrtext_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.page_ocrtext
    ADD CONSTRAINT page_ocrtext_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.legal_treatises_metadata(psmid);


--
-- Name: page page_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: -
--

ALTER TABLE ONLY moml.page
    ADD CONSTRAINT page_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- PostgreSQL database dump complete
--

