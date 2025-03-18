-- migrate:up
SET ROLE = law_admin;

ALTER TABLE moml_citations.citations_known
ADD CONSTRAINT citations_known_case_id_cap_fkey FOREIGN KEY (case_id_cap) REFERENCES cap.cases (id);

ALTER TABLE moml_citations.citations_known
ADD CONSTRAINT citations_known_case_id_er_fkey FOREIGN KEY (case_id_er) REFERENCES english_reports.cases (id);

-- migrate:down
SET ROLE = law_admin;

ALTER TABLE moml_citations.citations_known
DROP CONSTRAINT citations_known_case_id_cap_fkey;

ALTER TABLE moml_citations.citations_known
DROP CONSTRAINT citations_known_case_id_er_fkey;
