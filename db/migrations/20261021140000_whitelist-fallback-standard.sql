-- migrate:up
SET ROLE = law_admin;

-- A second reading for spellings that mean one reporter in one jurisdiction
-- or run of volumes and another elsewhere (issue #358, from the comparison
-- with CAP's citation graph in
-- https://github.com/chnm/legal-modernism/issues/74#issuecomment-6300506487).
--
-- The whitelist maps a spelling to one reporter everywhere. "Porter" is
-- Porter's Indiana Reports, but in an Alabama opinion it is Porter's Alabama
-- Reports: of Alabama's 1,666 us_diffvols_missing and 1,173 us_anachronistic
-- misses under "Porter", 1,461 and 988 match edges of CAP's graph to cases
-- with a Port. cite. fallback_standard names that other reporter. The linker
-- tries it only when the spelling's own reading fails with a tier that says
-- the reporter was wrong -- the volume is not one it has (volume_absent,
-- diffvols_missing) or the case found is later than the citing document
-- (anachronistic) -- and keeps the fallback's result only if it links to a
-- case a source holds. Otherwise the row is the miss it always was, so the
-- stub registry, built from those misses, is unchanged.
--
-- This needs no citing jurisdiction, which the cascade does not read and MOML
-- records only as US or UK. What it cannot fix is a citation the wrong
-- reporter answers: the 802 Alabama citations under "Stew." linked into N.J.
-- Eq. are links, not misses, and stay so.
--
-- The seeds, with the evidence for each (CAP ledger, measured 2026-10-20):
--
--   spelling        reads as       falls back to   evidence
--   Porter          Porter (Ind.)  Port. (Ala.)    as above
--   Stew., Stewart, Stewart (N.J.   Stew. (Ala.)    1,843 Alabama us_anachronistic
--     Stewt. Rep.     Eq.)                          misses
--   Den.            Den (Crown     Denio (N.Y.)    1,236 N.Y. misses, 1,189
--                     Cases)                        matching Denio cites
--   D. & B.         Dears & B      Dev. & Bat.     150 N.C. misses, 70 matching
--                                    (N.C.)          Dev. & Bat. cites
--   Hill            Hill (S.C.,    Hill (N.Y.)     8,123 us_diffvols_missing above
--                     3 vols)                       vol. 3, 1,282 from N.Y.
--   Howard          Howard (Miss., How. (U.S.)     2,869 us_volume_absent above
--                     7 vols)                       vol. 7
--   South.          So.            South. (N.J.)   once #356 maps it to the
--                                                    Southern Reporter, Southard's
--                                                    two volumes are refused as
--                                                    anachronistic
--
-- The last seed is guarded on #356's reporter row and does nothing until that
-- migration has run. "Wash." is left out: CAP spells both Washington's
-- Virginia Reports and the Washington Reports "Wash.", so it is a cite the
-- two share, which #359 resolves by date. The data step is a relink.

ALTER TABLE legalhist.whitelist
  ADD COLUMN IF NOT EXISTS fallback_standard text;

ALTER TABLE legalhist.whitelist
  DROP CONSTRAINT IF EXISTS fk_whitelist_fallback_standard;
ALTER TABLE legalhist.whitelist
  ADD CONSTRAINT fk_whitelist_fallback_standard
  FOREIGN KEY (fallback_standard) REFERENCES legalhist.reporters(reporter_standard);

-- A fallback belongs to a spelling that has a reading of its own, and is a
-- different reporter from it.
ALTER TABLE legalhist.whitelist
  DROP CONSTRAINT IF EXISTS chk_whitelist_fallback;
ALTER TABLE legalhist.whitelist
  ADD CONSTRAINT chk_whitelist_fallback CHECK (
    fallback_standard IS NULL
    OR (reporter_standard IS NOT NULL AND fallback_standard <> reporter_standard)
  );

UPDATE legalhist.whitelist w
   SET fallback_standard = v.fallback
  FROM (VALUES
    ('Porter',      'Porter',  'Port.'),
    ('Stew.',       'Stewart', 'Stew.'),
    ('Stewart',     'Stewart', 'Stew.'),
    ('Stewt. Rep.', 'Stewart', 'Stew.'),
    ('Den.',        'Den',     'Denio'),
    ('D. & B.',     'Dears & B', 'Dev. & Bat.'),
    ('Hill',        'Hill',    'Hill (N.Y.)'),
    ('Howard',      'Howard',  'How.'),
    ('South.',      'So.',     'South. (N.J.)')
  ) AS v(found, standard, fallback)
 WHERE w.reporter_found = v.found
   AND w.reporter_standard = v.standard
   AND w.fallback_standard IS NULL
   AND EXISTS (SELECT 1 FROM legalhist.reporters r WHERE r.reporter_standard = v.fallback);

-- migrate:down
SET ROLE = law_admin;

ALTER TABLE legalhist.whitelist
  DROP CONSTRAINT IF EXISTS chk_whitelist_fallback;
ALTER TABLE legalhist.whitelist
  DROP CONSTRAINT IF EXISTS fk_whitelist_fallback_standard;
ALTER TABLE legalhist.whitelist
  DROP COLUMN IF EXISTS fallback_standard;
