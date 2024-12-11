/**************************************/
/* Quick script to translate a column */
/* identifier to it's backing store   */
/* By Stephen Tigner                  */
/**************************************/

--Replace id5aa6a4b4cbe640bdbee1efd2ef569fba with the column alias you're looking for
select *
from MetaColumnIdentifiers mci
where lower(replace(('Id' + cast(mci.ColumnId as nvarchar(max))), '-', '')) = 'id252f48e6345f44319fe296709e6faf07'

