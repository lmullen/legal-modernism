-- migrate:up
CREATE INDEX IF NOT EXISTS idx_citations_unlinked_reporter_abbr ON moml_citations.citations_unlinked (reporter_abbr);

CREATE INDEX IF NOT EXISTS idx_alt_diffvols_volumes_composite ON legalhist.reporters_alt_diffvols_volumes (reporter_title, vol);

-- migrate:down
DROP INDEX IF EXISTS moml_citations.idx_citations_unlinked_reporter_abbr;

DROP INDEX IF EXISTS legalhist.idx_alt_diffvols_volumes_composite;
