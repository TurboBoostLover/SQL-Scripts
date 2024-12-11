SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaAvailableField AS maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
INNER JOIN ListItemType AS lit on maf.ColumnName = lit.ListItemTitleColumn and maf.TableName = lit.ListItemTableName
WHERE msf.MetaPresentationTypeId = 25