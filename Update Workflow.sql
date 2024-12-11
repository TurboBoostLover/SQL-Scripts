USE evc;

/*
Commit

                          Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-';
DECLARE @Comments nvarchar(Max) = '';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 1;
/*  
Default for @ScriptTypeId on this script is 1 for Support.  
For a complete list of ScriptTypes run the following query

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

/*
Please do not alter the script above this comment except to set
the Use statement and the variables. 

Notes:  
1.   In comments put a brief description of what the script does.
     You can also use this to document if we are doing something 
     that is against meta best practices, but the client is 
     insisting on, and that the client has been made aware of 
     the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the 
		 word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql
-----------------Script details go below this comment------------------
*/
DECLARE @propId INTEGERS;
DECLARE @uId INT = (SELECT Id FROM [User] WHERE Email = 'SupportAdmin@CurriQunet.com');
DECLARE @pId INT = (SELECT Id FROM Process WHERE Title = '');	--Name of workflow

DECLARE @MetaTemplates TABLE (MT INT)
INSERT INTO @MetaTemplates
SELECT MetaTemplateId FROM MetaTemplateType AS MTT
INNER JOIN MetaTemplate AS MT
ON MTT.MetaTemplateTypeId = MT.MetaTemplateTypeId
WHERE MTT.EntityTypeId = 6
AND MTT.Active = 1
AND TemplateName = '' -- Add Template Name


DECLARE @RealId TABLE (MS int)
INSERT INTO @RealId

	--SELECT Id FROM Module 
	--WHERE (MetaTemplateId = 879 or MetaTemplateId = 862)
	--AND ProcessId <> 1462
	--AND Active = 1


	SELECT * FROM Module
	WHERE MetaTemplateId in (SELECT * FROM @MetaTemplates)
	AND Active = 1
	AND ProcessId <> @pId

INSERT INTO @propId(Id)
SELECT ProposalId
FROM Module AS m
WHERE m.Id IN (SELECT * FROM @RealId)

UPDATE Module 
SET ProcessId = @pId
WHERE Module.Id IN(SELECT * FROM @RealId);

EXEC upRemoveProposal @proposalIds = @propId, @userId = @uId, @active = 1;