USE [];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-';
DECLARE @Comments nvarchar(Max) = 
	'Generic Maverick Conversion';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
For a complete list run the following query

Select * from history.ScriptType
*/

SELECT
 @@servername AS 'Server Name' 
,DB_NAME() AS 'Database Name'
,@JiraTicketNumber as 'Jira Ticket Number';

SET XACT_ABORT ON
BEGIN TRAN

If exists(select top 1 1 from History.ScriptsRunOnDatabase where TicketNumber = @JiraTicketNumber and Developer = @Developer and Comments = @Comments)
	THROW 51000, 'This Script has already been run', 1;

INSERT INTO History.ScriptsRunOnDatabase
(TicketNumber,Developer,Comments,ScriptTypeId)
VALUES
(@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId); 

/*--------------------------------------------------------------------
Please do not alter the script above this comment  except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing somehting 
		 that is against meta best practices but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql

-----------------Script details go below this line------------------*/
DECLARE @ClientId int = (SELECT Id FROM Client WHERE Active = 1)
DECLARE @Active int = (SELECT Id FROM StatusAlias WHERE Title = 'Active')

Merge MetaSelectedFieldAttribute as Target 
	using 
		(
			select 'helptext' as Name, msfa1.Value, msfa1.MetaSelectedFieldId  
	from MetaSelectedFieldAttribute msfa1
	where Name = 'subtext'
	And Not Exists 
	(
	select msfa2.MetaSelectedFieldId 
	from MetaSelectedFieldAttribute msfa2
	where Name = 'HelpText'
		And msfa2.MetaSelectedFieldId
		= msfa1.MetaSelectedFieldId 
	)
) as Source (Name,Value, MetaSelectedFieldId)
	On source.Name = Target.Name
	And source.Value = Target.Value
	And source.MetaSelectedFieldId = Target.MetaSelectedFieldId
When not matched then 
INSERT  (Name,Value, MetaSelectedFieldId)
values  (source.Name,source.Value, source.MetaSelectedFieldId);

UPDATE MetaSelectedField
SET IsRequired = 0
WHERE MetaSelectedFieldId in (
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE 
(MetaPresentationTypeId = 5
or 
(MetaPresentationTypeId = 1 and FieldTypeId = 5)
or MetaPresentationTypeId = 103)
AND IsRequired = 1
)

UPDATE msf
SET DisplayName = dbo.Format_RemoveAccents(dbo.stripHtml(DisplayName))
from MetaSelectedField msf
    inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
    inner join MetaSelectedSection mss2 on mss2.MetaSelectedSectionId = mss.MetaSelectedSection_MetaSelectedSectionId
    inner join MetaTemplate mt on mt.MetaTemplateId = mss.MetaTemplateId
    inner join MetaTemplateType mtt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    inner join EntityType et on et.Id = mtt.EntityTypeId
where msf.DisplayName <> dbo.Format_RemoveAccents(dbo.stripHtml(msf.DisplayName))
	and msf.MetaAvailableFieldId is not null
	and mtt.IsPresentationView = 0
	and mt.Active = 1
	and mtt.Active = 1

UPDATE mss
SET SectionName = dbo.Format_RemoveAccents(dbo.stripHtml(mss.SectionName))
from MetaSelectedSection mss
    inner join MetaTemplate mt on mt.MetaTemplateId = mss.MetaTemplateId
    inner join MetaTemplateType mtt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    inner join EntityType et on et.Id = mtt.EntityTypeId
where mss.SectionName <> dbo.Format_RemoveAccents(dbo.stripHtml(mss.SectionName))
	and mtt.IsPresentationView = 0
	and mt.Active = 1
	and mtt.Active = 1

	declare @currentSettings NVARCHAR(max) = (
    select replace(replace(JSON_Query(Configurations, '$[2].settings'), '[',''),']','')   
    from Config.ClientSetting
)
set @currentSettings = @currentSettings + ',{
    "AccessLevel": "curriqunet",
    "DataType": "bool",
    "Description": "This will enable the Contributors flyout feature on Maverick",
    "Default": false,
    "Label": "Enable Maverick Co-Contributors",
    "Name": "EnableFlyoutCoContributors",
    "Value": true,
    "Active": true
}'
set @currentSettings = CONCAT('[',@currentSettings,']')
update Config.ClientSetting
set Configurations = JSON_MODIFY(Configurations, '$[2].settings',JSON_QUERY(@currentSettings))

INSERT INTO CourseContributorMetaSelectedSection
(CourseContributorId, MetaSelectedSectionId, CreatedDate)
SELECT cc.Id, mss.MetaSelectedSectionId, GETDATE() FROM CourseContributor AS cc
INNER JOIN Course AS c on cc.CourseId = c.Id
INNER JOIN MetaTemplate As mt on c.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL

INSERT INTO ProgramContributorMetaSelectedSection
(ProgramContributorId, MetaSelectedSectionId)
SELECT pc.Id, mss.MetaSelectedSectionId FROM ProgramContributor As pc
INNER JOIN Program AS p on pc.ProgramId = p.Id
INNER JOIN MetaTemplate As mt on p.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL

INSERT INTO ModuleContributorMetaSelectedSection
(ModuleContributorId, MetaSelectedSectionId, CreatedDate)
SELECT mc.Id, mss.MetaSelectedSectionId, GETDATE() FROM ModuleContributor AS mc
INNER JOIN Module AS m on mc.ModuleId = m.Id
INNER JOIN MetaTemplate As mt on m.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL

DECLARE @CoCo TABLE (SecId int, FieldId int)
INSERT INTO @CoCo
SELECT mss.MetaSelectedSectionId, msf.MetaSelectedFieldId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mss.MetaBaseSchemaId in (210, 326,1456)

UPDATE MetaSelectedSection
SET MetaBaseSchemaId = NULL
, MetaSectionTypeId = 1
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @CoCo
)

UPDATE MetaSelectedField
SET DisplayName = 'Open the Form Properties to select co-contributors and assign permissions.'
, MetaAvailableFieldId = NULL
, IsRequired = 0
, MaxCharacters = NULL
, DefaultDisplayType = 'StaticText'
, MetaPresentationTypeId = 35
, Width = NULL
, WidthUnit = 0
, Height = NULL
, HeightUnit = 0
, FieldTypeId = 2
, LabelStyleId = NULL
, LabelVisible = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @CoCo
)

--DECLARE @titleFieldsMAF integers
--Insert into @titleFieldsMAF
--SELECT
--	maf.MetaAvailableFieldId
--FROM ListItemType lit
--	Inner join MetaAvailableField maf on maf.TableName = lit.ListItemTableName
--		and maf.ColumnName = lit.ListItemTitleColumn

--DECLARE @RTE INTEGERS
--INSERT INTO @RTE
--SELECT 
--	msf.MetaAvailableFieldId
--FROM MetaSelectedField msf
--	Inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
--	Inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
--	Inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	Inner join MetaPresentationType mpt on msf.MetaPresentationTypeId = mpt.Id
--	Inner join @titleFieldsMAF tfmaf on msf.MetaAvailableFieldId = tfmaf.Id
--WHERE mpt.Id in (25,26)

--UPDATE MetaSelectedField
--SET DefaultDisplayType = 'TextArea'
--, MetaPresentationTypeId = 17
--WHERE MetaAvailableFieldId in (
--	SELECT Id FROM @RTE
--)

--DECLARE @TableName NVARCHAR(128);
--DECLARE @ColumnName NVARCHAR(128);
--DECLARE @sql NVARCHAR(MAX);

--DECLARE table_cursor CURSOR FOR
--SELECT TableName, ColumnName
--FROM MetaAvailableField
--WHERE MetaAvailableFieldId IN (SELECT Id FROM @RTE);

--OPEN table_cursor;
--FETCH NEXT FROM table_cursor INTO @TableName, @ColumnName;

--WHILE @@FETCH_STATUS = 0
--BEGIN
--    SET @sql = 'UPDATE ' + QUOTENAME(@TableName) + 
--               ' SET ' + QUOTENAME(@ColumnName) + ' =  dbo.Format_RemoveAccents(dbo.stripHtml(' + QUOTENAME(@ColumnName) +'))'+ -- Change 'New Value' to the desired value
--               ' WHERE' + QUOTENAME(@ColumnName) + ' <> dbo.Format_RemoveAccents(dbo.stripHtml('+ QUOTENAME(@ColumnName) +'))';
    
--    EXEC sp_executesql @sql;
    
--    FETCH NEXT FROM table_cursor INTO @TableName, @ColumnName;
--END;

--CLOSE table_cursor;
--DEALLOCATE table_cursor;

Drop table if exists #Results
;with ProgramSequenceQuery as (
	Select MetaSelectedSectionId, MetaTemplateId, MetaSelectedSection_MetaSelectedSectionId as TabSection, 'ProgramSequence' as TableName
	from MetaSelectedSection 
	where MetaBaseSchemaId = 857 --ProgramSequence
), ProgramCourseQuery as ( 
	Select mss1.MetaSelectedSectionId, mss1.MetaTemplateId,
	mss2.MetaSelectedSection_MetaSelectedSectionId as TabSection, 'ProgramCourse' as TableName
	from MetaSelectedSection mss1
	inner join MetaSelectedSection mss2 on mss2.MetaSelectedSectionId
	= mss1.MetaSelectedSection_MetaSelectedSectionId
		And mss1.MetaBaseSchemaId = 164 --ProgramCourse
		And mss1.MetaSectionTypeId in (31,500)
), OutcomeMatchingQuery as ( 
	Select MetaSelectedSectionId, MetaTemplateId, MetaSelectedSection_MetaSelectedSectionId as TabSection, 'ProgramOutcomeMatching' as TableName
	from MetaSelectedSection
	Where MetaBaseSchemaId	= 204 --ProgramOutcomeMatching
) Select 	ps.MetaTemplateId,
		ps.MetaSelectedSectionId as ProgramSequenceSectionId
		,ps.TabSection as ProgramSequenceTabId
		,pc.MetaSelectedSectionId as ProgramCourseSectionId
		,pc.TabSection as ProgramCourseTabId
		,om.MetaSelectedSectionId as OutcomeMatchingSectionId
		,om.TabSection as OutcomeMatchingTabId
	into #Results
from ProgramSequenceQuery ps
	left join ProgramCourseQuery pc 
		on pc.MetaTemplateId = ps.MetaTemplateId
	left join OutcomeMatchingQuery om 
		on om.MetaTemplateId = ps.MetaTemplateId
;Merge MetaSelectedSectionAttribute as Target
	using(
				select 'triggersectionrefresh' as Name, 
								ProgramCourseTabId as Value,
								ProgramSequenceSectionId as MetaSelectedSectionId 
				from #Results r
				inner join metaSelectedField msf
					on msf.MetaSelectedSectionId = r.ProgramSequenceSectionId
				inner join MetaAvailableField maf 
					on maf.MetaAvailableFieldId = msf.MetaAvailableFieldId
						and ColumnName like '%Subject%Id%'
				Where ProgramCourseTabId is not null
				Union
				select 'triggersectionrefresh' as Name, 
								OutcomeMatchingTabId as Value,
								ProgramSequenceSectionId as MetaSelectedSectionId 
				from #Results r
				Where OutcomeMatchingTabId is not null
) as Source (Name,Value,MetaSelectedSectionId)
on Source.Name = Target.Name and
	 Source.Value = Target.Value and
	 Source.MetaSelectedSectionId = Target.MetaSelectedSectionId
When not Matched THEN
Insert  (Name,Value,MetaSelectedSectionId)
values  (Source.Name,Source.Value,Source.MetaSelectedSectionId);

UPDATE ListItemType
SET ListItemTitleColumn = REPLACE(ListItemTitleColumn, ' ', '')
WHERE ListItemTitleColumn like '% %'

DECLARE @AllowReactivation INT;

SELECT @AllowReactivation = AllowReactivation
FROM Config.ClientSetting;

IF @AllowReactivation = 1
BEGIN
    UPDATE ProposalType
    SET AllowReactivation = 1
    WHERE ProcessActionTypeId = 3
      AND Active = 1
      AND EntityTypeId IN (
          SELECT EntityTypeId 
          FROM ProposalType 
          WHERE AllowReactivation = 1
      );
END

DELETE FROM MetaSelectedSectionSetting
WHERE IsRequired = 0

DECLARE @table nvarchar(100) = 'moduleextension02',               -- Enter the Name of the Table
		@EntityTypeId int = 6;                                    -- EntityTypeId 1 = Course, 2 = Program, 6 = Module


DECLARE @ModuleOPEN INTEGERS
INSERT INTO @ModuleOPEN
SELECT 
		maf.MetaAvailableFieldId
FROM sys.columns c
INNER JOIN sys.objects o ON c.object_id = o.object_id
INNER JOIN sys.types t ON c.system_type_id = t.system_type_id
LEFT JOIN MetaAvailableField maf 
	ON o.Name = maf.TableName
	AND c.Name = maf.ColumnName
left join MetaAvailableGroup mag on mag.id = maf.MetaAvailableGroupId
WHERE o.name = @table
AND t.Name <> 'sysname'
AND t.Name = 'decimal'
and MetaAvailableFieldId is not null
AND NOT EXISTS (SELECT 1
					FROM MetaSelectedField msf
						INNER JOIN MetaSelectedSection mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
					WHERE msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
					AND mss.MetaTemplateId in (select mt.MetaTemplateId
												from MetaTemplate mt
												inner join MetaTemplateType mtt on mt.metaTemplateTypeId = mtt.metaTemplateTypeId
												where
												mt.startDate is not NULL
												and mt.DeletedDate is NULL
												and mt.enddate is null
												and mt.active = 1
												and Mtt.entityTypeId = @EntityTypeId
												and mtt.active = 1
												)
												 )

DECLARE @OldCalc TABLE (FieldId int, EntityTypeId int)
INSERT INTO @OldCalc
SELECT 
	msf.MetaSelectedFieldId,
	mtt.EntityTypeId
FROM MetaSelectedField msf
	Inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	Inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
	Inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	Inner join MetaPresentationType mpt on msf.MetaPresentationTypeId = mpt.Id
WHERE MetaAvailableFieldId is null
	and exists (
		SELECT 1 FROM MetaFieldFormula mff 
		where mff.MetaSelectedFieldId = msf.MetaSelectedFieldId
	)
	and (mt.MetaTemplateId in (
	SELECT MetaTemplateId FROM Course
	UNION
	SELECT MetaTemplateId FROM Program
	UNION
	SELECT MetaTemplateId FROM Module
	)
	or mt.Active = 1)

while exists(select top 1 FieldId from @OldCalc WHERE EntityTypeId = 6)
begin
		declare @Id int = (SELECT TOP 1 FieldId FROM @OldCalc WHERE EntityTypeId = 6)
    declare @TID int = (select top 1 1 from @ModuleOPEN)

		UPDATE MetaSelectedField
		SET MetaAvailableFieldId = @TID
		, MetaPresentationTypeId = 1
		, Height = 24
		, FieldTypeId = 1
		, ReadOnly = 1
		WHERE MetaSelectedFieldId = @Id

    delete @OldCalc
		WHERE FieldId = @Id
		delete @ModuleOPEN
		WHERE Id = @TID
end

SET @Table = 'CourseDescription'
SET @EntityTypeId = 1

DECLARE @CourseOPEN INTEGERS
INSERT INTO @CourseOPEN
SELECT 
		maf.MetaAvailableFieldId
FROM sys.columns c
INNER JOIN sys.objects o ON c.object_id = o.object_id
INNER JOIN sys.types t ON c.system_type_id = t.system_type_id
LEFT JOIN MetaAvailableField maf 
	ON o.Name = maf.TableName
	AND c.Name = maf.ColumnName
left join MetaAvailableGroup mag on mag.id = maf.MetaAvailableGroupId
WHERE o.name = @table
AND t.Name <> 'sysname'
AND t.Name = 'decimal'
and MetaAvailableFieldId is not null
AND NOT EXISTS (SELECT 1
					FROM MetaSelectedField msf
						INNER JOIN MetaSelectedSection mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
					WHERE msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
					AND mss.MetaTemplateId in (select mt.MetaTemplateId
												from MetaTemplate mt
												inner join MetaTemplateType mtt on mt.metaTemplateTypeId = mtt.metaTemplateTypeId
												where
												mt.startDate is not NULL
												and mt.DeletedDate is NULL
												and mt.enddate is null
												and mt.active = 1
												and Mtt.entityTypeId = @EntityTypeId
												and mtt.active = 1
												)
												 )

while exists(select top 1 FieldId from @OldCalc WHERE EntityTypeId = 1)
begin
		declare @Id2 int = (SELECT TOP 1 FieldId FROM @OldCalc WHERE EntityTypeId = 1)
    declare @TID2 int = (select top 1 1 from @CourseOPEN)

		UPDATE MetaSelectedField
		SET MetaAvailableFieldId = @TID2
		, MetaPresentationTypeId = 1
		, Height = 24
		, FieldTypeId = 1
		, ReadOnly = 1
		WHERE MetaSelectedFieldId = @Id2

    delete @OldCalc
		WHERE FieldId = @Id2
		delete @CourseOPEN
		WHERE Id = @TID2
end

SET @Table = 'GenericDecimal'
SET @EntityTypeId = 2

DECLARE @ProgramOPEN INTEGERS
INSERT INTO @ProgramOPEN
SELECT 
		maf.MetaAvailableFieldId
FROM sys.columns c
INNER JOIN sys.objects o ON c.object_id = o.object_id
INNER JOIN sys.types t ON c.system_type_id = t.system_type_id
LEFT JOIN MetaAvailableField maf 
	ON o.Name = maf.TableName
	AND c.Name = maf.ColumnName
left join MetaAvailableGroup mag on mag.id = maf.MetaAvailableGroupId
WHERE o.name = @table
AND t.Name <> 'sysname'
AND t.Name = 'decimal'
and MetaAvailableFieldId is not null
AND NOT EXISTS (SELECT 1
					FROM MetaSelectedField msf
						INNER JOIN MetaSelectedSection mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
					WHERE msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
					AND mss.MetaTemplateId in (select mt.MetaTemplateId
												from MetaTemplate mt
												inner join MetaTemplateType mtt on mt.metaTemplateTypeId = mtt.metaTemplateTypeId
												where
												mt.startDate is not NULL
												and mt.DeletedDate is NULL
												and mt.enddate is null
												and mt.active = 1
												and Mtt.entityTypeId = @EntityTypeId
												and mtt.active = 1
												)
												 )

while exists(select top 1 FieldId from @OldCalc WHERE EntityTypeId = 2)
begin
		declare @Id3 int = (SELECT TOP 1 FieldId FROM @OldCalc WHERE EntityTypeId = 2)
    declare @TID3 int = (select top 1 1 from @ProgramOPEN)

		UPDATE MetaSelectedField
		SET MetaAvailableFieldId = @TID3
		, MetaPresentationTypeId = 1
		, Height = 24
		, FieldTypeId = 1
		, ReadOnly = 1
		WHERE MetaSelectedFieldId = @Id3

    delete @OldCalc
		WHERE FieldId = @Id3
		delete @ProgramOPEN
		WHERE Id = @TID3
end

declare @templateId integers
insert into @templateId
	select 
	mt.MetaTemplateId
	from MetaTemplateType mtt
	inner join MetaTemplate mt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
	where mtt.EntityTypeId = 1
	and mtt.IsPresentationView = 0
	and mtt.ClientId = @clientId

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);

insert into @FieldCriteria (TableName, ColumnName)
values
('Course', 'CourseNumber'),
('Course', 'SubjectId')

declare @tabs table (
	tabId int primary key,
	TemplateId int
);

insert into @tabs(tabId,TemplateId)
select Distinct
	mss.MetaSelectedSection_MetaSelectedSectionId,
	mss.MetaTemplateId 
	from MetaTemplate mt
	inner join MetaSelectedSection mss on mt.MetaTemplateId = mss.MetaTemplateId
	inner join MetaSelectedField msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	inner join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
	inner join @FieldCriteria rfc	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName) 
	where mt.MetaTemplateId  in (select * from @templateId)
	and msf.ReadOnly  <> 1

Declare @StandardSQL nvarchar(max) =CONCAT(
'SELECT 
	Case
		WHEN c.StatusAliasId =', @Active, ' THEN 1
		when exists (
			select top 1 1
			from dbo.Course c2
				inner join ProposalType pt2 on c2.ProposalTypeId = pt2.Id
			where c2.ClientId = c.ClientId
				and c2.SubjectId = c.SubjectId
				and LTRIM(RTRIM(c2.CourseNumber)) = LTRIM(RTrim(c.CourseNumber))
				and pt2.ClientEntityTypeId = pt.ClientEntityTypeId
				and c2.BaseCourseId <> c.BaseCourseId
				and c2.Active = 1
		) 
		then 0	
		else 1
	END As ISValid
FROM Course c
	inner join ProposalType pt on c.ProposalTypeId = pt.Id
WHERE c.Id = @entityId');

Insert into MetaSqlStatement (SqlStatement, SqlStatementTypeId)
Values
(@StandardSQL, 1);

Declare @newSqlStatmentid int = scope_Identity();

IF exists ( SELECT 1 from MetaControlAttribute where MetaSelectedSectionId in (Select tabid from @tabs))
	THROW 51000, 'There is already tab level validation on one of the tabs',1;

Insert into MetaControlAttribute (Name,Description,MetaControlAttributeTypeId,CustomMessage,MetaSqlStatementId, MetaSelectedSectionId)
Select
	'Course Code Validation - Standard', 
	'Course Code Validation - Standard',
	6,
	'A course with this course number and subject code already exisits.',
	@newSqlStatmentid,
	tabId
FRom @tabs

UPDATE Config.ClientSetting
SET Configurations = JSON_MODIFY(Configurations, 'append $[4].settings', JSON_QUERY('{"AccessLevel": "curriqunet","DataType": "bool","Description": "","Default": "","Label": "Open Proposals in a New Tab","Name": "OpenProposalStrategy","Value": true,"Active": true}'))

DECLARE @EmptySections INTEGERS
INSERT INTO @EmptySections
SELECT MetaSelectedSectionId FROM MetaSelectedSection
WHERE MetaSelectedSectionId not in (
	SELECT MetaSelectedSection_MetaSelectedSectionId FROM MetaSelectedSection WHERE MetaSelectedSection_MetaSelectedSectionId IS NOT NULL
	UNION
	SELECT MetaSelectedSectionId FROM MetaSelectedField
)

DELETE FROM CourseSectionSummary WHERE MetaSelectedSectionId in (
	SELECT id FROM @EmptySections
)

DELETE FROM MetaSelectedSectionAttribute WHERE MetaSelectedSectionId in (
	SELECT id FROM @EmptySections
)

DELETE FROM MetaDisplaySubscriber WHERE MetaSelectedSectionId in (
	SELECT id FROM @EmptySections
)

DELETE FROM CourseContributorMetaSelectedSection WHERE MetaSelectedSectionId in (
	SELECT Id FROM @EmptySections
)

DELETE FROM MetaSelectedSectionRolePermission WHERE MetaSelectedSectionId in (
	SELECT Id FROM @EmptySections
)

DELETE FROM MetaSelectedSection WHERE MetaSelectedSectionId in (
	SELECT Id FROM @EmptySections
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()

exec EntityExpand

COMMIT