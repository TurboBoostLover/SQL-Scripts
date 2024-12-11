use tru

SELECT  
 DB_NAME(),
 mss.MetaSelectedSectionId,
 mss.MetaTemplateId,
 mss.SectionName,
 mss.MetaBaseSchemaId,
 mss2.SectionName
FROM MetaSelectedSection mss
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE mss.metasectionTypeId = 13
 and exists ( 
 SELECT 
 c.id 
 from course c
 WHERE c.metatemplateId = mss.metatemplateId
 and c.active = 1
 Union
 SELECT 
 p.metatemplateId
 from Program p
 WHERE p.metatemplateId = mss.metatemplateId
 and p.active = 1
 Union
 SELECT 
 m.id 
 from Module m
 WHERE m.metatemplateId = mss.metatemplateId
 and m.active = 1
 )
 order by mss.MetaBaseSchemaId
--
