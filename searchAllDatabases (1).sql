USE master;

-- COMMIT
-- ROLLBACK

SET XACT_ABORT ON 
--SELECT @@servername AS 'Server Name' ,DB_NAME() AS 'Database Name'

BEGIN TRAN
BEGIN TRY

DECLARE @base TABLE (dbName NVARCHAR(MAX), query NVARCHAR(MAX));
INSERT INTO @base 
SELECT [name], 
'
' AS sqlText
FROM sys.databases
WHERE CASE 
		WHEN state_desc = 'ONLINE' THEN object_id(quotename([name]) + '.[Config].[ClientSetting]', 'U')
		END is not null
AND [name] not  LIKE '%_Old'
ORDER BY name

-- read file
CREATE TABLE #fileContent (content NVARCHAR(MAX))
-- BULK INSERT #fileContent
-- FROM 'C:\Users\AndrewEmrick\Desktop\Scripts\searchTemplate.sql'
-- WITH ( 
-- 	CODEPAGE= 65001, -- UTF-8 encoding
-- 	ROWTERMINATOR = ''
-- ); 

UPDATE @base
--for running this from a query
SET query = ( 'SELECT 	DB_NAME()     ,* FROM AssessmentDeviceType') --if not reading from a file

--for running this from a file
--SET query = (SELECT TOP 1 Content FROM #fileContent)

DROP TABLE #fileContent

-- ====================
-- interface implementation
-- ====================
-- interface dbName, query
DECLARE @container TABLE (Id INT IDENTITY(1, 1), dbName NVARCHAR(MAX), query NVARCHAR(MAX), queryRdyForExec NVARCHAR(MAX));
INSERT INTO @container (dbName, query)
SELECT b.dbName, b.query
FROM @base b

UPDATE b
SET queryRdyForExec = 'use [' + b.dbName + '];' + b.query
FROM @container b

DECLARE @currId INT = (SELECT MIN(Id) FROM @container)
DECLARE @dbName NVARCHAR(MAX) = '';
DECLARE @sql NVARCHAR(MAX) = '';

WHILE (@currId <= (SELECT MAX(Id) FROM @container))
BEGIN
	SET @dbName = (SELECT dbName FROM @container WHERE Id = @currId);
	SET @sql = (SELECT queryRdyForExec FROM @container WHERE Id = @currId);
	DECLARE @procBody NVARCHAR(MAX) = (SELECT query FROM @container WHERE Id = @currId);
	EXEC sp_executesql  @sql;
	PRINT '============================= [ START ] ======================================';
	PRINT @sql;

	SET @currId = @currId + 1;
END

COMMIT		-- disable this for support
END TRY
BEGIN CATCH
	PRINT '============================= [ Rolling back ] ======================================';
	PRINT 'Database: [' + @dbName + ']'; 
	PRINT 'Query :';
	PRINT  @sql;
	ROLLBACK; -- disable this for support
	THROW; -- will stop execution
END CATCH

