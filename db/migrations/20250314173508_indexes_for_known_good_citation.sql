-- migrate:up
SET ROLE = law_admin;

ALTER TABLE moml_citations.citations_known
ADD CONSTRAINT pk_citations_known_id PRIMARY KEY (id);

CREATE INDEX idx_citations_known_cite_alternative ON moml_citations.citations_known (cite_alternative);

CREATE INDEX idx_citations_known_cite_standard ON moml_citations.citations_known (cite_standard);

CREATE INDEX idx_citations_known_case_id_er ON moml_citations.citations_known (case_id_er);

CREATE INDEX idx_citations_known_case_id_cap ON moml_citations.citations_known (case_id_cap);

CREATE INDEX idx_citations_known_moml_treatise_page ON moml_citations.citations_known (moml_treatise, moml_page);

-- migrate:down
SET ROLE = law_admin;

ALTER TABLE moml_citations.citations_known
DROP CONSTRAINT IF EXISTS pk_citations_known_id;

DROP INDEX IF EXISTS moml_citations.idx_citations_known_cite_alternative;

DROP INDEX IF EXISTS moml_citations.idx_citations_known_cite_standard;

DROP INDEX IF EXISTS moml_citations.idx_citations_known_case_id_er;

DROP INDEX IF EXISTS moml_citations.idx_citations_known_case_id_cap;

DROP INDEX IF EXISTS moml_citations.idx_citations_known_moml_treatise_page;
