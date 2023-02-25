-- number of "citations" found
select count(*) from output.moml_citations;

-- number of "citations" not whitelisted
select sum(n) from output.top_reporters_not_whitelisted;

-- number of "cases" linked
select count(*) from linking.moml_04_cap_case where "case" is not null;

-- number of CAP case IDs fount
select count(distinct "case") from linking.moml_04_cap_case;

-- number of cases in cap
select count(*) from cap.cases WHERE decision_year < 1920;

-- number of citations linked to cases 
select count(*) from linking.moml_05_moml_to_cap;

-- number of MOML pages
select count(*) from moml.page;