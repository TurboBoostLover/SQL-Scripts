-- ===========================
-- user input
-- ===========================
declare 
	@id int = 

	--, @tableName sysname = 'AccreditationStatus'
	--, @primaryKeyColumnName sysname = 'Id'

	--, @tableName sysname = 'MetaForeignKeyCriteriaClient'
	--, @primaryKeyColumnName sysname = 'Id'

	--, @tableName sysname = 'ExpressionPart'
	--, @primaryKeyColumnName sysname = 'Id'

	--, @tableName sysname = 'MetaDisplayRule'
	--, @primaryKeyColumnName sysname = 'Id'

	--, @tableName sysname = 'MetaDisplaySubscriber'
	--, @primaryKeyColumnName sysname = 'Id'

	--, @tableName sysname = 'OrganizationEntity'
	--, @primaryKeyColumnName sysname = 'Id'

	--, @tableName sysname = 'MetaSelectedSection'
	--, @primaryKeyColumnName sysname = 'MetaSelectedSectionId'

	--, @tableName sysname = 'MetaSelectedSectionAttribute'
	--, @primaryKeyColumnName sysname = 'MetaSelectedSectionId'

	--, @tableName sysname = 'MetaSelectedField'
	--, @primaryKeyColumnName sysname = 'MetaSelectedFieldId'

	--, @tableName sysname = 'MetaSelectedFieldAttribute'
	--, @primaryKeyColumnName sysname = 'MetaSelectedFieldId'

	--, @tableName sysname = 'ListItemType'
	--, @primaryKeyColumnName sysname = 'Id'

	--, @tableName sysname = 'CatalogBlock'
	--, @primaryKeyColumnName sysname = 'Id'


-- ============
-- process
-- ============
declare
	@insertStatement nvarchar(max),
	@columnsCommaDelimited nvarchar(max),
	@columnsValuesCommaDelimited nvarchar(max) = '',
	@empty nvarchar(max) = N'',
	@currentColumnName nvarchar(max),
	@currentColumnType nvarchar(max),
	@currentSchemaName sysname,
	@isComputed bit,
	@getColumnValueQueryString nvarchar(max),
	@rowIdIndex int,
	@rowIdMax int,
	@rawValue nvarchar(max),
	@valueEncoded nvarchar(max),
	@sqlParams nvarchar(1000),
	@queryColumnsMetadata nvarchar(max),
	@newLine nvarchar(100) = char(13) + char(10),
	@displayMode int = 2,
	@dbName sysname = db_name()
;

declare @ColumnsMetaData table 
(
	Id int NOT NULL IDENTITY(1, 1) primary key,
	[name] nvarchar(max), 
	RowId int, 
	[Type] nvarchar(max),
	SchemaName sysname
);

set @queryColumnsMetadata = concat(@empty, '
	select quotename(c.name) as [name]
	, row_number() over (order by c.column_id) as RowId
	, (
		select top 1 st.name
		from sys.types st 
		where c.system_type_id = st.system_type_id
	)
	, quotename(sch.name)
	from ', quotename(@dbName) , '.sys.objects o
		inner join ', quotename(@dbName), '.sys.columns c on o.object_id = c.object_id
		inner join ', quotename(@dbName), '.sys.schemas sch on o.schema_id = sch.schema_id
	where o.name = @tableName
	and c.name != @primaryKeyColumnName
	and c.is_computed = 0
');

set @sqlParams = N'
	@primaryKeyColumnName sysname,
	@tableName sysname
';

insert into @ColumnsMetaData
exec sys.sp_executesql @queryColumnsMetadata, @sqlParams
, @primaryKeyColumnName = @primaryKeyColumnName
, @tableName = @tableName;

with ColumnsRecursive as
(
	select m.RowId, cast(m.name as nvarchar(max)) as [name]
	from @ColumnsMetaData m
	where m.RowId = 1
	union all
	select m2.RowId, m.name + ', ' + m2.name  as [name]
	from ColumnsRecursive m
		inner join @ColumnsMetaData m2 on m.RowId + 1 = m2.RowId
)
	select @columnsCommaDelimited = name
	from ColumnsRecursive 
	where RowId = (select Max(RowId) from ColumnsRecursive )

set @rowIdIndex = (select min(RowId) from @ColumnsMetaData);
set @rowIdMax = (select max(RowId) from @ColumnsMetaData);

set @sqlParams = N'@retvalOUT nvarchar(max) output';

while (@rowIdIndex <= @rowIdMax)
begin
	select @currentColumnName = [name] 
	, @currentColumnType = [Type]
	, @currentSchemaName = SchemaName
	from @ColumnsMetaData where RowId = @rowIdIndex

	if (@currentColumnType = 'image')
	begin;
		set @rowIdIndex = @rowIdIndex + 1;
		select '*This table has an image type column which cannot be generated using this script.' as [Message]
		continue;
	end;
	
	set @getColumnValueQueryString = concat(@empty, 
		'select @retvalOUT =',
		@currentColumnName,
		'from ',
		quotename(@dbName),
		'.',
		@currentSchemaName,
		'.',
		quotename(@tableName),
		' where ',
		quotename(@primaryKeyColumnName),
		' = ',
		cast(@id as nvarchar(max))
	);

	exec sys.sp_executesql @getColumnValueQueryString, @sqlParams, @retvalOUT=@rawValue output;
	
	-- set value
	if 
	(
		@currentColumnType in ('nvarchar', 'sysname', 'datetime')
		and @rawValue IS NOT NULL
	)
	begin;
		set @valueEncoded = concat(@empty, '''', REPLACE(@rawValue, '''', ''''''), '''')
	end;
	else
	begin;
		if (@rawValue is null)
		begin;
			set @valueEncoded = 'NULL';
		end;
		else
		begin;
			set @valueEncoded = @rawValue;
		end;
	end;

	-- set new lines and commas
	if (@rowIdIndex != @rowIdMax)
	begin
		set @columnsValuesCommaDelimited = concat(
			@columnsValuesCommaDelimited,
			@valueEncoded,
			', ',
			case
				when @displayMode = 2 then concat('-- ', @currentColumnName) + @newLine
				else ''
				end
		);
	end
	else
	begin
		set @columnsValuesCommaDelimited = concat(
			@columnsValuesCommaDelimited,
			@valueEncoded,
			case
				when @displayMode = 2 then concat('-- ', @currentColumnName)
				else ''
				end
		);
	end
	
	set @rowIdIndex = @rowIdIndex + 1;
end

set @insertStatement = concat(@empty,
	'insert into ',
	quotename(@tableName),
	@newLine,
	'(',
	@columnsCommaDelimited,
	')',
	@newLine,
	'values',
	case 
		when @displayMode = 2 then @newLine
		else '' 
		end, 
	'(',
	case 
		when @displayMode = 2 then @newLine
		else '' 
		end,
	@columnsValuesCommaDelimited,
	case 
		when @displayMode = 2 then @newLine
		else '' 
		end,
	')'
);

select @insertStatement as 'Generated'

PRINT @insertStatement