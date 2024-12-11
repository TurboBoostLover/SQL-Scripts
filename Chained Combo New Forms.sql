SET XACT_ABORT ON
BEGIN TRAN
--commit
--rollback

INSERT INTO MetaSelectedFieldAttribute (Name,Value,MetaSelectedFieldId)
VALUES
('FilterSubscriptionTable', 'GenericOrderedList01', 974),		--table name of parent
('FilterSubscriptionColumn', 'Related_ProgramId', 974),			--column name of parent
('FilterTargetTable', 'GenericOrderedList01', 974),				--table name of child					--all go on child
('FilterTargetColumn', 'ProgramOutcomeId', 974)					--column name of child


DECLARE @Mfcid int = (SELECT MAX(id) FROM MetaForeignKeyCriteriaClient) + 1								--id for new mfkcc

DECLARE @SQL NVARCHAR(MAX)	='SELECT Id AS Value,
		coalesce(EntityTitle, Title) AS Text
		FROM Program										
		WHERE Active = 1'																				--custom sql for parent

DECLARE @SQL3 NVARCHAR(MAX) ='																			
SELECT coalesce(EntityTitle, Title) AS Text
		FROM Program
		WHERE Id = @Id
'																										--resolution sql for parent


DECLARE @SQL2 NVARCHAR(MAX)	=	'SELECT Id AS Value, 
		Outcome AS Text,
		ProgramId as FilterValue
		FROM ProgramOutcome 
		WHERE Active = 1'																				--custom sql for child

DECLARE @SQL4 NVARCHAR(MAX) ='
SELECT Outcome AS Text
		FROM ProgramOutcome
		WHERE Id = @Id
'																										--resolution sql for child
		
INSERT INTO MetaForeignKeyCriteriaClient
(Id,TableName,DefaultValueColumn,DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@Mfcid, 'GenericOrderedList01','Title', 'Id', @SQL, @SQL3, NULL, 'TestProgramDropDown', 2),			--New MFKCC
(@Mfcid + 1, 'GenericOrderedList01','Outcome', 'Id', @SQL2, @SQL4, NULL, 'TestProgramDropDown', 3)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @Mfcid																--Set MFKCC on Fields
WHERE MetaSelectedFieldId = 973

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @Mfcid+1																--Set MFKCC on Fields
WHERE MetaSelectedFieldId = 974

UPDATE MetaTemplate
SET LastUpdatedDate= GETDATE()																			--Update Template
WHERE MetaTemplateId = 1

UPDATE ListItemType
SET Title = 'Program Outcome'
, ListItemTitleColumn = 'Related_ProgramId'																--List item on oL check column as column but be column or table idk of item in ol
WHERE Id = 29

UPDATE MetaSelectedField
SET FieldTypeId = 5																						--FieldType must be 5 for looksups
WHERE MetaSelectedFieldId in (973, 974)
