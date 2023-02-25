select
from_id, from_case_name, from_jurisdiction, from_year,
to_id, to_case_name, to_jurisdiction, to_year
FROM cap_to_cap_citations
WHERE from_year < 1930
