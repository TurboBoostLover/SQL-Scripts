USE []

DECLARE @table nvarchar(100) = 'moduleExtension02',               -- Enter the Name of the Table
		@clientId int =3, --If the client is a district make sure that you are using the correct ClientId
		@EntityTypeId int = 6;                                    -- EntityTypeId 1 = Course, 2 = Program, 6 = Module

SELECT o.Name as 'Table', c.name as 'Column', t.name as 'DataType',
		c.max_length as 'MaxLength', c.precision, c.scale,
		maf.MetaAvailableFieldId,
		maf.DefaultDisplayName,
		mag.GroupName
FROM sys.columns c
INNER JOIN sys.objects o ON c.object_id = o.object_id
INNER JOIN sys.types t ON c.system_type_id = t.system_type_id
LEFT JOIN MetaAvailableField maf 
	ON o.Name = maf.TableName
	AND c.Name = maf.ColumnName
left join MetaAvailableGroup mag on mag.id = maf.MetaAvailableGroupId
WHERE o.name = @table
AND t.Name <> 'sysname'
--and c.scale > 2
--AND t.Name = 'nvarchar'                                               -- You can specify what kind of field you are looking for
--and c.name like '%Id'                                             -- You can specify what kind of field you are looking for
and MetaAvailableFieldId is not null
AND NOT EXISTS (SELECT 1
					FROM MetaSelectedField msf
						INNER JOIN MetaSelectedSection mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
					WHERE msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
					AND mss.MetaTemplateId in (select mt.MetaTemplateId
												from MetaTemplate mt
												inner join MetaTemplateType mtt on mt.metaTemplateTypeId = mtt.metaTemplateTypeId
												where --mt.clientId = @ClientId
												--and 
												mt.startDate is not NULL
												and mt.DeletedDate is NULL
												and mt.enddate is null
												and mt.active = 1
												and Mtt.entityTypeId = @EntityTypeId
												and mtt.active = 1
												)
												 )
ORDER BY o.name, c.name