-- Count all of the rows
WITH tbl AS (
	SELECT
		table_schema,
		TABLE_NAME
	FROM
		information_schema.tables
	WHERE
		TABLE_NAME NOT LIKE 'pg_%'
)
SELECT
	table_schema,
	TABLE_NAME,
	(xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, TABLE_NAME), FALSE, TRUE, '')))[1]::text::int AS rows_n
FROM
	tbl
ORDER BY
	rows_n DESC;
	
	
-- Quicker count of live tuples
SELECT schemaname,relname,n_live_tup 
  FROM pg_stat_user_tables 
ORDER BY n_live_tup DESC;

