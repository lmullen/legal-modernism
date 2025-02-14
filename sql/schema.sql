--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2 (Debian 17.2-1.pgdg120+1)
-- Dumped by pg_dump version 17.2 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cap; Type: SCHEMA; Schema: -; Owner: law_admin
--

CREATE SCHEMA cap;


ALTER SCHEMA cap OWNER TO law_admin;

--
-- Name: cap_citations; Type: SCHEMA; Schema: -; Owner: law_admin
--

CREATE SCHEMA cap_citations;


ALTER SCHEMA cap_citations OWNER TO law_admin;

--
-- Name: legalhist; Type: SCHEMA; Schema: -; Owner: law_admin
--

CREATE SCHEMA legalhist;


ALTER SCHEMA legalhist OWNER TO law_admin;

--
-- Name: moml; Type: SCHEMA; Schema: -; Owner: law_admin
--

CREATE SCHEMA moml;


ALTER SCHEMA moml OWNER TO law_admin;

--
-- Name: moml_citations; Type: SCHEMA; Schema: -; Owner: law_admin
--

CREATE SCHEMA moml_citations;


ALTER SCHEMA moml_citations OWNER TO law_admin;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: law_admin
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO law_admin;

--
-- Name: stats; Type: SCHEMA; Schema: -; Owner: law_admin
--

CREATE SCHEMA stats;


ALTER SCHEMA stats OWNER TO law_admin;

--
-- Name: sys_admin; Type: SCHEMA; Schema: -; Owner: law_admin
--

CREATE SCHEMA sys_admin;


ALTER SCHEMA sys_admin OWNER TO law_admin;

--
-- Name: textbooks; Type: SCHEMA; Schema: -; Owner: law_admin
--

CREATE SCHEMA textbooks;


ALTER SCHEMA textbooks OWNER TO law_admin;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: chnm_authorize(text, text, text, text, boolean); Type: PROCEDURE; Schema: sys_admin; Owner: law_admin
--

CREATE PROCEDURE sys_admin.chnm_authorize(IN v_flag text, IN v_schema_privs text, IN v_schema_table_privs text, IN v_role text, IN v_dryrun boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec record;
    cnt int;
BEGIN
    if v_dryrun = TRUE then
	raise notice 'dry run';
    end if;  
    cnt := 0;
    for rec in (
        SELECT distinct(table_schema)
        FROM information_schema.tables
        WHERE table_schema NOT IN ('pg_catalog', 'information_schema', 'sys_admin')
    )
    loop
        cnt := cnt + 1;
	raise notice '';
	raise notice 'SCHEMA: %', rec.table_schema;
	if v_flag = 'grant' then
	    raise notice 'GRANT % ON SCHEMA % TO %;', v_schema_privs, rec.table_schema, v_role;
	    raise notice 'GRANT % ON ALL TABLES IN SCHEMA % TO %;', v_schema_table_privs, rec.table_schema, v_role;
	    if v_dryrun = FALSE then
	        execute format ('GRANT %s ON SCHEMA %I TO %I;', v_schema_privs, rec.table_schema, v_role);
	        execute format ('GRANT %s ON ALL TABLES IN SCHEMA %I TO %I;', v_schema_table_privs, rec.table_schema, v_role); 	
	    end if;  
	end if;
        if v_flag = 'revoke' then
	    raise notice 'REVOKE % ON SCHEMA % FROM %;', v_schema_privs, rec.table_schema, v_role;
	    raise notice 'REVOKE % ON ALL TABLES IN SCHEMA % FROM %;', v_schema_table_privs, rec.table_schema, v_role;
	    if v_dryrun = FALSE then
	        execute format ('REVOKE %s ON SCHEMA %I FROM %I;', v_schema_privs, rec.table_schema, v_role);
	        execute format ('REVOKE %s ON ALL TABLES IN SCHEMA %I FROM %I;', v_schema_table_privs, rec.table_schema, v_role);  	
	    end if;  
	end if;
    end loop;
    raise notice 'Schema Count: %', cnt;
	
    raise notice '';
    raise notice '###############################################################';
    raise notice '';

    raise notice '';
    raise notice '######################';
    raise notice '###     TABLES     ###';
    raise notice '######################';
    raise notice '';	
   
    cnt := 0;
    for rec in (
        SELECT table_schema, table_name
        FROM information_schema.tables
        WHERE table_schema NOT IN ('pg_catalog', 'information_schema', 'sys_admin')
    )
    loop
        cnt := cnt + 1;
        raise notice '%.%', rec.table_schema, rec.table_name;
    end loop;
    raise notice 'Tables Count: %', cnt;
	
    raise notice '';
    raise notice '#####################';
    raise notice '###     VIEWS     ###';
    raise notice '#####################';
    raise notice '';	
	
    cnt := 0;
    for rec in (
        SELECT table_schema, table_name
        FROM information_schema.views
        WHERE table_schema NOT IN ('pg_catalog', 'information_schema', 'sys_admin')
    )
    loop
        cnt := cnt + 1;
        raise notice '%.%', rec.table_schema, rec.table_name;
    end loop;
    raise notice 'Views Count: %', cnt;
	
    raise notice '';
    raise notice '#########################';
    raise notice '###     SEQUENCES     ###';
    raise notice '#########################';
    raise notice '';
	
    cnt := 0;
    for rec in (
        SELECT sequence_schema, sequence_name 
	FROM information_schema.sequences
	WHERE sequence_schema NOT IN ('pg_catalog', 'information_schema', 'sys_admin')
    )
    loop
        cnt := cnt + 1;
        raise notice '%.%', rec.sequence_schema, rec.sequence_name;
    end loop;
    raise notice 'Sequences Count: %', cnt;

    raise notice '';
    raise notice '#########################';
    raise notice '###     FUNCTIONS     ###';
    raise notice '#########################';
    raise notice '';
  
    cnt := 0;
    for rec in (
        SELECT routine_schema, routine_name 
        FROM information_schema.routines
	WHERE routine_type = 'FUNCTION'
	AND routine_schema NOT IN ('pg_catalog', 'information_schema', 'sys_admin')
    )
    loop
        cnt := cnt + 1;
        raise notice '%.%', rec.routine_schema, rec.routine_name;
    end loop;
    raise notice 'Functions Count: %', cnt;
END;
$$;


ALTER PROCEDURE sys_admin.chnm_authorize(IN v_flag text, IN v_schema_privs text, IN v_schema_table_privs text, IN v_role text, IN v_dryrun boolean) OWNER TO law_admin;

--
-- Name: chnm_reassign_database_owner(text); Type: PROCEDURE; Schema: sys_admin; Owner: law_admin
--

CREATE PROCEDURE sys_admin.chnm_reassign_database_owner(IN v_owner text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  r record;
BEGIN
  FOR r IN 

    -- tables
    select 'ALTER TABLE "' || table_schema || '"."' || table_name || '" OWNER TO ' || v_owner || ';' as a
    from information_schema.tables
    where table_schema not in ('pg_catalog' , 'pg_toast', 'information_schema')

    union all

    -- sequences
    select 'ALTER SEQUENCE "' || sequence_schema || '"."' || sequence_name || '" OWNER TO ' || v_owner || ';' as a
    from information_schema.sequences
    where sequence_schema not in ('pg_catalog' , 'pg_toast', 'information_schema')

    union all

    -- views
    select 'ALTER VIEW "' || table_schema || '"."' || table_name || '" OWNER TO ' || v_owner || ';' as a
    from information_schema.views
    where table_schema not in ('pg_catalog' , 'pg_toast', 'information_schema')

    union all

    -- functions and procedures
    select 'ALTER ROUTINE "'||nsp.nspname||'"."'||p.proname||'"('||pg_get_function_identity_arguments(p.oid)||') OWNER TO ' || v_owner || ';' as a
    from pg_proc p join pg_namespace nsp ON p.pronamespace = nsp.oid
    where nsp.nspname not in ('pg_catalog' , 'pg_toast', 'information_schema')

    union all

    -- schemas
    select 'ALTER SCHEMA "' || schema_name || '" OWNER TO ' || v_owner 
    from information_schema.schemata
    where schema_name not in ('pg_catalog' , 'pg_toast', 'information_schema')

    union all

    -- database
    select 'ALTER DATABASE "' || current_database() || '" OWNER TO ' || v_owner 
  LOOP
    RAISE NOTICE '%', r.a;
    EXECUTE r.a;
  END LOOP;
END;
$$;


ALTER PROCEDURE sys_admin.chnm_reassign_database_owner(IN v_owner text) OWNER TO law_admin;

--
-- Name: chnm_revoke_role_from_users(text); Type: PROCEDURE; Schema: sys_admin; Owner: law_admin
--

CREATE PROCEDURE sys_admin.chnm_revoke_role_from_users(IN v_role text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec record;
BEGIN
    for rec in (
        WITH roles as (
            SELECT 
                rolname, rolsuper, rolinherit,
                rolcreaterole, rolcreatedb, rolcanlogin,
                rolreplication, rolconnlimit, rolvaliduntil, rolbypassrls,
                ARRAY(SELECT rolname FROM pg_auth_members m JOIN pg_roles g ON (m.roleid = g.oid) WHERE m.member = r.oid) AS memberof
            FROM pg_roles r
	)
	SELECT * FROM roles WHERE
	    v_role = ANY(memberof)
    )
    loop
        raise notice 'REVOKE % FROM %;', v_role, rec.rolname;
        execute format ('REVOKE %I FROM %I;', v_role, rec.rolname);
    end loop;
END;
$$;


ALTER PROCEDURE sys_admin.chnm_revoke_role_from_users(IN v_role text) OWNER TO law_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cases; Type: TABLE; Schema: cap; Owner: law_admin
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


ALTER TABLE cap.cases OWNER TO law_admin;

--
-- Name: citations; Type: TABLE; Schema: cap; Owner: law_admin
--

CREATE TABLE cap.citations (
    cite text NOT NULL,
    type text NOT NULL,
    "case" bigint NOT NULL
);


ALTER TABLE cap.citations OWNER TO law_admin;

--
-- Name: courts; Type: TABLE; Schema: cap; Owner: law_admin
--

CREATE TABLE cap.courts (
    id bigint NOT NULL,
    name text NOT NULL,
    name_abbreviation text NOT NULL,
    slug text NOT NULL,
    url text NOT NULL
);


ALTER TABLE cap.courts OWNER TO law_admin;

--
-- Name: jurisdictions; Type: TABLE; Schema: cap; Owner: law_admin
--

CREATE TABLE cap.jurisdictions (
    id bigint NOT NULL,
    name_long text NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    whitelisted boolean NOT NULL,
    url text NOT NULL
);


ALTER TABLE cap.jurisdictions OWNER TO law_admin;

--
-- Name: opinions; Type: TABLE; Schema: cap; Owner: law_admin
--

CREATE TABLE cap.opinions (
    "case" bigint NOT NULL,
    type text NOT NULL,
    author jsonb NOT NULL,
    text text NOT NULL
);


ALTER TABLE cap.opinions OWNER TO law_admin;

--
-- Name: reporters; Type: TABLE; Schema: cap; Owner: law_admin
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


ALTER TABLE cap.reporters OWNER TO law_admin;

--
-- Name: reporters_to_jurisdictions; Type: TABLE; Schema: cap; Owner: law_admin
--

CREATE TABLE cap.reporters_to_jurisdictions (
    reporter integer,
    jurisdiction integer
);


ALTER TABLE cap.reporters_to_jurisdictions OWNER TO law_admin;

--
-- Name: volumes; Type: TABLE; Schema: cap; Owner: law_admin
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


ALTER TABLE cap.volumes OWNER TO law_admin;

--
-- Name: volumes_to_jurisdictions; Type: TABLE; Schema: cap; Owner: law_admin
--

CREATE TABLE cap.volumes_to_jurisdictions (
    barcode text,
    jurisdiction integer
);


ALTER TABLE cap.volumes_to_jurisdictions OWNER TO law_admin;

--
-- Name: citations; Type: TABLE; Schema: cap_citations; Owner: law_admin
--

CREATE TABLE cap_citations.citations (
    cites_from integer,
    cites_to integer
);


ALTER TABLE cap_citations.citations OWNER TO law_admin;

--
-- Name: metadata; Type: TABLE; Schema: cap_citations; Owner: law_admin
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


ALTER TABLE cap_citations.metadata OWNER TO law_admin;

--
-- Name: cap_to_cap_citations; Type: MATERIALIZED VIEW; Schema: cap_citations; Owner: lmullen
--

CREATE MATERIALIZED VIEW cap_citations.cap_to_cap_citations AS
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


ALTER MATERIALIZED VIEW cap_citations.cap_to_cap_citations OWNER TO lmullen;

--
-- Name: pagerank; Type: TABLE; Schema: cap_citations; Owner: law_admin
--

CREATE TABLE cap_citations.pagerank (
    id integer,
    raw_score double precision,
    percentile double precision
);


ALTER TABLE cap_citations.pagerank OWNER TO law_admin;

--
-- Name: page_ocrtext; Type: TABLE; Schema: moml; Owner: law_admin
--

CREATE TABLE moml.page_ocrtext (
    pageid character varying(510) NOT NULL,
    psmid character varying(510) NOT NULL,
    ocrtext text
);


ALTER TABLE moml.page_ocrtext OWNER TO law_admin;

--
-- Name: all_page_id; Type: MATERIALIZED VIEW; Schema: legalhist; Owner: lmullen
--

CREATE MATERIALIZED VIEW legalhist.all_page_id AS
 SELECT psmid,
    pageid
   FROM moml.page_ocrtext
  WITH NO DATA;


ALTER MATERIALIZED VIEW legalhist.all_page_id OWNER TO lmullen;

--
-- Name: ocr_corrections; Type: TABLE; Schema: legalhist; Owner: law_admin
--

CREATE TABLE legalhist.ocr_corrections (
    mistake text,
    correction text
);


ALTER TABLE legalhist.ocr_corrections OWNER TO law_admin;

--
-- Name: reporters_alt_diffvols_abbreviations; Type: TABLE; Schema: legalhist; Owner: law_admin
--

CREATE TABLE legalhist.reporters_alt_diffvols_abbreviations (
    cap_abbr text,
    alt_abbr text,
    reporter_title text
);


ALTER TABLE legalhist.reporters_alt_diffvols_abbreviations OWNER TO law_admin;

--
-- Name: TABLE reporters_alt_diffvols_abbreviations; Type: COMMENT; Schema: legalhist; Owner: law_admin
--

COMMENT ON TABLE legalhist.reporters_alt_diffvols_abbreviations IS 'The mapping between abbreviations and CAP reporters and our alternative reporters';


--
-- Name: reporters_alt_diffvols_reporters; Type: TABLE; Schema: legalhist; Owner: law_admin
--

CREATE TABLE legalhist.reporters_alt_diffvols_reporters (
    reporter_title text NOT NULL,
    level text,
    jurisdiction text,
    single_vol boolean NOT NULL,
    year_start integer,
    year_end integer
);


ALTER TABLE legalhist.reporters_alt_diffvols_reporters OWNER TO law_admin;

--
-- Name: TABLE reporters_alt_diffvols_reporters; Type: COMMENT; Schema: legalhist; Owner: law_admin
--

COMMENT ON TABLE legalhist.reporters_alt_diffvols_reporters IS 'Alternative reporters to reporters in CAP, where the volume numbers are different from CAP';


--
-- Name: reporters_alt_diffvols_volumes; Type: TABLE; Schema: legalhist; Owner: law_admin
--

CREATE TABLE legalhist.reporters_alt_diffvols_volumes (
    reporter_title text,
    vol integer,
    cap_vol integer,
    cap_reporter text NOT NULL
);


ALTER TABLE legalhist.reporters_alt_diffvols_volumes OWNER TO law_admin;

--
-- Name: TABLE reporters_alt_diffvols_volumes; Type: COMMENT; Schema: legalhist; Owner: law_admin
--

COMMENT ON TABLE legalhist.reporters_alt_diffvols_volumes IS 'The mapping between volumes from our alternative reporters to the CAP reporter volume numbers';


--
-- Name: reporters_alt_samevols_abbreviations; Type: TABLE; Schema: legalhist; Owner: law_admin
--

CREATE TABLE legalhist.reporters_alt_samevols_abbreviations (
    cap_abbr text NOT NULL,
    alt_abbr text NOT NULL
);


ALTER TABLE legalhist.reporters_alt_samevols_abbreviations OWNER TO law_admin;

--
-- Name: TABLE reporters_alt_samevols_abbreviations; Type: COMMENT; Schema: legalhist; Owner: law_admin
--

COMMENT ON TABLE legalhist.reporters_alt_samevols_abbreviations IS 'Alternative reporters to reporters in CAP, where the volume numbers are the same as CAP but abbreviations/names are different';


--
-- Name: reporters_citation_to_cap; Type: TABLE; Schema: legalhist; Owner: law_admin
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


ALTER TABLE legalhist.reporters_citation_to_cap OWNER TO law_admin;

--
-- Name: reporters_single_volume_abbr; Type: VIEW; Schema: legalhist; Owner: law_admin
--

CREATE VIEW legalhist.reporters_single_volume_abbr AS
 SELECT a.alt_abbr,
    a.cap_abbr,
    r.reporter_title
   FROM (legalhist.reporters_alt_diffvols_reporters r
     LEFT JOIN legalhist.reporters_alt_diffvols_abbreviations a ON ((r.reporter_title = a.reporter_title)))
  WHERE (r.single_vol = true);


ALTER VIEW legalhist.reporters_single_volume_abbr OWNER TO law_admin;

--
-- Name: VIEW reporters_single_volume_abbr; Type: COMMENT; Schema: legalhist; Owner: law_admin
--

COMMENT ON VIEW legalhist.reporters_single_volume_abbr IS 'Abbreviations for single volume reporters';


--
-- Name: textbooks_vols; Type: TABLE; Schema: legalhist; Owner: law_admin
--

CREATE TABLE legalhist.textbooks_vols (
    bibliographicid text,
    psmid text,
    webid text,
    school text NOT NULL,
    title text NOT NULL,
    edition text,
    topic text,
    year_begin integer NOT NULL,
    year_end integer NOT NULL,
    course text,
    subtopic text,
    school_state text NOT NULL,
    region text,
    class_year text
);


ALTER TABLE legalhist.textbooks_vols OWNER TO law_admin;

--
-- Name: textbooks_works; Type: TABLE; Schema: legalhist; Owner: law_admin
--

CREATE TABLE legalhist.textbooks_works (
    workid text NOT NULL,
    work_title text,
    moml_webids text[]
);


ALTER TABLE legalhist.textbooks_works OWNER TO law_admin;

--
-- Name: citations_unlinked; Type: TABLE; Schema: moml_citations; Owner: law_admin
--

CREATE TABLE moml_citations.citations_unlinked (
    id uuid NOT NULL,
    moml_treatise text NOT NULL,
    moml_page text NOT NULL,
    raw text NOT NULL,
    volume integer NOT NULL,
    reporter_abbr text NOT NULL,
    page integer NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE moml_citations.citations_unlinked OWNER TO law_admin;

--
-- Name: top_reporters; Type: MATERIALIZED VIEW; Schema: legalhist; Owner: lmullen
--

CREATE MATERIALIZED VIEW legalhist.top_reporters AS
 SELECT reporter_abbr,
    count(*) AS n
   FROM moml_citations.citations_unlinked
  GROUP BY reporter_abbr
  ORDER BY (count(*)) DESC
  WITH NO DATA;


ALTER MATERIALIZED VIEW legalhist.top_reporters OWNER TO lmullen;

--
-- Name: top_reporters_not_whitelisted; Type: VIEW; Schema: legalhist; Owner: law_admin
--

CREATE VIEW legalhist.top_reporters_not_whitelisted AS
 SELECT tr.reporter_abbr AS reporter_found,
    wl.reporter_standard,
    wl.reporter_cap,
    wl.statute,
    wl.uk,
    wl.junk,
    tr.n
   FROM (legalhist.top_reporters tr
     LEFT JOIN legalhist.reporters_citation_to_cap wl ON ((tr.reporter_abbr = wl.reporter_found)))
  WHERE (wl.reporter_found IS NULL)
  ORDER BY tr.n DESC;


ALTER VIEW legalhist.top_reporters_not_whitelisted OWNER TO law_admin;

--
-- Name: book_citation; Type: TABLE; Schema: moml; Owner: law_admin
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


ALTER TABLE moml.book_citation OWNER TO law_admin;

--
-- Name: book_info; Type: TABLE; Schema: moml; Owner: law_admin
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


ALTER TABLE moml.book_info OWNER TO law_admin;

--
-- Name: book_locsubjecthead; Type: TABLE; Schema: moml; Owner: law_admin
--

CREATE TABLE moml.book_locsubjecthead (
    psmid character varying(510),
    type character varying(510),
    subfield character varying(510),
    locsubject character varying(510)
);


ALTER TABLE moml.book_locsubjecthead OWNER TO law_admin;

--
-- Name: book_subject; Type: TABLE; Schema: moml; Owner: law_admin
--

CREATE TABLE moml.book_subject (
    psmid character varying(510),
    subject character varying(510),
    source character varying(510)
);


ALTER TABLE moml.book_subject OWNER TO law_admin;

--
-- Name: book_volumeset; Type: TABLE; Schema: moml; Owner: law_admin
--

CREATE TABLE moml.book_volumeset (
    psmid character varying(510),
    volumeid character varying(510),
    assetid character varying(510),
    filmedvolume character varying(510)
);


ALTER TABLE moml.book_volumeset OWNER TO law_admin;

--
-- Name: legal_treatises_metadata; Type: TABLE; Schema: moml; Owner: law_admin
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


ALTER TABLE moml.legal_treatises_metadata OWNER TO law_admin;

--
-- Name: page; Type: TABLE; Schema: moml; Owner: law_admin
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


ALTER TABLE moml.page OWNER TO law_admin;

--
-- Name: page_content; Type: TABLE; Schema: moml; Owner: law_admin
--

CREATE TABLE moml.page_content (
    pageid character varying(510),
    psmid character varying(510),
    sectionheader_type character varying(510),
    sectionheader character varying(510)
);


ALTER TABLE moml.page_content OWNER TO law_admin;

--
-- Name: treatises; Type: VIEW; Schema: moml; Owner: law_admin
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


ALTER VIEW moml.treatises OWNER TO law_admin;

--
-- Name: VIEW treatises; Type: COMMENT; Schema: moml; Owner: law_admin
--

COMMENT ON VIEW moml.treatises IS 'Treatises aggregated from their individual volumes';


--
-- Name: us_treatises; Type: VIEW; Schema: moml; Owner: law_admin
--

CREATE VIEW moml.us_treatises AS
 SELECT (bibliographicid)::text AS bibliographicid,
    year,
    title,
    vols,
    subjects,
    psmid
   FROM moml.treatises
  WHERE (('UK'::text <> ALL ((subjects)::text[])) AND ('Biography'::text <> ALL ((subjects)::text[])) AND ('Collected Essays'::text <> ALL ((subjects)::text[])) AND ('Trials'::text <> ALL ((subjects)::text[])) AND (NOT (title ~* '\Woration\W'::text)) AND (NOT (title ~* '\Wremarks of\W'::text)) AND (NOT (title ~* '\Waddress\W'::text)));


ALTER VIEW moml.us_treatises OWNER TO law_admin;

--
-- Name: page_to_case; Type: TABLE; Schema: moml_citations; Owner: law_admin
--

CREATE TABLE moml_citations.page_to_case (
    id uuid NOT NULL,
    moml_treatise text,
    moml_page text,
    cite_in_moml text,
    cap_link_cite text,
    "case" bigint
);


ALTER TABLE moml_citations.page_to_case OWNER TO law_admin;

--
-- Name: volume_to_case; Type: VIEW; Schema: moml_citations; Owner: law_admin
--

CREATE VIEW moml_citations.volume_to_case AS
 SELECT moml_treatise,
    "case",
    count(*) AS n
   FROM moml_citations.page_to_case
  GROUP BY moml_treatise, "case";


ALTER VIEW moml_citations.volume_to_case OWNER TO law_admin;

--
-- Name: bibliocouple_treatises; Type: MATERIALIZED VIEW; Schema: moml_citations; Owner: lmullen
--

CREATE MATERIALIZED VIEW moml_citations.bibliocouple_treatises AS
 WITH ut2c AS (
         SELECT DISTINCT t2c.bibliographicid,
            t2c."case"
           FROM ( SELECT t.bibliographicid,
                    c.moml_treatise AS psmid,
                    c."case"
                   FROM ((moml_citations.volume_to_case c
                     LEFT JOIN moml.book_info bi ON ((c.moml_treatise = (bi.psmid)::text)))
                     LEFT JOIN moml.us_treatises t ON (((bi.bibliographicid)::text = t.bibliographicid)))) t2c
        )
 SELECT cites1.bibliographicid AS t1,
    cites2.bibliographicid AS t2,
    count(*) AS n
   FROM (ut2c cites1
     LEFT JOIN ut2c cites2 ON ((cites1."case" = cites2."case")))
  WHERE (cites1.bibliographicid <> cites2.bibliographicid)
  GROUP BY cites1.bibliographicid, cites2.bibliographicid
  WITH NO DATA;


ALTER MATERIALIZED VIEW moml_citations.bibliocouple_treatises OWNER TO lmullen;

--
-- Name: database_size; Type: VIEW; Schema: stats; Owner: law_admin
--

CREATE VIEW stats.database_size AS
 SELECT pg_size_pretty(pg_database_size('law'::name)) AS pg_size_pretty;


ALTER VIEW stats.database_size OWNER TO law_admin;

--
-- Name: table_sizes; Type: VIEW; Schema: stats; Owner: law_admin
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


ALTER VIEW stats.table_sizes OWNER TO law_admin;

--
-- Name: migrations_dbmate; Type: TABLE; Schema: sys_admin; Owner: law_admin
--

CREATE TABLE sys_admin.migrations_dbmate (
    version character varying(128) NOT NULL
);


ALTER TABLE sys_admin.migrations_dbmate OWNER TO law_admin;

--
-- Name: schools_to_cases; Type: MATERIALIZED VIEW; Schema: textbooks; Owner: lmullen
--

CREATE MATERIALIZED VIEW textbooks.schools_to_cases AS
 SELECT s2w2v.school,
    s2w2v.school_state,
    s2w2v.region,
    s2w2v.course,
    s2w2v.topic,
    s2w2v.subtopic,
    s2w2v.year_begin,
    s2w2v.year_end,
    s2w2v.workid,
    s2w2v.work_title,
    s2w2v.moml_webid,
    m6.moml_treatise,
    m6."case",
    c.name_abbreviation,
    c.decision_year,
    j.name_long AS jurisdiction_name
   FROM (((( SELECT tw.workid,
            tw.work_title,
            tw.moml_webid,
            tv.bibliographicid,
            tv.psmid,
            tv.webid,
            tv.school,
            tv.title,
            tv.edition,
            tv.topic,
            tv.year_begin,
            tv.year_end,
            tv.course,
            tv.subtopic,
            tv.school_state,
            tv.region,
            tv.class_year
           FROM (( SELECT textbooks_works.workid,
                    textbooks_works.work_title,
                    unnest(textbooks_works.moml_webids) AS moml_webid
                   FROM legalhist.textbooks_works) tw
             LEFT JOIN legalhist.textbooks_vols tv ON ((tw.moml_webid = tv.webid)))) s2w2v
     LEFT JOIN moml_citations.volume_to_case m6 ON ((s2w2v.psmid = m6.moml_treatise)))
     LEFT JOIN cap.cases c ON ((m6."case" = c.id)))
     LEFT JOIN cap.jurisdictions j ON ((c.jurisdiction = j.id)))
  WITH NO DATA;


ALTER MATERIALIZED VIEW textbooks.schools_to_cases OWNER TO lmullen;

--
-- Name: schools_to_textbooks; Type: VIEW; Schema: textbooks; Owner: law_admin
--

CREATE VIEW textbooks.schools_to_textbooks AS
 SELECT DISTINCT tv.school,
    tw.workid,
    tw.title
   FROM (( SELECT textbooks_works.workid,
            textbooks_works.work_title AS title,
            unnest(textbooks_works.moml_webids) AS moml_webid
           FROM legalhist.textbooks_works) tw
     LEFT JOIN legalhist.textbooks_vols tv ON ((tw.moml_webid = tv.webid)))
  ORDER BY tw.workid;


ALTER VIEW textbooks.schools_to_textbooks OWNER TO law_admin;

--
-- Name: cases cases_pkey; Type: CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (id);


--
-- Name: courts courts_pkey; Type: CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.courts
    ADD CONSTRAINT courts_pkey PRIMARY KEY (id);


--
-- Name: jurisdictions jurisdictions_pkey; Type: CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.jurisdictions
    ADD CONSTRAINT jurisdictions_pkey PRIMARY KEY (id);


--
-- Name: reporters reporters_pkey; Type: CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.reporters
    ADD CONSTRAINT reporters_pkey PRIMARY KEY (id);


--
-- Name: volumes volumes_pkey; Type: CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.volumes
    ADD CONSTRAINT volumes_pkey PRIMARY KEY (barcode);


--
-- Name: metadata metadata_pkey1; Type: CONSTRAINT; Schema: cap_citations; Owner: law_admin
--

ALTER TABLE ONLY cap_citations.metadata
    ADD CONSTRAINT metadata_pkey1 PRIMARY KEY (id);


--
-- Name: ocr_corrections ocr_corrections_unique; Type: CONSTRAINT; Schema: legalhist; Owner: law_admin
--

ALTER TABLE ONLY legalhist.ocr_corrections
    ADD CONSTRAINT ocr_corrections_unique UNIQUE (mistake, correction);


--
-- Name: reporters_alt_samevols_abbreviations reporter_alt_abbr_unique; Type: CONSTRAINT; Schema: legalhist; Owner: law_admin
--

ALTER TABLE ONLY legalhist.reporters_alt_samevols_abbreviations
    ADD CONSTRAINT reporter_alt_abbr_unique UNIQUE (cap_abbr, alt_abbr);


--
-- Name: reporters_alt_diffvols_abbreviations reporter_alt_diff_vols_abbr_unique; Type: CONSTRAINT; Schema: legalhist; Owner: law_admin
--

ALTER TABLE ONLY legalhist.reporters_alt_diffvols_abbreviations
    ADD CONSTRAINT reporter_alt_diff_vols_abbr_unique UNIQUE (cap_abbr, alt_abbr);


--
-- Name: reporters_alt_diffvols_reporters reporters_alt_diff_vols_pkey; Type: CONSTRAINT; Schema: legalhist; Owner: law_admin
--

ALTER TABLE ONLY legalhist.reporters_alt_diffvols_reporters
    ADD CONSTRAINT reporters_alt_diff_vols_pkey PRIMARY KEY (reporter_title);


--
-- Name: reporters_citation_to_cap reporters_citation_to_cap_pkey; Type: CONSTRAINT; Schema: legalhist; Owner: law_admin
--

ALTER TABLE ONLY legalhist.reporters_citation_to_cap
    ADD CONSTRAINT reporters_citation_to_cap_pkey PRIMARY KEY (reporter_found);


--
-- Name: textbooks_works textbooks_works_pkey; Type: CONSTRAINT; Schema: legalhist; Owner: law_admin
--

ALTER TABLE ONLY legalhist.textbooks_works
    ADD CONSTRAINT textbooks_works_pkey PRIMARY KEY (workid);


--
-- Name: book_info book_info_pkey; Type: CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.book_info
    ADD CONSTRAINT book_info_pkey PRIMARY KEY (psmid);


--
-- Name: legal_treatises_metadata legal_treatises_metadata_pkey; Type: CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.legal_treatises_metadata
    ADD CONSTRAINT legal_treatises_metadata_pkey PRIMARY KEY (psmid);


--
-- Name: page_ocrtext moml_page_ocrtext_pk; Type: CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.page_ocrtext
    ADD CONSTRAINT moml_page_ocrtext_pk PRIMARY KEY (psmid, pageid);


--
-- Name: page page_pkey; Type: CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.page
    ADD CONSTRAINT page_pkey PRIMARY KEY (pageid, psmid);


--
-- Name: citations_unlinked moml_citations_id_key; Type: CONSTRAINT; Schema: moml_citations; Owner: law_admin
--

ALTER TABLE ONLY moml_citations.citations_unlinked
    ADD CONSTRAINT moml_citations_id_key UNIQUE (id);


--
-- Name: citations_unlinked moml_citations_pkey; Type: CONSTRAINT; Schema: moml_citations; Owner: law_admin
--

ALTER TABLE ONLY moml_citations.citations_unlinked
    ADD CONSTRAINT moml_citations_pkey PRIMARY KEY (moml_treatise, moml_page, volume, reporter_abbr, page);


--
-- Name: page_to_case moml_page_to_cap_case_pkey; Type: CONSTRAINT; Schema: moml_citations; Owner: law_admin
--

ALTER TABLE ONLY moml_citations.page_to_case
    ADD CONSTRAINT moml_page_to_cap_case_pkey PRIMARY KEY (id);


--
-- Name: migrations_dbmate migrations_dbmate_pkey; Type: CONSTRAINT; Schema: sys_admin; Owner: law_admin
--

ALTER TABLE ONLY sys_admin.migrations_dbmate
    ADD CONSTRAINT migrations_dbmate_pkey PRIMARY KEY (version);


--
-- Name: cap_case_first_page_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX cap_case_first_page_idx ON cap.cases USING btree (first_page);


--
-- Name: cap_case_jurisdiction_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX cap_case_jurisdiction_idx ON cap.cases USING btree (jurisdiction);


--
-- Name: cap_case_last_page_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX cap_case_last_page_idx ON cap.cases USING btree (last_page);


--
-- Name: cap_case_reporter_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX cap_case_reporter_idx ON cap.cases USING btree (reporter);


--
-- Name: cap_case_volume_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX cap_case_volume_idx ON cap.cases USING btree (volume);


--
-- Name: cap_case_year_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX cap_case_year_idx ON cap.cases USING btree (decision_year);


--
-- Name: cap_citations_case_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX cap_citations_case_idx ON cap.citations USING btree ("case");


--
-- Name: cap_citations_cite_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX cap_citations_cite_idx ON cap.citations USING btree (cite);


--
-- Name: cap_reporters_to_jurisdictions_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE UNIQUE INDEX cap_reporters_to_jurisdictions_idx ON cap.reporters_to_jurisdictions USING btree (reporter, jurisdiction);


--
-- Name: cap_volumes_to_jurisdictions_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE UNIQUE INDEX cap_volumes_to_jurisdictions_idx ON cap.volumes_to_jurisdictions USING btree (barcode, jurisdiction);


--
-- Name: reporters_short_name_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX reporters_short_name_idx ON cap.reporters USING btree (short_name);


--
-- Name: reporters_to_jurisdictions_jurisdiction_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX reporters_to_jurisdictions_jurisdiction_idx ON cap.reporters_to_jurisdictions USING btree (jurisdiction);


--
-- Name: reporters_to_jurisdictions_reporter_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX reporters_to_jurisdictions_reporter_idx ON cap.reporters_to_jurisdictions USING btree (reporter);


--
-- Name: volumes_volume_number_idx; Type: INDEX; Schema: cap; Owner: law_admin
--

CREATE INDEX volumes_volume_number_idx ON cap.volumes USING btree (volume_number);


--
-- Name: citations_cites_from_idx; Type: INDEX; Schema: cap_citations; Owner: law_admin
--

CREATE INDEX citations_cites_from_idx ON cap_citations.citations USING btree (cites_from);


--
-- Name: citations_cites_to_idx; Type: INDEX; Schema: cap_citations; Owner: law_admin
--

CREATE INDEX citations_cites_to_idx ON cap_citations.citations USING btree (cites_to);


--
-- Name: metadata_decision_year_idx; Type: INDEX; Schema: cap_citations; Owner: law_admin
--

CREATE INDEX metadata_decision_year_idx ON cap_citations.metadata USING btree (decision_year);


--
-- Name: metadata_jurisdiction__name_idx; Type: INDEX; Schema: cap_citations; Owner: law_admin
--

CREATE INDEX metadata_jurisdiction__name_idx ON cap_citations.metadata USING btree (jurisdiction_name);


--
-- Name: reporter_alt_same_vols_alt_abbr_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporter_alt_same_vols_alt_abbr_idx ON legalhist.reporters_alt_samevols_abbreviations USING btree (alt_abbr);


--
-- Name: reporter_alt_same_vols_cap_abbr_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporter_alt_same_vols_cap_abbr_idx ON legalhist.reporters_alt_samevols_abbreviations USING btree (cap_abbr);


--
-- Name: reporters_alt_diff_vols_single_vol_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporters_alt_diff_vols_single_vol_idx ON legalhist.reporters_alt_diffvols_reporters USING btree (single_vol);


--
-- Name: reporters_alt_diffvols_abbreviations_alt_abbr_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporters_alt_diffvols_abbreviations_alt_abbr_idx ON legalhist.reporters_alt_diffvols_abbreviations USING btree (alt_abbr);


--
-- Name: reporters_alt_diffvols_abbreviations_cap_abbr_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporters_alt_diffvols_abbreviations_cap_abbr_idx ON legalhist.reporters_alt_diffvols_abbreviations USING btree (cap_abbr);


--
-- Name: reporters_alt_diffvols_abbreviations_reporter_title_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporters_alt_diffvols_abbreviations_reporter_title_idx ON legalhist.reporters_alt_diffvols_abbreviations USING btree (reporter_title);


--
-- Name: reporters_alt_diffvols_volumes_cap_reporter_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporters_alt_diffvols_volumes_cap_reporter_idx ON legalhist.reporters_alt_diffvols_volumes USING btree (cap_reporter);


--
-- Name: reporters_alt_diffvols_volumes_vol_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporters_alt_diffvols_volumes_vol_idx ON legalhist.reporters_alt_diffvols_volumes USING btree (vol);


--
-- Name: reporters_citation_to_cap_reporter_cap_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporters_citation_to_cap_reporter_cap_idx ON legalhist.reporters_citation_to_cap USING btree (reporter_cap);


--
-- Name: reporters_citation_to_cap_reporter_standard_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX reporters_citation_to_cap_reporter_standard_idx ON legalhist.reporters_citation_to_cap USING btree (reporter_standard);


--
-- Name: textbooks_bibliographicid2_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX textbooks_bibliographicid2_idx ON legalhist.textbooks_vols USING btree (bibliographicid);


--
-- Name: textbooks_bibliographicid_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX textbooks_bibliographicid_idx ON legalhist.textbooks_vols USING btree (bibliographicid);


--
-- Name: textbooks_psmid2_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX textbooks_psmid2_idx ON legalhist.textbooks_vols USING btree (psmid);


--
-- Name: textbooks_psmid_idx; Type: INDEX; Schema: legalhist; Owner: law_admin
--

CREATE INDEX textbooks_psmid_idx ON legalhist.textbooks_vols USING btree (psmid);


--
-- Name: top_reporters_reporter_abbr_idx; Type: INDEX; Schema: legalhist; Owner: lmullen
--

CREATE INDEX top_reporters_reporter_abbr_idx ON legalhist.top_reporters USING btree (reporter_abbr);


--
-- Name: book_info_bibliographicid_idx; Type: INDEX; Schema: moml; Owner: law_admin
--

CREATE INDEX book_info_bibliographicid_idx ON moml.book_info USING btree (bibliographicid);


--
-- Name: book_info_webid_idx; Type: INDEX; Schema: moml; Owner: law_admin
--

CREATE INDEX book_info_webid_idx ON moml.book_info USING btree (webid);


--
-- Name: book_subject_subject_idx; Type: INDEX; Schema: moml; Owner: law_admin
--

CREATE INDEX book_subject_subject_idx ON moml.book_subject USING btree (subject);


--
-- Name: moml_page_to_cap_case_case_idx; Type: INDEX; Schema: moml_citations; Owner: law_admin
--

CREATE INDEX moml_page_to_cap_case_case_idx ON moml_citations.page_to_case USING btree ("case");


--
-- Name: moml_page_to_cap_case_moml_page_idx; Type: INDEX; Schema: moml_citations; Owner: law_admin
--

CREATE INDEX moml_page_to_cap_case_moml_page_idx ON moml_citations.page_to_case USING btree (moml_page);


--
-- Name: moml_page_to_cap_case_moml_treatise_idx; Type: INDEX; Schema: moml_citations; Owner: law_admin
--

CREATE INDEX moml_page_to_cap_case_moml_treatise_idx ON moml_citations.page_to_case USING btree (moml_treatise);


--
-- Name: cases cap_cases_court_fk; Type: FK CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cap_cases_court_fk FOREIGN KEY (court) REFERENCES cap.courts(id);


--
-- Name: cases cap_cases_jurisdiction_fk; Type: FK CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cap_cases_jurisdiction_fk FOREIGN KEY (jurisdiction) REFERENCES cap.jurisdictions(id);


--
-- Name: cases cap_cases_reporter_fk; Type: FK CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cap_cases_reporter_fk FOREIGN KEY (reporter) REFERENCES cap.reporters(id);


--
-- Name: cases cap_cases_volume_fk; Type: FK CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.cases
    ADD CONSTRAINT cap_cases_volume_fk FOREIGN KEY (volume) REFERENCES cap.volumes(barcode);


--
-- Name: citations cap_citations_case_fk; Type: FK CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.citations
    ADD CONSTRAINT cap_citations_case_fk FOREIGN KEY ("case") REFERENCES cap.cases(id);


--
-- Name: opinions cap_opinions_case_fk; Type: FK CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.opinions
    ADD CONSTRAINT cap_opinions_case_fk FOREIGN KEY ("case") REFERENCES cap.cases(id);


--
-- Name: reporters_to_jurisdictions reporters_to_jurisdictions_reporter_fkey; Type: FK CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.reporters_to_jurisdictions
    ADD CONSTRAINT reporters_to_jurisdictions_reporter_fkey FOREIGN KEY (reporter) REFERENCES cap.reporters(id);


--
-- Name: volumes_to_jurisdictions volumes_to_jurisdictions_barcode_fkey; Type: FK CONSTRAINT; Schema: cap; Owner: law_admin
--

ALTER TABLE ONLY cap.volumes_to_jurisdictions
    ADD CONSTRAINT volumes_to_jurisdictions_barcode_fkey FOREIGN KEY (barcode) REFERENCES cap.volumes(barcode);


--
-- Name: citations citations_cites_from_fkey; Type: FK CONSTRAINT; Schema: cap_citations; Owner: law_admin
--

ALTER TABLE ONLY cap_citations.citations
    ADD CONSTRAINT citations_cites_from_fkey FOREIGN KEY (cites_from) REFERENCES cap_citations.metadata(id);


--
-- Name: citations citations_cites_to_fkey; Type: FK CONSTRAINT; Schema: cap_citations; Owner: law_admin
--

ALTER TABLE ONLY cap_citations.citations
    ADD CONSTRAINT citations_cites_to_fkey FOREIGN KEY (cites_to) REFERENCES cap_citations.metadata(id);


--
-- Name: pagerank pagerank_id_fkey; Type: FK CONSTRAINT; Schema: cap_citations; Owner: law_admin
--

ALTER TABLE ONLY cap_citations.pagerank
    ADD CONSTRAINT pagerank_id_fkey FOREIGN KEY (id) REFERENCES cap_citations.metadata(id);


--
-- Name: reporters_alt_diffvols_abbreviations reporters_alt_diffvols_abbreviations_reporter_title_fkey; Type: FK CONSTRAINT; Schema: legalhist; Owner: law_admin
--

ALTER TABLE ONLY legalhist.reporters_alt_diffvols_abbreviations
    ADD CONSTRAINT reporters_alt_diffvols_abbreviations_reporter_title_fkey FOREIGN KEY (reporter_title) REFERENCES legalhist.reporters_alt_diffvols_reporters(reporter_title);


--
-- Name: reporters_alt_diffvols_volumes reporters_alt_diffvols_volumes_reporter_title_fkey; Type: FK CONSTRAINT; Schema: legalhist; Owner: law_admin
--

ALTER TABLE ONLY legalhist.reporters_alt_diffvols_volumes
    ADD CONSTRAINT reporters_alt_diffvols_volumes_reporter_title_fkey FOREIGN KEY (reporter_title) REFERENCES legalhist.reporters_alt_diffvols_reporters(reporter_title);


--
-- Name: textbooks_vols textbooks_psmid_fkey; Type: FK CONSTRAINT; Schema: legalhist; Owner: law_admin
--

ALTER TABLE ONLY legalhist.textbooks_vols
    ADD CONSTRAINT textbooks_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: book_citation book_citation_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.book_citation
    ADD CONSTRAINT book_citation_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: book_locsubjecthead book_locsubjecthead_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.book_locsubjecthead
    ADD CONSTRAINT book_locsubjecthead_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: book_subject book_subject_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.book_subject
    ADD CONSTRAINT book_subject_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: book_volumeset book_volumeset_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.book_volumeset
    ADD CONSTRAINT book_volumeset_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: page_content page_content_pageid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.page_content
    ADD CONSTRAINT page_content_pageid_fkey FOREIGN KEY (pageid, psmid) REFERENCES moml.page(pageid, psmid);


--
-- Name: page_ocrtext page_ocrtext_pageid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.page_ocrtext
    ADD CONSTRAINT page_ocrtext_pageid_fkey FOREIGN KEY (pageid, psmid) REFERENCES moml.page(pageid, psmid);


--
-- Name: page_ocrtext page_ocrtext_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.page_ocrtext
    ADD CONSTRAINT page_ocrtext_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.legal_treatises_metadata(psmid);


--
-- Name: page page_psmid_fkey; Type: FK CONSTRAINT; Schema: moml; Owner: law_admin
--

ALTER TABLE ONLY moml.page
    ADD CONSTRAINT page_psmid_fkey FOREIGN KEY (psmid) REFERENCES moml.book_info(psmid);


--
-- Name: SCHEMA cap; Type: ACL; Schema: -; Owner: law_admin
--

GRANT USAGE ON SCHEMA cap TO law_service;


--
-- Name: SCHEMA cap_citations; Type: ACL; Schema: -; Owner: law_admin
--

GRANT USAGE ON SCHEMA cap_citations TO law_service;


--
-- Name: SCHEMA legalhist; Type: ACL; Schema: -; Owner: law_admin
--

GRANT USAGE ON SCHEMA legalhist TO law_service;


--
-- Name: SCHEMA moml; Type: ACL; Schema: -; Owner: law_admin
--

GRANT USAGE ON SCHEMA moml TO law_service;


--
-- Name: SCHEMA moml_citations; Type: ACL; Schema: -; Owner: law_admin
--

GRANT USAGE ON SCHEMA moml_citations TO law_service;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: law_admin
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT ALL ON SCHEMA public TO law_dev;


--
-- Name: SCHEMA stats; Type: ACL; Schema: -; Owner: law_admin
--

GRANT USAGE ON SCHEMA stats TO law_service;


--
-- Name: TABLE cases; Type: ACL; Schema: cap; Owner: law_admin
--

GRANT SELECT ON TABLE cap.cases TO law_service;


--
-- Name: TABLE citations; Type: ACL; Schema: cap; Owner: law_admin
--

GRANT SELECT ON TABLE cap.citations TO law_service;


--
-- Name: TABLE courts; Type: ACL; Schema: cap; Owner: law_admin
--

GRANT SELECT ON TABLE cap.courts TO law_service;


--
-- Name: TABLE jurisdictions; Type: ACL; Schema: cap; Owner: law_admin
--

GRANT SELECT ON TABLE cap.jurisdictions TO law_service;


--
-- Name: TABLE opinions; Type: ACL; Schema: cap; Owner: law_admin
--

GRANT SELECT ON TABLE cap.opinions TO law_service;


--
-- Name: TABLE reporters; Type: ACL; Schema: cap; Owner: law_admin
--

GRANT SELECT ON TABLE cap.reporters TO law_service;


--
-- Name: TABLE reporters_to_jurisdictions; Type: ACL; Schema: cap; Owner: law_admin
--

GRANT SELECT ON TABLE cap.reporters_to_jurisdictions TO law_service;


--
-- Name: TABLE volumes; Type: ACL; Schema: cap; Owner: law_admin
--

GRANT SELECT ON TABLE cap.volumes TO law_service;


--
-- Name: TABLE volumes_to_jurisdictions; Type: ACL; Schema: cap; Owner: law_admin
--

GRANT SELECT ON TABLE cap.volumes_to_jurisdictions TO law_service;


--
-- Name: TABLE citations; Type: ACL; Schema: cap_citations; Owner: law_admin
--

GRANT SELECT ON TABLE cap_citations.citations TO law_service;


--
-- Name: TABLE metadata; Type: ACL; Schema: cap_citations; Owner: law_admin
--

GRANT SELECT ON TABLE cap_citations.metadata TO law_service;


--
-- Name: TABLE pagerank; Type: ACL; Schema: cap_citations; Owner: law_admin
--

GRANT SELECT ON TABLE cap_citations.pagerank TO law_service;


--
-- Name: TABLE page_ocrtext; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.page_ocrtext TO law_service;


--
-- Name: TABLE all_page_id; Type: ACL; Schema: legalhist; Owner: lmullen
--

GRANT SELECT ON TABLE legalhist.all_page_id TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.all_page_id TO law_admin;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.all_page_id TO kfunk;


--
-- Name: TABLE ocr_corrections; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT ON TABLE legalhist.ocr_corrections TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.ocr_corrections TO kfunk;


--
-- Name: TABLE reporters_alt_diffvols_abbreviations; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT ON TABLE legalhist.reporters_alt_diffvols_abbreviations TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.reporters_alt_diffvols_abbreviations TO kfunk;


--
-- Name: TABLE reporters_alt_diffvols_reporters; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT ON TABLE legalhist.reporters_alt_diffvols_reporters TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.reporters_alt_diffvols_reporters TO kfunk;


--
-- Name: TABLE reporters_alt_diffvols_volumes; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT ON TABLE legalhist.reporters_alt_diffvols_volumes TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.reporters_alt_diffvols_volumes TO kfunk;


--
-- Name: TABLE reporters_alt_samevols_abbreviations; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT ON TABLE legalhist.reporters_alt_samevols_abbreviations TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.reporters_alt_samevols_abbreviations TO kfunk;


--
-- Name: TABLE reporters_citation_to_cap; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT ON TABLE legalhist.reporters_citation_to_cap TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.reporters_citation_to_cap TO kfunk;


--
-- Name: TABLE reporters_single_volume_abbr; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT ON TABLE legalhist.reporters_single_volume_abbr TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.reporters_single_volume_abbr TO kfunk;


--
-- Name: TABLE textbooks_vols; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT ON TABLE legalhist.textbooks_vols TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.textbooks_vols TO kfunk;


--
-- Name: TABLE textbooks_works; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.textbooks_works TO kfunk;


--
-- Name: TABLE citations_unlinked; Type: ACL; Schema: moml_citations; Owner: law_admin
--

GRANT SELECT ON TABLE moml_citations.citations_unlinked TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE moml_citations.citations_unlinked TO kfunk;


--
-- Name: TABLE top_reporters; Type: ACL; Schema: legalhist; Owner: lmullen
--

GRANT SELECT ON TABLE legalhist.top_reporters TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.top_reporters TO law_admin;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.top_reporters TO kfunk;


--
-- Name: TABLE top_reporters_not_whitelisted; Type: ACL; Schema: legalhist; Owner: law_admin
--

GRANT SELECT ON TABLE legalhist.top_reporters_not_whitelisted TO law_service;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE legalhist.top_reporters_not_whitelisted TO kfunk;


--
-- Name: TABLE book_citation; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.book_citation TO law_service;


--
-- Name: TABLE book_info; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.book_info TO law_service;


--
-- Name: TABLE book_locsubjecthead; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.book_locsubjecthead TO law_service;


--
-- Name: TABLE book_subject; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.book_subject TO law_service;


--
-- Name: TABLE book_volumeset; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.book_volumeset TO law_service;


--
-- Name: TABLE legal_treatises_metadata; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.legal_treatises_metadata TO law_service;


--
-- Name: TABLE page; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.page TO law_service;


--
-- Name: TABLE page_content; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.page_content TO law_service;


--
-- Name: TABLE treatises; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.treatises TO law_service;


--
-- Name: TABLE us_treatises; Type: ACL; Schema: moml; Owner: law_admin
--

GRANT SELECT ON TABLE moml.us_treatises TO law_service;


--
-- Name: TABLE page_to_case; Type: ACL; Schema: moml_citations; Owner: law_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE moml_citations.page_to_case TO kfunk;


--
-- Name: TABLE volume_to_case; Type: ACL; Schema: moml_citations; Owner: law_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE moml_citations.volume_to_case TO kfunk;


--
-- Name: TABLE bibliocouple_treatises; Type: ACL; Schema: moml_citations; Owner: lmullen
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE moml_citations.bibliocouple_treatises TO kfunk;


--
-- Name: TABLE database_size; Type: ACL; Schema: stats; Owner: law_admin
--

GRANT SELECT ON TABLE stats.database_size TO law_service;


--
-- Name: TABLE table_sizes; Type: ACL; Schema: stats; Owner: law_admin
--

GRANT SELECT ON TABLE stats.table_sizes TO law_service;


--
-- Name: TABLE schools_to_cases; Type: ACL; Schema: textbooks; Owner: lmullen
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE textbooks.schools_to_cases TO kfunk;


--
-- Name: TABLE schools_to_textbooks; Type: ACL; Schema: textbooks; Owner: law_admin
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE textbooks.schools_to_textbooks TO kfunk;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: legalhist; Owner: lmullen
--

ALTER DEFAULT PRIVILEGES FOR ROLE lmullen IN SCHEMA legalhist GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO kfunk;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: moml_citations; Owner: lmullen
--

ALTER DEFAULT PRIVILEGES FOR ROLE lmullen IN SCHEMA moml_citations GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO kfunk;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: lmullen
--

ALTER DEFAULT PRIVILEGES FOR ROLE lmullen IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO kfunk;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: textbooks; Owner: lmullen
--

ALTER DEFAULT PRIVILEGES FOR ROLE lmullen IN SCHEMA textbooks GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO kfunk;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON SEQUENCES TO law_dev;


--
-- Name: DEFAULT PRIVILEGES FOR SCHEMAS; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT CREATE ON SCHEMAS TO law_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT USAGE ON SCHEMAS TO law_dev;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON TABLES TO law_dev;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT SELECT ON TABLES TO law_service;


--
-- PostgreSQL database dump complete
--

