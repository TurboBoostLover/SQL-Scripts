DECLARE @MFCC int = (SELECT MAX(id) FROM MetaForeignKeyCriteriaClient)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) ="
exec upGenerateCourseBlockDisplay @entityId = @entityId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,Title,LookupLoadTimingType)
VALUES
(@MFCC+1, 'ProgramQueryText', 'Id', 'Title', @SQL, @SQL, NULL, 'Course Block', 2)

UPDATE MetaSelectedField
SET DefaultDisplayType = 'QueryText', 
MetaPresentationTypeId = 103, 
FieldTypeId = 5,
MetaForeignKeyLookupSourceId = @MFCC + 1, 
DisplayName = 'Course Blocks', 
LabelVisible = 0
WHERE MetaSelectedFieldId = 14311