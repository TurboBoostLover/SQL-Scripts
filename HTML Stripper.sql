USE [];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = '';
DECLARE @Comments nvarchar(Max) = 
	'';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 1; /*  Default 1 is Support,  
For a complete list run the following query

Select * from history.ScriptType
*/

SELECT
 @@servername AS 'Server Name' 
,DB_NAME() AS 'Database Name'
,@JiraTicketNumber as 'Jira Ticket Number';

SET XACT_ABORT ON
BEGIN TRAN

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
Declare @clientId int =2, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId


declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('Cover', 'Course', 'Description','Update')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedField
SET DefaultDisplayType = 'Textarea'
, MetaPresentationTypeId = 17
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields)

DECLARE @TABLE Table (Id int, Description NVARCHAR(MAX), Descriptionnm NVARCHAR(MAX))
INSERT INTO @TABLE
SELECT Id ,
CAST(dbo.stripHtml (dbo.regex_replace(Description, N'['+nchar(8203)+N']', N'')) AS NVARCHAR(MAX)),
Description
FROM Course
WHERE ClientId = 2
AND Active = 1


-- Replacing all known and other common instances of escaped characters in the Description output
UPDATE @TABLE SET Description = replace(Description, '&rsquo;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&#39;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&nbsp;' collate Latin1_General_CS_AS, ' '  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&quot;' collate Latin1_General_CS_AS, '"'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&euro;' collate Latin1_General_CS_AS, '€'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&lt;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&gt;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&oelig;' collate Latin1_General_CS_AS, 'oe'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&copy;' collate Latin1_General_CS_AS, '©'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&laquo;' collate Latin1_General_CS_AS, '«'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&reg;' collate Latin1_General_CS_AS, '®'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&plusmn;' collate Latin1_General_CS_AS, '±'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&sup2;' collate Latin1_General_CS_AS, '²'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&sup3;' collate Latin1_General_CS_AS, '³'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&micro;' collate Latin1_General_CS_AS, 'µ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&middot;' collate Latin1_General_CS_AS, '·'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&ordm;' collate Latin1_General_CS_AS, 'º'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&raquo;' collate Latin1_General_CS_AS, '»'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&frac14;' collate Latin1_General_CS_AS, '¼'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&frac12;' collate Latin1_General_CS_AS, '½'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&frac34;' collate Latin1_General_CS_AS, '¾'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&Aelig' collate Latin1_General_CS_AS, 'Æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&Ccedil;' collate Latin1_General_CS_AS, 'Ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&Egrave;' collate Latin1_General_CS_AS, 'È'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&Eacute;' collate Latin1_General_CS_AS, 'É'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&Ecirc;' collate Latin1_General_CS_AS, 'Ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&Ouml;' collate Latin1_General_CS_AS, 'Ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&agrave;' collate Latin1_General_CS_AS, 'à'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&acirc;' collate Latin1_General_CS_AS, 'â'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&auml;' collate Latin1_General_CS_AS, 'ä'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&aelig;' collate Latin1_General_CS_AS, 'æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&ccedil;' collate Latin1_General_CS_AS, 'ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&egrave;' collate Latin1_General_CS_AS, 'è'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&eacute;' collate Latin1_General_CS_AS, 'é'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&ecirc;' collate Latin1_General_CS_AS, 'ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&euml;' collate Latin1_General_CS_AS, 'ë'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&icirc;' collate Latin1_General_CS_AS, 'î'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&ocirc;' collate Latin1_General_CS_AS, 'ô'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&ouml;' collate Latin1_General_CS_AS, 'ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&divide;' collate Latin1_General_CS_AS, '÷'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&oslash;' collate Latin1_General_CS_AS, 'ø'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&ugrave;' collate Latin1_General_CS_AS, 'ù'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&uacute;' collate Latin1_General_CS_AS, 'ú'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&ucirc;' collate Latin1_General_CS_AS, 'û'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&uuml;' collate Latin1_General_CS_AS, 'ü'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&lsaquo;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, '&rsaquo;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)

UPDATE Course
SET Description = t.Description
from Course AS c
INNER JOIN @TABLE AS t ON c.Id = t.Id


/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

commit
--rollback