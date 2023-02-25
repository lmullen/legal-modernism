select bibliographicid, count(*) as n
from moml.book_info
group by bibliographicid
having count(*) > 1
order by n desc;

select bi.bibliographicid, bi.psmid, bi.year, bc.currentvolume, bc.displaytitle
from moml.book_info bi
left join moml.book_citation bc on bi.psmid = bc.psmid
where bi.bibliographicid = 'CTRG95-B1363'
order by year, currentvolume::int;