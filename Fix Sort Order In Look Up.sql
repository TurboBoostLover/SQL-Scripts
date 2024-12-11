update mq 
set SortOrder = sorted.rownum 
output inserted.*
from MinimumQualification mq
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from MinimumQualification 
) sorted on mq.Id = sorted.Id