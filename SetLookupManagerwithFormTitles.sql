USE [nukz];

--commit
--Rollback

SELECT
 @@servername AS 'Server Name' 
,DB_NAME() AS 'Database Name'

SET XACT_ABORT ON
BEGIN TRAN

DELETE FROM ClientLookupType

----------------------Queries Go Below this Line--------------------------------
declare @clientId int = 1

declare @tempLookups table (Id int identity(1,1), Name varchar(500),LookupId int)

insert into @tempLookups
(Name,LookupId)
select replace(Title,' ','')+ 'id',id
from LookupType
WHERE id NOT IN (54, 79)

declare @lookupToAdd table (Id int identity(1,1),LookupTypeId int ,CustomTitle varchar(500))

declare @start int = 1
declare @end int = (select max(id) + 1 from @tempLookups)

while @start < @end
BEGIN

    declare @displayname varchar(500) = (select Name from @tempLookups where Id = @start)
    declare @actualName varchar(500);
    declare @currentTypeId int = (select LookupId from @tempLookups where Id = @start)

    if exists (
        select top 1 msf.DisplayName
        from MetaAvailableField maf
	        inner join MetaSelectedField msf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
					INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
					INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
					INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
        where maf.ColumnName = @displayname
				and mtt.Active = 1
				and mt.Active = 1
    )
    begin
        set @actualName =  (select top 1 msf.DisplayName
        from MetaAvailableField maf
	        inner join MetaSelectedField msf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
					INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
					INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
					INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
        where maf.ColumnName = @displayname
				and mtt.Active = 1
				and mt.Active = 1
        and maf.ColumnName =@displayname)

        insert into @lookupToAdd
        (LookupTypeId,CustomTitle)
        VALUES
        (@currentTypeId,@actualName)

    end 

set @start = @start + 1

END

insert into ClientLookupType
(ClientId,LookupTypeId,CustomTitle)
output INSERTED.*
select 
    @clientId
    ,LookupTypeId
    ,Case   
        WHEN LookupTypeId = 18 then 'Course Date Type'
        WHEN LookupTypeId = 41 then 'Program Date Type'
    ELSE CustomTitle
    END
from @lookupToAdd

--commit
--rollback