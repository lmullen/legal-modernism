SELECT 
c.cites_from AS from_id, f.cites AS from_case_name, f.jurisdiction_name AS from_jurisdiction, f.jurisdiction_id AS from_jurisdiction_id, f.decision_year AS from_year, f.court_name_abbreviation AS from_court, f.court_id AS from_court_id,
c.cites_to AS to_id, t.cites AS to_case_name, t.jurisdiction_name AS to_jurisdiction, t.jurisdiction_id AS to_jurisdiction_id, t.decision_year AS to_year, t.court_name_abbreviation AS to_court, t.court_id AS to_court_id
FROM cap_citations.citations c
LEFT JOIN cap_citations.metadata f ON c.cites_from = f.id
LEFT JOIN cap_citations.metadata t ON c.cites_to = t.id