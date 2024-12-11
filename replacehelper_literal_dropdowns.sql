declare @lookupTablesToIgnore table (
	TableName sysname
);
insert into @lookupTablesToIgnore
values
('ClientLearningOutcome'),
('Campus'),
('AwardType'),
('DeliveryMethod'),
('GeneralEducation'),
('GeneralEducationElement'),
('CipCode'),
('CipCode_Florida'),
('ClientTopCode'),
('Yesno'),
('PickList'),
('Condition'),
('ListItemType'),
('OrganizationEntity'),
('Subject'),
('Semester'),
('User'),
('SamCode'),
('CipCode_Seeded'),
('BaseProgram'),
('Soc'),
('Numeral')

-- ====================================================
-- begin
-- ====================================================
-- ==============================
-- @InUsedTemplate
-- ==============================
declare @reportInUsed table (ReportId int, EntityCount int, reportTemplateId int)

insert into @reportInUsed
select rpfn1.Id
, count(rpfn3.EntityId)
, rpfn2.reportTemplateId
from (
	-- * This is a copy from MetaReportingServices *
	--Join reports across all client entries for reports with a null client id on the MetaReport table.
	--All active clients will have these reports (default behavior).
	--Only create mappings where the template is used by that client, which is determined by:
	--* The client of the template
	--* Other clients that use that template (as defined by the MetaTemplateTypeClient table)
	select
		mr.Id as ReportId,
		mrt.SortOrder,
		mrtt.MetaTemplateTypeId,
		mrat.ProcessActionTypeId,
		c.Id as MappedClientId,
		c.CacheIdentifier,

		--This mr.* is done so we can bring in any new columns added to the MetaReport table once they are available w/o changing the query
		mr.*
	from MetaReport mr
	inner join MetaReportType mrt on mr.MetaReportTypeId = mrt.Id
	inner join MetaReportActionType mrat on mr.Id = mrat.MetaReportId
	inner join MetaReportTemplateType mrtt on (mr.Id = mrtt.MetaReportId and isnull(mrtt.Active, 1) = 1)
	inner join MetaTemplateType mtt on mrtt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	inner join Client c on (
		(c.Id = mtt.ClientId)
		or exists (
			select 1
			from MetaTemplateTypeClient mttc
			where mttc.MetaTemplateTypeId = mtt.MetaTemplateTypeId
			and mttc.ClientId = c.Id
		)
	)
	where c.Active = 1
	and mr.ClientId is null
	union
	--Then combine those results with reports that are bound to a specific client id.
	--Only the specified client will have these reports (configured behavior via non-null entries in the MetaReport ClientId column).
	select
		mr.Id as ReportId,
		mrt.SortOrder,
		mrtt.MetaTemplateTypeId,
		mrat.ProcessActionTypeId,
		c.Id as MappedClientId,
		c.CacheIdentifier,

		--This mr.* is done so we can bring in any new columns added to the MetaReport table once they are available w/o changing the query
		mr.*
	from MetaReport mr
	inner join MetaReportType mrt on mr.MetaReportTypeId = mrt.Id
	inner join MetaReportActionType mrat on mr.Id = mrat.MetaReportId
	inner join MetaReportTemplateType mrtt on mr.Id = mrtt.MetaReportId
	inner join Client c on mr.ClientId = c.Id
	--order by mrtt.MetaTemplateTypeId, mrt.SortOrder, mr.Title;
) rpfn1
	outer apply openjson(rpfn1.ReportAttributes)
	with (
		reportTemplateId int '$.reportTemplateId'
	) rpfn2
	outer apply (
		select *
		from (
			select
				c.CacheIdentifier AS ClientCacheIdentifier,
				mt.MetaTemplateTypeId,
				pt.ProcessActionTypeId,
				e.Id as EntityId
			from Course e
				inner join Client c on e.ClientId = c.Id
				inner join MetaTemplate mt on e.MetaTemplateId = mt.MetaTemplateId
				inner join ProposalType pt on e.ProposalTypeId = pt.Id
			where e.Active = 1
			union
			select
				c.CacheIdentifier AS ClientCacheIdentifier,
				mt.MetaTemplateTypeId,
				pt.ProcessActionTypeId,
				e.Id as EntityId
			from Program e
				inner join Client c on e.ClientId = c.Id
				inner join MetaTemplate mt on e.MetaTemplateId = mt.MetaTemplateId
				inner join ProposalType pt on e.ProposalTypeId = pt.Id
			where e.Active = 1
			union
			select
				c.CacheIdentifier AS ClientCacheIdentifier,
				mt.MetaTemplateTypeId,
				pt.ProcessActionTypeId,
				e.Id as EntityId
			from Package e
				inner join Client c on e.ClientId = c.Id
				inner join MetaTemplate mt on e.MetaTemplateId = mt.MetaTemplateId
				inner join ProposalType pt on e.ProposalTypeId = pt.Id
			where e.Active = 1
			union
			select
				c.CacheIdentifier AS ClientCacheIdentifier,
				mt.MetaTemplateTypeId,
				pt.ProcessActionTypeId,
				e.Id as EntityId
			from Module e
				inner join Client c on e.ClientId = c.Id
				inner join MetaTemplate mt on e.MetaTemplateId = mt.MetaTemplateId
				inner join ProposalType pt on e.ProposalTypeId = pt.Id
			where e.Active = 1
		) rpfn3fn1
		where rpfn1.MetaTemplateTypeId = rpfn3fn1.MetaTemplateTypeId
		and rpfn1.ProcessActionTypeId = rpfn3fn1.ProcessActionTypeId
		and rpfn1.CacheIdentifier = rpfn3fn1.ClientCacheIdentifier
	) rpfn3
group by rpfn1.Id, rpfn2.reportTemplateId, rpfn1.Title


declare @InUsedTemplate table
(
	MTT_Id int,
	MTT_Name nvarchar(max),
	MTT_ClientId int,
	MTT_EntityTypeId int,
	MTT_Active bit,
	MT_Id int primary key,
	MT_Name nvarchar(max),
	MT_Active bit,
	EntityCount int,
	IsReport bit,
	ActiveTemplate bit,
	TemplateInUsed bit
);


insert into @InUsedTemplate (
	MTT_Id,
	MTT_Name,
	MTT_ClientId,
	MTT_EntityTypeId,
	MTT_Active,
	MT_Id,
	MT_Name,
	MT_Active,
	EntityCount,
	IsReport,
	ActiveTemplate,
	TemplateInUsed
)
select 
  mtt.MetaTemplateTypeId
, mtt.TemplateName
, mtt.ClientId
, mtt.EntityTypeId
, mtt.Active
, pmt.MetaTemplateId
, pmt.Title
, case when current_timestamp between pmt.StartDate and isnull(pmt.EndDate, current_timestamp) then 1 else 0 end
, case
	when mtt.IsPresentationView = 0 then fn2.EntityCount
	when mtt.IsPresentationView = 1 then fn2a.EntityCount
	else 0
	end as EntityCount
, mtt.IsPresentationView
, fn.ActiveTemplate
, fn3.InUsedTemplate
from MetaTemplate pmt
	inner join MetaTemplateType mtt on pmt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	inner join EntityType et on mtt.EntityTypeId = et.Id
	inner join Client cl on mtt.ClientId = cl.Id
	outer apply (
		select 
				case 
					when current_timestamp between pmt.StartDate and isnull(pmt.EndDate, current_timestamp)
						and pmt.IsDraft = 0
						and pmt.Active = 1
						and mtt.Active = 1
							then 1
					else 0 
					end as ActiveTemplate
	) fn
	outer apply (
		select count(*) as EntityCount
		from (
			select c.Id, c.MetaTemplateId
			from Course c
			where c.Active = 1
			union
			select p.Id, p.MetaTemplateId
			from Program p
			where p.Active = 1
			union
			select p.Id, p.MetaTemplateId
			from Package p
			where p.Active = 1
			union
			select p.Id, p.MetaTemplateId
			from Module p
			where p.Active = 1
		) f
		where pmt.MetaTemplateId = f.MetaTemplateId
		group by MetaTemplateId
	) fn2

	outer apply (
		select sum(coalesce(riu.EntityCount, 0)) as EntityCount
		from @reportInUsed riu
		where pmt.MetaTemplateId = riu.reportTemplateId
		group by riu.reportTemplateId
	) fn2a	

	outer apply (
		select 
			case
				when mtt.IsPresentationView = 1 and (fn2a.EntityCount > 0 or fn.ActiveTemplate = 1) then 1
				when mtt.IsPresentationView = 0 and (fn2.EntityCount > 0 or fn.ActiveTemplate = 1) then 1
				end	as InUsedTemplate
	) fn3


/* =========================
** MSSPages
** =========================
*/
/*
- Use this for ms, imp, or testing purposes. If used in dev work, add some indexes to increase performance
- This casacades from top to bottom, so if you pass a tab section id, it will get all its children sections and nested sections
*/

declare @MSSTabs table
(
	MSSId int primary key,
	IsTab bit,
	TabMSSId int,
	TabMSSSectionName nvarchar(500)
);

with Pages as (
	select mss.MetaSelectedSectionId as MSSId
	, null as ParentId
	, mss.MetaSelectedSectionId as MainParentId
	, case when mss.MetaSelectedSection_MetaSelectedSectionId is null then 1 else 0 end as IsTab
	from MetaSelectedSection mss
	-- add filters as desires
	where mss.MetaSelectedSection_MetaSelectedSectionId is null

	union all

	select mss.MetaSelectedSectionId as MSSId
	, p.MSSId as ParentId
	, p.MainParentId
	, case when mss.MetaSelectedSection_MetaSelectedSectionId is null then 1 else 0 end as IsTab
	from Pages p
		inner join MetaSelectedSection mss on p.MSSId = mss.MetaSelectedSection_MetaSelectedSectionId
)
	insert into @MSSTabs (MSSId, TabMSSId, TabMSSSectionName, IsTab)
	select p.MSSId, p.MainParentId, mss.SectionName, p.IsTab
	from Pages p
		inner join MetaSelectedSection mss on p.MainParentId = mss.MetaSelectedSectionId



-- ====================================================
-- begin
-- ====================================================
drop table if exists #fkMAFColumns
;with Source as	-- pulls all the meta avaiable fields possible
(
	SELECT 
	  maf.TableName						AS 'table_name'
	, maf.ColumnName					AS 'column_name'
	--, st.name							AS 'type_name'
	--, (CASE 
	--	WHEN sc.max_length/2 = 0 THEN '-1'
	--	ELSE sc.max_length
	--	END)							AS 'max_length_divided'
	--, sc.precision
	--, sc.scale
	, maf.MetaAvailableFieldId
	--, sch.schema_id
	, fn.PrimaryTableName as PrimaryTableName
	--, fn.ReferenceTableName as PrimaryTableName
	FROM sys.columns sc
		INNER JOIN sys.objects so ON sc.object_id = so.object_id
		inner join sys.schemas sch on so.schema_id = sch.schema_id
		inner join sys.types st ON sc.system_type_id = st.system_type_id
		inner join MetaAvailableField maf
			ON so.name = maf.TableName
			AND sc.name = maf.ColumnName
		cross apply (
			select  
			  tab1.name as ForeignTableName
			, sch.schema_id as ForeignTableSchemaId
			, col1.name as ForeignTableColumnName
 			, tab2.name as PrimaryTableName
			, col2.name as PrimaryTableColumnName
			from sys.foreign_key_columns fkc
				-- foreign
				inner join sys.objects obj ON obj.object_id = fkc.constraint_object_id -- this is just the contraint object
				inner join sys.tables tab1 ON tab1.object_id = fkc.parent_object_id -- foreign table
				inner join sys.schemas sch ON tab1.schema_id = sch.schema_id -- schema of foreign 
				inner join sys.columns col1 ON col1.column_id = fkc.parent_column_id  -- foreign key column
										AND col1.object_id = tab1.object_id

				-- primary
				inner join sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id -- primary table
				inner join sys.columns col2 ON col2.column_id = referenced_column_id  -- primary id
										AND col2.object_id = tab2.object_id
			where sc.column_id = col1.column_id
			and so.object_id = col1.object_id
			--select *
			--from dbo.SystemForeignKeyView v
			--where maf.TableName = v.TableName
			--and maf.ColumnName = v.ColumnName
		) fn
	where 1 = 1
)
	select *
	into #fkMAFColumns
	from Source

 --MAF tables not found in MetaBaseSChema tables
	--;with allMBSTables as (
	--	select mbs.PrimaryTable as TableName
	--	from MetaBaseSchema mbs
	--	union
	--	select mbs.ForeignTable
	--	from MetaBaseSchema mbs
	--)
	--	select *
	--	from #fkMAFColumns a
	--	where not exists (
	--		select 1
	--		from allMBSTables m
	--		where a.table_name = m.TableName
	--	);

 --MAF table and column not found in MB
	--select *
	--from #fkMAFColumns a
	--where a.PrimaryTableName is not null
	--and not exists (
	--	select *
	--	from MetaBaseSchema mbs
	--	where mbs.MetaRelationTypeId = 3
	--	and a.PrimaryTableName = mbs.PrimaryTable
	--	and a.table_name = mbs.ForeignTable
	--	and a.column_name = mbs.ForeignKey
	--)
	--order by 1, 2

-- the mfkcb table does not match with foreign contraint table
	--select maf.MetaAvailableFieldId
	--, maf.TableName as MAF_Table
	--, maf.ColumnName as MAF_Column
	--, b.TableName as MFKCB_Table
	--, a.PrimaryTableName as ForeignKeyLookupTable
	--from #fkMAFColumns a
	--	inner join MetaAvailableField maf on a.MetaAvailableFieldId = maf.MetaAvailableFieldId
	--	inner join MetaForeignKeyCriteriaBase b on maf.MetaForeignKeyLookupSourceId = b.Id
	--where b.TableName != a.PrimaryTableName

-- fields in used that are fk
drop table if exists #InUsedFKMAFs;
select distinct msf.MetaAvailableFieldId
, a.PrimaryTableName
into #InUsedFKMAFs
from @InUsedTemplate i
	inner join MetaSelectedSection mss on i.MT_Id = mss.MetaTemplateId
	inner join MetaSelectedField msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	inner join #fkMAFColumns a on msf.MetaAvailableFieldId = a.MetaAvailableFieldId
	--inner join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
where i.TemplateInUsed = 1;

drop table if exists #InUsedSqlOverrides;
;with Source as (
	select msf.MetaSelectedFieldId
	, c.Id
	, c.CustomSql
	, c.ResolutionSql
	, 1 as IsSqlOverride
	from @InUsedTemplate i
		inner join MetaSelectedSection mss on i.MT_Id = mss.MetaTemplateId
		inner join MetaSelectedField msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
		inner join MetaForeignKeyCriteriaClient c on msf.MetaForeignKeyLookupSourceId = c.Id
	where i.TemplateInUsed = 1
)
, Source2 as (
	select msf.MetaSelectedFieldId
	, b.Id 
	, b.CustomSql
	, b.ResolutionSql
	, 0 as IsSqlOverride
	from @InUsedTemplate i
		inner join MetaSelectedSection mss on i.MT_Id = mss.MetaTemplateId
		inner join MetaSelectedField msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
		inner join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
		inner join MetaForeignKeyCriteriaBase b on maf.MetaForeignKeyLookupSourceId = b.Id
	where i.TemplateInUsed = 1
	and not exists (
		select 1
		from Source s
		where msf.MetaSelectedFieldId = s.MetaSelectedFieldId
	)
)
, Source3 as (
	select *
	from Source
	union 
	select *
	from Source2
)
	select distinct Id, CustomSql, ResolutionSql, IsSqlOverride
	into #InUsedSqlOverrides
	from Source3
;

-- primary tables that are not for lookup data 
drop table if exists #EntityPrimaryTableOneToMany;
with Recur as (
	select mbs.Id
	, mbs.PrimaryTable
	, mbs.ForeignTable
	, mbs.EntityTypeId
	, mbs.MetaRelationTypeId
	, mbs.Id as RootMetaBaseSchemaId
	, 0 as [Level]
	from MetaBaseSchema mbs
	where mbs.PrimaryTable in (
		select et.ReferenceTable
		from EntityType et
	)
	and MetaRelationTypeId = 2

	union all

	select mbs.Id
	, mbs.PrimaryTable
	, mbs.ForeignTable
	, mbs.EntityTypeId
	, mbs.MetaRelationTypeId
	, r.RootMetaBaseSchemaId
	, r.[Level] + 1 as [Level]
	from Recur r
		inner join MetaBaseSchema mbs on r.ForeignTable = mbs.PrimaryTable
	where mbs.MetaRelationTypeId = 2
)
, Prepare as (
	select PrimaryTable as TableName
	from Recur
	union
	select ForeignTable
	from Recur
)
	select TableName
	into #EntityPrimaryTableOneToMany
	from Prepare

drop table if exists #EntityPrimaryTableOneToOne
select fn.TableName
into #EntityPrimaryTableOneToOne
from (
	select mbs.PrimaryTable as TableName
	from MetaBaseSchema mbs
	where mbs.MetaRelationTypeId = 1 
	union
	select mbs.ForeignTable
	from MetaBaseSchema mbs
	where mbs.MetaRelationTypeId = 1 
) fn

-- ltieral dropdowns
drop table if exists #LDFields;
create table #LDFields (
	--Id int identity primary key,
	MT_Id int,
	TabName nvarchar(max),
	MSFId int  primary key,
	MAFId int,
	EntityTypeId int,
	IsFirstLevelOfDetail bit
);

insert into #LDFields
select
  i.MT_Id
, t.TabMSSSectionName
, msf.MetaSelectedFieldId as MSFId
, maf.MetaAvailableFieldId as MAFId
, i.MTT_EntityTypeId as EntityTypeId
, coalesce(fn.IsFirstLevelOfDetail, 0) as IsFirstLevelOfDetail
from MetaSelectedField msf
	inner join MetaSelectedSection mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	inner join @InUsedTemplate i on mss.MetaTemplateId = i.MT_Id
	inner join @MSSTabs t on mss.MetaSelectedSectionId = t.MSSId
	inner join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
	outer apply (
		select top 1 1 as IsFirstLevelOfDetail
		from MetaBaseSchema mbs
		where mbs.MetaRelationTypeId = 1
		and (maf.TableName = mbs.PrimaryTable or maf.TableName = mbs.ForeignTable)
	) fn
where 1 = 1
and i.TemplateInUsed = 1
and (
	msf.MetaPresentationTypeId = 101
	or
	exists (
		select 1
		from MetaLiteralList mll
		where msf.MetaSelectedFieldId = mll.MetaSelectedFieldId
	)
);

--1631
drop table if exists #LDFieldsTables;
;with LDSFieldMBS as (
	select mbs.Id
	, mbs.PrimaryTable
	, mbs.ForeignTable
	from #LDFields l
		inner join MetaAvailableField maf on l.MAFId = maf.MetaAvailableFieldId
		inner join MetaBaseSchema mbs on 
			mbs.MetaRelationTypeId = 1
			and (
				maf.TableName = mbs.PrimaryTable
				or
				maf.TableName = mbs.ForeignTable
			)
			and l.EntityTypeId = mbs.EntityTypeId
)
, Prepare as (
	select maf.TableName
	from #LDFields l
		inner join MetaAvailableField maf on l.MAFId = maf.MetaAvailableFieldId
	union 
	select PrimaryTable
	from LDSFieldMBS
	union 
	select ForeignTable
	from LDSFieldMBS
)
	select *
	into #LDFieldsTables
	from Prepare
;

drop table if exists #Enumerable;
create table #Enumerable (
	InsertedId int identity primary key,
	TableName nvarchar(max),
	ColumnName nvarchar(max),
	MAFId int,
	PrimaryTableName nvarchar(max),
	IsFirstLevelOfDetail bit
)

;with MBSTables as (
	select mbs.PrimaryTable as TableName
	from MetaBaseSchema mbs
	union
	select mbs.ForeignTable
	from MetaBaseSchema mbs
)
	insert into #Enumerable
	select e.*
	, isnull(fn.IsFirstLevelOfDetail, 0) as IsFirstLevelOfDetail
	from MBSTables a
		inner join #fkMAFColumns e on a.TableName = e.table_name
		inner join MetaAvailableField bmaf on e.MetaAvailableFieldId = bmaf.MetaAvailableFieldId
		outer apply (
			select top 1 1 as IsFirstLevelOfDetail
			from MetaBaseSchema mbs
			where mbs.MetaRelationTypeId = 1
			and (bmaf.TableName = mbs.PrimaryTable or bmaf.TableName = mbs.ForeignTable)
		) fn
	where 1 = 1
	and a.TableName not in ('CourseYesNo', 'ProgramYesNo', 'ModuleYesNo')
	and e.PrimaryTableName not in (
		select TableName
		from @lookupTablesToIgnore
	)
	and dbo.RegEx_IsMatch(e.PrimaryTableName, '^CB[0-9][0-9]') != 1
	and e.PrimaryTableName not like 'Catalog%'
	and not exists (
		select 1
		from #EntityPrimaryTableOneToMany ept
		where e.PrimaryTableName = ept.TableName
	)
	and not exists (
		select 1
		from #EntityPrimaryTableOneToOne ept
		where e.PrimaryTableName = ept.TableName
	)
	-- MAFs not used already
	and not exists (
		select 1
		from #InUsedFKMAFs i
		where e.MetaAvailableFieldId = i.MetaAvailableFieldId
	)
	-- only where on tables field can live and grow:)
	and exists (
		select *
		from #LDFieldsTables l
		where e.table_name = l.TableName
	)
	order by fn.IsFirstLevelOfDetail desc, e.PrimaryTableName
;

select InsertedId as [Index]
, TableName
, ColumnName
, MAFId
, PrimaryTableName as LookupTable
, IsFirstLevelOfDetail
from #Enumerable

declare @i int = (select min(InsertedId) from #Enumerable);
declare @max int = (select max(InsertedId) from #Enumerable);

declare 
	@currMAFId int,
	@currMAFTableName nvarchar(max),
	@currMAFColumnName nvarchar(max),
	@currLookupTableName nvarchar(max),
	@hasResults1 bit = 0,
	@hasResults2 bit = 0,
	@hasResults3 bit = 0,
	@simpleLookupQuery nvarchar(max)
;


while @i <= @max 
begin;

	set @hasResults1 = 0;
	set @hasResults2 = 0;
	set @hasResults3 = 0;

	select @currMAFId = l.MAFId
	, @currMAFTableName = maf.TableName
	, @currMAFColumnName = maf.ColumnName
	, @currLookupTableName = l.PrimaryTableName
	from #Enumerable l
		inner join MetaAvailableField maf on l.MAFId = maf.MetaAvailableFieldId
	where l.InsertedId = @i

	set @simpleLookupQuery = concat(
		'select ''Lookup data'', * from ', quotename(@currLookupTableName)
	);

	if exists (
		select *
		from dbo.fnBulkResolveCustomSqlQuery(@simpleLookupQuery, 1, null, null, null, null, null) b
		where b.ResultCount > 0
	)
		set @hasResults1 = 1;

	if exists (
		select 1
		from #InUsedFKMAFs i
			inner join MetaAvailableField maf on i.MetaAvailableFieldId = maf.MetaAvailableFieldId
		where i.PrimaryTableName = @currLookupTableName
		and i.MetaAvailableFieldId != @currMAFId
	)
		set @hasResults2 = 1;
	
	if exists (
		select 1
		from #InUsedSqlOverrides s
		where s.CustomSql like '%' + @currLookupTableName + '%'
		or s.ResolutionSql like '%' + @currLookupTableName + '%'
	)
		set @hasResults3 = 1;

	if (
		@hasResults1 = 1 or @hasResults2 = 1 or @hasResults3 = 1
	)
		select l.InsertedId as '=> Index'
		, l.IsFirstLevelOfDetail
		, l.MAFId as MetaAvailableFieldId
		, l.TableName
		, l.ColumnName
		, l.PrimaryTableName as LookupTable
		from #Enumerable l
		where l.InsertedId = @i

	if (@hasResults1 = 1)
		exec sys.sp_executesql @simpleLookupQuery;
	;

	if (@hasResults2 = 1)
		select 'In used by another MAF', maf.MetaAvailableFieldId
		, maf.TableName
		, maf.ColumnName
		, i.PrimaryTableName
		from #InUsedFKMAFs i
			inner join MetaAvailableField maf on i.MetaAvailableFieldId = maf.MetaAvailableFieldId
		where i.PrimaryTableName = @currLookupTableName
		and i.MetaAvailableFieldId != @currMAFId
	;

	if (@hasResults3 = 1)
		select 'In used by MFKCC', s.*
		from #InUsedSqlOverrides s
		where s.CustomSql like '%' + @currLookupTableName + '%'
		or s.ResolutionSql like '%' + @currLookupTableName + '%'
	;
	-- next
	set @i = @i + 1;
end;
