-- migrate:up
SET ROLE = law_admin;

-- Whitelist fixes from comparing our CAP-opinion links with CAP's own
-- citation graph (issue #356; the evidence is in
-- https://github.com/chnm/legal-modernism/issues/74#issuecomment-6300506487).
-- A citation of ours, "v S p" in citing case C, was matched to an edge from C
-- that only CAP's graph has when that edge's cited case has a CAP cite with
-- volume v and a page span containing p; over many citations, the CAP
-- reporter of the matched cites says what spelling S means. Counts below are
-- rows in opinion_citations.citations_unlinked (CAP) and
-- moml_citations.citations_unlinked (MOML), measured 2026-10-21.
--
-- Four parts:
--
-- 1. Spellings mapped to the wrong reporter. 'South.' (178,173 CAP, 29,243
--    MOML; under 2% at a volume within Southard's two) is the Southern
--    Reporter; 'An.' is La. Ann.; the S. & M. family is Smedes & Marshall's
--    Mississippi Reports, not the one-volume Chancery Reports; 'J. R.' is
--    Johnson's Reports; and 'W. R.' (292,640 MOML, 97% above volume 3) is
--    the Weekly Reporter, not W. Robinson's three volumes of Admiralty.
--    'South.' and 'J. R.' are each another reporter's reporter_standard, and
--    under the #289 rule a standard spelling belongs to its reporter, so
--    Southard's Reports is re-keyed as 'South. (N.J.)' and the Judicial
--    Review as 'Jurid. Rev.' before their spellings move, in the manner of
--    20260906140000_seed-remap-er-reporter-spellings.sql. 'Hill' above
--    volume 3 and 'Howard' above volume 7 are left alone: their low volumes
--    link correctly to Hill's S.C. and Howard's Mississippi Reports (about
--    8,000 and 1,400 CAP links), so they turn on the volume, which the
--    whitelist cannot express (#358).
--
-- 2. Spellings added: variants with evidence from CAP's graph, and some by
--    name only. The Missouri "l. c." forms and the "at page" forms are pin
--    cites and link through cap_page_interior.
--
-- 3. Spellings marked junk, so they leave the not-whitelisted pool: surnames
--    read as reporters, treatises and digests, American statutes (junk by
--    the existing convention), and prose.
--
-- 4. Stubs minted under 'J. R.' are deleted, since they were Johnson's
--    citations; a stub with curated metadata is kept, and then so is the
--    'J. R.' reporter row it needs. The A.B.R. stubs minted from 'An.' are
--    indistinguishable from real ones and are left for `make db-stubs`.
--
-- Nothing here changes what the detector finds. The data step is a relink of
-- both corpora with a stub rebuild.
--
-- Left for other issues: the diffvols fallback that turns an uncovered
-- 'South.' or 'Hill' volume into a wrong link (#357); spellings whose
-- reporter turns on the citing jurisdiction or the volume (#358).

-- 1a. Re-key Southard's Reports and the Judicial Review.

INSERT INTO legalhist.reporters
    (reporter_standard, reporter_title, level, jurisdiction, year_start, year_end, single_vol, type, reporter_cap, cited_by_year_from)
SELECT m.new, r.reporter_title, r.level, r.jurisdiction, r.year_start, r.year_end, r.single_vol, r.type, r.reporter_cap, r.cited_by_year_from
FROM (VALUES
    ('South.', 'South. (N.J.)'),
    ('J. R.',  'Jurid. Rev.')
) AS m(old, new)
JOIN legalhist.reporters r ON r.reporter_standard = m.old
WHERE NOT EXISTS (SELECT 1 FROM legalhist.reporters n WHERE n.reporter_standard = m.new);

UPDATE legalhist.reporters_diffvols
   SET reporter_standard = 'South. (N.J.)'
 WHERE reporter_standard = 'South.'
   AND EXISTS (SELECT 1 FROM legalhist.reporters n WHERE n.reporter_standard = 'South. (N.J.)');

UPDATE legalhist.reporters_abbreviations
   SET reporter_standard = 'South. (N.J.)'
 WHERE reporter_standard = 'South.'
   AND EXISTS (SELECT 1 FROM legalhist.reporters n WHERE n.reporter_standard = 'South. (N.J.)');

-- The spellings that stay with Southard. 'South.)' is almost always
-- volume 1 or 2 ("(1 South.)"); the others name the reporter or the state.
UPDATE legalhist.whitelist
   SET reporter_standard = 'South. (N.J.)'
 WHERE reporter_standard = 'South.'
   AND reporter_found IN ('South.)', 'Southard,', 'South. (N. J.)', 'South. Pep.')
   AND EXISTS (SELECT 1 FROM legalhist.reporters n WHERE n.reporter_standard = 'South. (N.J.)');

-- 1b. Move the misread spellings.

UPDATE legalhist.whitelist w
   SET reporter_standard = m.new
  FROM (VALUES
    -- Southern Reporter: 'South.' and its OCR variants
    ('South.',  'South.', 'So.'),
    ('Sonth.',  'South.', 'So.'),
    ('Soulh.',  'South.', 'So.'),
    ('Soutli.', 'South.', 'So.'),
    -- Louisiana Annual Reports: 18,547 CAP, 2,260 MOML
    ('An.', 'A.B.R.', 'La. Ann.'),
    -- Johnson's Reports: 2,823 CAP, 5,492 MOML
    ('J. R.', 'J. R.', 'Johns.'),
    -- Weekly Reporter
    ('W. R.',  'W Rob', 'W.R.'),
    ('W. R',   'W Rob', 'W.R.'),
    ('W. R.,', 'W Rob', 'W.R.'),
    ('W. r.',  'W Rob', 'W.R.'),
    ('W. t.',  'W Rob', 'W.R.')  -- 3,536 MOML, 96% above volume 3: a misread 'W. R.'
) AS m(found, old, new)
 WHERE w.reporter_found = m.found
   AND w.reporter_standard = m.old;

-- Smedes & Marshall's Mississippi Reports (1843-50, 14 volumes), which CAP
-- holds as 'S. & M.'. The Chancery Reports keep their 'Ch.' spellings.
INSERT INTO legalhist.reporters
    (reporter_standard, reporter_title, level, jurisdiction, year_start, year_end, single_vol, type)
SELECT 'S. & M.', 'Smedes & Marshall''s Mississippi Reports', 'state', 'us:ms', 1843, 1850, false, 'nominate'
WHERE NOT EXISTS (SELECT 1 FROM legalhist.reporters WHERE reporter_standard = 'S. & M.');

UPDATE legalhist.whitelist
   SET reporter_standard = 'S. & M.'
 WHERE reporter_standard = 'Miss. (S. & M. Ch.)'
   AND reporter_found IN (
     'S. & M.', 'S. & M. (Miss.)', 'S. & MI.', 'Sin. & M.', 'Sm. & M.',
     'Smedes & M.', 'Smedes & M. (Miss.)', 'Smedes & Mar.', 'Smedes & Marsh.',
     'Smedes & Marsh. Rep.', 'Smedes & Marshall', 'Smedes &. Marshall',
     'Smedes & Marshalls’', 'Smedes and Marshall’s Reports'
   );

UPDATE legalhist.reporters_abbreviations
   SET reporter_standard = 'S. & M.'
 WHERE reporter_standard = 'Miss. (S. & M. Ch.)'
   AND alt_abbr = 'S.& M.';

-- 1c. Drop the old keys once nothing references them. The 'J. R.' stubs go
-- first; a stub with metadata keeps its row and its reporter.

DO $$
BEGIN
  IF to_regclass('legalhist.stub_cases') IS NOT NULL THEN
    DELETE FROM legalhist.stub_cases s
     WHERE s.reporter_standard = 'J. R.'
       AND NOT EXISTS (SELECT 1 FROM legalhist.stub_case_metadata m WHERE m.cite = s.cite);
  END IF;
END $$;

DELETE FROM legalhist.reporters r
 WHERE r.reporter_standard IN ('South.', 'J. R.')
   AND NOT EXISTS (SELECT 1 FROM legalhist.whitelist w WHERE w.reporter_standard = r.reporter_standard)
   AND NOT EXISTS (SELECT 1 FROM legalhist.reporters_abbreviations a WHERE a.reporter_standard = r.reporter_standard)
   AND NOT EXISTS (SELECT 1 FROM legalhist.reporters_diffvols d WHERE d.reporter_standard = r.reporter_standard)
   AND NOT EXISTS (SELECT 1 FROM legalhist.stub_cases s WHERE s.reporter_standard = r.reporter_standard);

-- 2. Spellings added.

-- Decisiones de Puerto Rico, the Spanish series CAP holds as 'P.R. Dec.'
-- (our 'P.R.' is the English-language Puerto Rico Reports).
INSERT INTO legalhist.reporters
    (reporter_standard, reporter_title, level, jurisdiction, year_start, single_vol, type)
SELECT 'P.R. Dec.', 'Decisiones de Puerto Rico', 'state', 'us:pr', 1901, false, 'official'
WHERE NOT EXISTS (SELECT 1 FROM legalhist.reporters WHERE reporter_standard = 'P.R. Dec.');

INSERT INTO legalhist.whitelist (reporter_found, reporter_standard, junk)
SELECT v.found, v.standard, false
FROM (VALUES
    -- With evidence from CAP's graph: CAP citations, and the share matched
    -- to an edge only CAP has / the share of those landing on this reporter.
    ('Pa. Superior Ct.', 'Pa. Super.'),      -- 8,466; 95% / 100%
    ('Mo. l. c.',        'Mo.'),             -- 14,080; 14% / 100%
    ('Mo. App. l. c.',   'Mo. App.'),        -- 2,483; 13% / 99%
    ('Mo. loc. cit.',    'Mo.'),             -- 1,886; 16% / 100%
    ('D. P. R.',         'P.R. Dec.'),       -- 2,387; 65% / 100%
    ('C. Cls.',          'Ct. Cl.'),         -- 848; 86% / 100%
    ('C. Cls. R.',       'Ct. Cl.'),         -- 2,576; 1% / 86%
    ('Sandf. Ch.',       'Sand. Ch.'),       -- 1,741; 63% / 99%
    ('Por.',             'Port.'),           -- 1,516; 13% / 97%
    ('O. C. C.',         'Ohio C.C. Dec.'),  -- 684; 8% / 100%
    ('J. J. Marshall',   'J.J. Marsh.'),     -- 749; 4% / 81%
    ('Johns. Cases',     'Johns. Cas.'),     -- 648; 3% / 79%
    ('L.Ed.',            'L. Ed.'),          -- 1,164; 4% / 100%
    ('S.Ct.',            'S. Ct.'),          -- 806; 4% / 94%
    ('N. T.',            'N.Y.'),            -- 594; 7% / 100%; an OCR misreading of "N. Y."
    ('Coms.',            'Comst.'),          -- 580; 3% / 67% (to N.Y., Comst.'s reporter_cap)
    -- The same pin-cite construction as 'Mo. l. c.', with little evidence.
    ('U. S., at page',   'U.S.'),            -- 608
    ('U. S. at page',    'U.S.'),            -- 606
    ('N. Y., at page',   'N.Y.'),            -- 814
    -- By name only.
    ('Texas Ct. App.',   'Tex. Ct. App.'),   -- 7,164
    ('Georgia Reports',  'Ga.'),
    ('Oklahoma',         'Okla.'),
    ('C. E. Green',      'Green Eq.'),       -- like the existing 'C. E. Green,'
    ('C. E. Gr.)',       'Green Eq.'),
    ('Amer. Dec.',       'Am. Dec.'),
    ('Amer. St. Rep.',   'Am. St. Rep.'),
    ('L. R. A., n. s.',  'L.R.A. (n.s.)'),
    ('L. R. A., N. S.',  'L.R.A. (n.s.)'),
    ('Burrows',          'Burr'),            -- like the existing 'Burrows,'
    -- English reports, by name; in MOML nearly all fall within the
    -- reporter's volumes.
    ('Ambler',           'Amb'),             -- 4,823 MOML
    ('Taunton',          'Taunt'),           -- 2,262 MOML, 98% in vols 1-8
    ('Carr. & Payne',    'Car & P'),         -- 4,014 MOML, all in vols 1-10
    ('C. Rob. Adm.',     'C Rob'),           -- 382 MOML, 99% in vols 1-6
    ('Simons',           'Sim')              -- 2,981 MOML, 99% in vols 1-17
) AS v(found, standard)
WHERE EXISTS (SELECT 1 FROM legalhist.reporters r WHERE r.reporter_standard = v.standard)
  AND NOT EXISTS (SELECT 1 FROM legalhist.whitelist w WHERE w.reporter_found = v.found);

-- 3. Spellings marked junk. None matches an edge only CAP has.

INSERT INTO legalhist.whitelist (reporter_found, reporter_standard, junk)
SELECT v.found, NULL, true
FROM (VALUES
    -- Surnames read as reporters
    ('Burns'), ('King'), ('Palmer'), ('Phillips'), ('Cooper'), ('Andrews'),
    ('Baldwin'), ('Johnston'), ('Jacobs'), ('Fitzgerald'), ('Daniels'),
    ('Burnett'), ('Finch'), ('Vaughn'), ('Winchester'), ('Davison'),
    -- Treatises, encyclopedias and digests
    ('Kent'), ('Cyc'), ('Cyc. p.'), ('Cyc. pp.'), ('Cyc., p.'), ('Oyc.'),
    ('R. C. L.'), ('R. C. L. p.'), ('Corpus Juris'), ('Ency. Pl. & Pr.'),
    ('Enc. Pl. & Pr.'), ('Brick. Dig.'), ('Mayf. Dig.'), ('Com. Dig.'),
    ('Greenl. Ev.'), ('Jarman on Wills'),
    -- American statutes
    ('Stat. at Large'), ('St. at Large'), ('Stat'), ('Stat. L., p.'),
    ('Comp. Laws'), ('(Laws of'), ('(U. S. Comp. St.'), ('(Comp. St.'),
    ('(Pamph. L., p.'), ('R. S. p.'), ('(R. S.'), ('R. S., p.'),
    ('(Gen. Stat.'), ('O. L.'), ('Ohio Laws'), ('(chap.'), ('of Act No.'),
    ('of the code of'),
    -- Prose
    ('in block'), ('dollars and'), ('dollars'), ('north, range'),
    ('north, of range'), ('south, range'), ('feet and'), ('feet long and'),
    ('feet wide and'), ('de marzo de'), ('de mayo de'), ('de junio de'),
    ('ditto'), ('Ed.)'), ('Ed.), sec.'), ('Ed.), p.'), ('(P. C.'),
    ('Dick.)'), ('T.')
) AS v(found)
WHERE NOT EXISTS (SELECT 1 FROM legalhist.whitelist w WHERE w.reporter_found = v.found);

-- migrate:down
SET ROLE = law_admin;

-- The deleted 'J. R.' stubs are not restored: the registry is derived, and
-- `make db-stubs` rebuilds it.

DELETE FROM legalhist.whitelist
 WHERE junk
   AND reporter_found IN (
    'Burns', 'King', 'Palmer', 'Phillips', 'Cooper', 'Andrews',
    'Baldwin', 'Johnston', 'Jacobs', 'Fitzgerald', 'Daniels',
    'Burnett', 'Finch', 'Vaughn', 'Winchester', 'Davison',
    'Kent', 'Cyc', 'Cyc. p.', 'Cyc. pp.', 'Cyc., p.', 'Oyc.',
    'R. C. L.', 'R. C. L. p.', 'Corpus Juris', 'Ency. Pl. & Pr.',
    'Enc. Pl. & Pr.', 'Brick. Dig.', 'Mayf. Dig.', 'Com. Dig.',
    'Greenl. Ev.', 'Jarman on Wills',
    'Stat. at Large', 'St. at Large', 'Stat', 'Stat. L., p.',
    'Comp. Laws', '(Laws of', '(U. S. Comp. St.', '(Comp. St.',
    '(Pamph. L., p.', 'R. S. p.', '(R. S.', 'R. S., p.',
    '(Gen. Stat.', 'O. L.', 'Ohio Laws', '(chap.', 'of Act No.',
    'of the code of',
    'in block', 'dollars and', 'dollars', 'north, range',
    'north, of range', 'south, range', 'feet and', 'feet long and',
    'feet wide and', 'de marzo de', 'de mayo de', 'de junio de',
    'ditto', 'Ed.)', 'Ed.), sec.', 'Ed.), p.', '(P. C.',
    'Dick.)', 'T.'
   );

DELETE FROM legalhist.whitelist w
 USING (VALUES
    ('Pa. Superior Ct.', 'Pa. Super.'),
    ('Mo. l. c.',        'Mo.'),
    ('Mo. App. l. c.',   'Mo. App.'),
    ('Mo. loc. cit.',    'Mo.'),
    ('D. P. R.',         'P.R. Dec.'),
    ('C. Cls.',          'Ct. Cl.'),
    ('C. Cls. R.',       'Ct. Cl.'),
    ('Sandf. Ch.',       'Sand. Ch.'),
    ('Por.',             'Port.'),
    ('O. C. C.',         'Ohio C.C. Dec.'),
    ('J. J. Marshall',   'J.J. Marsh.'),
    ('Johns. Cases',     'Johns. Cas.'),
    ('L.Ed.',            'L. Ed.'),
    ('S.Ct.',            'S. Ct.'),
    ('N. T.',            'N.Y.'),
    ('Coms.',            'Comst.'),
    ('U. S., at page',   'U.S.'),
    ('U. S. at page',    'U.S.'),
    ('N. Y., at page',   'N.Y.'),
    ('Texas Ct. App.',   'Tex. Ct. App.'),
    ('Georgia Reports',  'Ga.'),
    ('Oklahoma',         'Okla.'),
    ('C. E. Green',      'Green Eq.'),
    ('C. E. Gr.)',       'Green Eq.'),
    ('Amer. Dec.',       'Am. Dec.'),
    ('Amer. St. Rep.',   'Am. St. Rep.'),
    ('L. R. A., n. s.',  'L.R.A. (n.s.)'),
    ('L. R. A., N. S.',  'L.R.A. (n.s.)'),
    ('Burrows',          'Burr'),
    ('Ambler',           'Amb'),
    ('Taunton',          'Taunt'),
    ('Carr. & Payne',    'Car & P'),
    ('C. Rob. Adm.',     'C Rob'),
    ('Simons',           'Sim')
 ) AS v(found, standard)
 WHERE w.reporter_found = v.found
   AND w.reporter_standard = v.standard;

DELETE FROM legalhist.reporters r
 WHERE r.reporter_standard = 'P.R. Dec.'
   AND NOT EXISTS (SELECT 1 FROM legalhist.whitelist w WHERE w.reporter_standard = r.reporter_standard)
   AND NOT EXISTS (SELECT 1 FROM legalhist.reporters_abbreviations a WHERE a.reporter_standard = r.reporter_standard)
   AND NOT EXISTS (SELECT 1 FROM legalhist.stub_cases s WHERE s.reporter_standard = r.reporter_standard);

-- Restore the old keys with the metadata the new rows carry.
INSERT INTO legalhist.reporters
    (reporter_standard, reporter_title, level, jurisdiction, year_start, year_end, single_vol, type, reporter_cap, cited_by_year_from)
SELECT m.old, r.reporter_title, r.level, r.jurisdiction, r.year_start, r.year_end, r.single_vol, r.type, r.reporter_cap, r.cited_by_year_from
FROM (VALUES
    ('South.', 'South. (N.J.)'),
    ('J. R.',  'Jurid. Rev.')
) AS m(old, new)
JOIN legalhist.reporters r ON r.reporter_standard = m.new
WHERE NOT EXISTS (SELECT 1 FROM legalhist.reporters o WHERE o.reporter_standard = m.old);

UPDATE legalhist.whitelist w
   SET reporter_standard = m.old
  FROM (VALUES
    ('South.',  'South.', 'So.'),
    ('Sonth.',  'South.', 'So.'),
    ('Soulh.',  'South.', 'So.'),
    ('Soutli.', 'South.', 'So.'),
    ('An.', 'A.B.R.', 'La. Ann.'),
    ('J. R.', 'J. R.', 'Johns.'),
    ('W. R.',  'W Rob', 'W.R.'),
    ('W. R',   'W Rob', 'W.R.'),
    ('W. R.,', 'W Rob', 'W.R.'),
    ('W. r.',  'W Rob', 'W.R.'),
    ('W. t.',  'W Rob', 'W.R.')
) AS m(found, old, new)
 WHERE w.reporter_found = m.found
   AND w.reporter_standard = m.new;

UPDATE legalhist.whitelist
   SET reporter_standard = 'South.'
 WHERE reporter_standard = 'South. (N.J.)';

UPDATE legalhist.reporters_abbreviations
   SET reporter_standard = 'South.'
 WHERE reporter_standard = 'South. (N.J.)';

UPDATE legalhist.reporters_diffvols
   SET reporter_standard = 'South.'
 WHERE reporter_standard = 'South. (N.J.)';

UPDATE legalhist.whitelist
   SET reporter_standard = 'Miss. (S. & M. Ch.)'
 WHERE reporter_standard = 'S. & M.';

UPDATE legalhist.reporters_abbreviations
   SET reporter_standard = 'Miss. (S. & M. Ch.)'
 WHERE reporter_standard = 'S. & M.';

DELETE FROM legalhist.reporters r
 WHERE r.reporter_standard IN ('South. (N.J.)', 'Jurid. Rev.', 'S. & M.')
   AND NOT EXISTS (SELECT 1 FROM legalhist.whitelist w WHERE w.reporter_standard = r.reporter_standard)
   AND NOT EXISTS (SELECT 1 FROM legalhist.reporters_abbreviations a WHERE a.reporter_standard = r.reporter_standard)
   AND NOT EXISTS (SELECT 1 FROM legalhist.reporters_diffvols d WHERE d.reporter_standard = r.reporter_standard)
   AND NOT EXISTS (SELECT 1 FROM legalhist.stub_cases s WHERE s.reporter_standard = r.reporter_standard);
