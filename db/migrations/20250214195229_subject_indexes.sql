-- migrate:up
SET ROLE = law_admin;
CREATE INDEX IF NOT EXISTS idx_book_subject_psmid_subject ON moml.book_subject(psmid, subject);
CREATE INDEX IF NOT EXISTS idx_book_info_psmid ON moml.book_info(psmid);

-- migrate:down
SET ROLE = law_admin;
DROP INDEX IF EXISTS moml.idx_book_subject_psmid_subject;
DROP INDEX IF EXISTS moml.idx_book_info_psmid;
