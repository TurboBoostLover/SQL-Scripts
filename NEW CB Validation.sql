use cuesta

DECLARE @CB03 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName like '%CB03%'and Id = 413) --413
DECLARE @CB04 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName = 'CB04' and Id = 414) --414
DECLARE @CB05 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName = 'CB05') -- 415
DECLARE @CB08 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName = 'CB08') --416
DECLARE @CB09 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName like 'CB09'and Id = 417)-- 417
DECLARE @CB10 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName like 'CB10') --Created
DECLARE @CB11 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName = 'CB11')--418
DECLARE @CB13 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName = 'CB13')--419
DECLARE @CB21 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName like 'CB21' and Id = 420) --420
DECLARE @CB22 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName = 'CB22')--421
DECLARE @CB23 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName like 'CB23')--Created
DECLARE @CB24 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName = 'CB24')--20
DECLARE @CB25 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName like 'CB25')--Created
DECLARE @CB26 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName like 'CB26') --Created
DECLARE @CB27 INT = (SELECT Id FROM MetaForeignKeyCriteriaClient WHERE TableName = 'CB27') --422

DECLARE @MAXID INT = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName,DefaultValueColumn, DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,Title, LookupLoadTimingType)
VALUES
(@MAXID, 'CB10', 'Id', 'Code', 'EXEC upGenerateCBCustomSQL @CBCode = ''CB10'', @entityId = @entityId', 'select Id as [Value], Code + '' - '' + [Description] as [Text] from CB10 where Id = @id;', NULL, 'CB10', 2),
(@MAXID+1, 'CB23', 'Id', 'Code', 'EXEC upGenerateCBCustomSQL @CBCode = ''CB23'', @entityId = @entityId', 'select Id as [Value], Code + '' - '' + [Description] as [Text] from CB23 where Id = @id;', NULL, 'CB23', 2),
(@MAXID+2, 'CB25', 'Id', 'Code', 'EXEC upGenerateCBCustomSQL @CBCode = ''CB25'', @entityId = @entityId', 'select Id as [Value], Code + '' - '' + [Description] as [Text] from CB25 where Id = @id;', NULL, 'CB25', 2),
(@MAXID+3, 'CB26', 'Id', 'Code', 'EXEC upGenerateCBCustomSQL @CBCode = ''CB26'', @entityId = @entityId', 'select Id as [Value], Code + '' - '' + [Description] as [Text] from CB26 where Id = @id;', NULL, 'CB26', 2)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB03'', @entityId = @entityId'
WHERE Id = @CB03

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB04'', @entityId = @entityId'
WHERE Id = @CB04

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB05'', @entityId = @entityId'
WHERE Id = @CB05

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB08'', @entityId = @entityId'
WHERE Id = @CB08

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB09'', @entityId = @entityId'
WHERE Id = @CB09

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB11'', @entityId = @entityId'
WHERE Id = @CB11

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB13'', @entityId = @entityId'
WHERE Id = @CB13

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB21'', @entityId = @entityId'
WHERE Id = @CB21

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB22'', @entityId = @entityId'
WHERE Id = @CB22

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB24'', @entityId = @entityId'
, LookupLoadTimingType = 2
WHERE Id = @CB24

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'EXEC upGenerateCBCustomSQL @CBCode = ''CB27'', @entityId = @entityId'
WHERE Id = @CB27

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAXID
WHERE MetaSelectedFieldId = 12993

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAXID + 1
WHERE MetaSelectedFieldId = 12998

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAXID + 2
WHERE MetaSelectedFieldId = 13000

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAXID + 3
WHERE MetaSelectedFieldId = 13001

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
VALUES
('subscription', 12996, 13000),
('subscription', 12989, 13001)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId = 51