-- migrate:up
SET ROLE = law_admin;
CREATE SCHEMA IF NOT EXISTS predictor;

-- migrate:down
SET ROLE = law_admin;
DROP SCHEMA IF EXISTS predictor;
