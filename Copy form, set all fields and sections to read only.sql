USE [Cuesta];

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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 


/********************** Changes go HERE **************************************************/

DECLARE @UserId int = (
SELECT Id FROM [User]
WHERE FirstName = 'Support'							--get user id
AND Username = 'SupportAdmin@CurriQunet.com'
)

EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 54, @Templatename = 'Program Deactivation' --copy new Program and Create Program Modification

DECLARE @Templateid2 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new program modification
DECLARE @Templatetypeid int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of program modifcation

EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Templateid2 , @metaTemplateTypeId = @Templatetypeid -- activates the new template

DECLARE @OldTT int = (
SELECT MetaTemplateTypeId 
FROM ProposalType
WHERE Title = 'Program (3. Deactivate Proposal)'		------Gets TemplateType currently being used and stores it for later
AND Active = 1
)

UPDATE ProposalType
SET MetaTemplateTypeId = @Templatetypeid
	WHERE Title = 'Program (3. Deactivate Proposal)'		------Sets program modification to be used now in the correct spot
	AND Active = 1

DECLARE @TABLE Table (Id int)
INSERT INTO @TABLE
SELECT MetaSelectedFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt ON mss2.MetaTemplateId = mt.MetaTemplateId
WHERE mt.MetaTemplateId = @Templateid2

UPDATE MetaSelectedField
SET ReadOnly = 1
, IsRequired = 0
WHERE MetaSelectedFieldId in (SELECT Id FROM @TABLE)

DECLARE @TABLE2 TABLE (Id int)
INSERT INTO @TABLE2
SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection as mss
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt ON mss2.MetaTemplateId = mt.MetaTemplateId
WHERE mt.MetaTemplateId = @Templateid2

UPDATE MetaSelectedSection
SET ReadOnly =1
WHERE MetaSelectedSectionId in (SELECT Id FROM @TABLE2)


/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()


while exists(select top 1 1 from @templateId)
begin
    declare @TID int = (select top 1 * from @templateId)
    exec upUpdateEntitySectionSummary @entitytypeid = 6,@templateid = @TID		--badge update
    delete @templateId
    where id = @TID
end



--commit
--rollback