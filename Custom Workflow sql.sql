USE [];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-';
DECLARE @Comments nvarchar(Max) = 
	'Condtional Step in workflow';
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
INSERT INTO WorkflowCondition
(Title, Description, ConditionSQL, CommandTypeId, Active)
VALUES
('Set up workflow so someone isnt included', '', '
/*
			1: Not Included
			2: Required
			3: Optional
		*/ 
		select c.Id
			, case
				when c.SubjectId in (10365, 10368, 10417, 10357) /* 10365 FAC, 10368 FTEC, 10417 WFT, 10357 EMT */
				 then 2
				else 1
			end as StepTypeId
		from ProcessLevelActionHistory plah
			left join Course c on plah.ProposalId = c.ProposalId
		where plah.Id = @processLevelActionHistoryId;', 1, 1)

DECLARE @ID int = SCOPE_IDENTITY()

UPDATE Step
SET WorkflowConditionId = @ID
WHERE Id in (
SELECT Id FROM Step WHERE Active = 1 and PositionId = (SELECT Id FROM Position WHERE Title = '')
)