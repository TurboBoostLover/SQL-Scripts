use ccsf

DECLARE @TABLE INTEGERS
INSERT INTO @TABLE
SELECT DISTINCT m1.Id
FROM MetaSelectedFieldAttribute m1
INNER JOIN (
    SELECT name, value, metaselectedfieldId
    FROM MetaSelectedFieldAttribute
    GROUP BY name, value, metaselectedfieldId
    HAVING COUNT(*) > 1
) m2 ON m1.name = m2.name AND m1.value = m2.value AND m1.metaselectedfieldId = m2.metaselectedfieldId;

SELECT * FROM @TABLE


DECLARE @TABLE2 TABLE (txt NVARCHAR(MAX), msf int)
INSERT INTO @TABLE2
SELECT Value, MetaSelectedFieldId
FROM MetaSelectedFieldAttribute
WHERE Name = 'SubText'

DECLARE @TABLE3 TABLE (txt NVARCHAR(MAX), msf int)
INSERT INTO @TABLE3
SELECT Value, MetaSelectedFieldId
FROM MetaSelectedFieldAttribute
WHERE Name = 'helptext'

SELECT * FROM @TABLE2 AS t
LEFT JOIN @TABLE3 AS t2 on t.msf = t2.msf
WHERE --(
t.msf not in (SELECT msf FROM @TABLE3)
--OR
--t2.msf not in (SELECT msf FROM @TABLE2)
--)

SELECT * FROM MetaSelectedField WHERE 
(MetaPresentationTypeId = 5
or 
(MetaPresentationTypeId = 1 and FieldTypeId = 5)
or MetaPresentationTypeId = 103)
AND IsRequired = 1