/* ===================
** Configuration
** ===================
*/
-- shows/hides first result set
declare @showCatalogOverView bit = 1;
-- shows/hides second result set
declare @showCatalogProposalOverview bit = 1;
-- shows/hides third result set
declare @showCatalogCurriculumBlockOverview bit = 1;

-- filters the third result 
-- set this to null when you are setting @filterShowOnlyActiveCatalog to 1
declare @filterCatalogId int = null;

-- filters the third result 
-- set this to null when you are setting @filterCatalogId to 1
declare @filterShowOnlyActiveCatalog bit = null;

/* ===================
** Catalog Overview
** ===================
*/
declare @CatalogOverview table
(
	Id int identity primary key,
	DBName sysname,
	ClientCode sysname,
	HasOldCatalog bit,
	HasNewCatalog bit,
	HasActiveProposal bit,
	ActiveCatalogId int,
	LocalUrl nvarchar(max)
)

insert into @CatalogOverview
select db_name() as DB
, c.Code as ClientCode
, cs.AllowCatalog as 'HasOldCatalog'
, cs.EnableNewCatalog as 'HasNewCatalog'
, oa1.HasActiveProposal
, oa1.ActiveCatalogId
, concat(
	'http://localhost:50175/',
	c.Code,
	'/Catalog/View'
) as [LocalUrl]
--, cpi.*
--, tmi.*
from config.ClientSetting cs
	inner join client c on cs.ClientId = c.Id
	outer apply (
		select 1 as HasActiveProposal
		, m.Id as ActiveCatalogId
		from Module m
			inner join ProposalType pt on m.ProposalTypeId = pt.Id
			inner join ClientEntityType cet on pt.ClientEntityTypeId = cet.Id
			inner join StatusAlias sa on m.StatusAliasId = sa.Id
		-- catalog
		where cet.EntitySpecializationTypeId = 1
		-- active
		and sa.StatusBaseId = 1
	) oa1
where c.Active = 1;

declare @ActiveCatalog table (
	CatalogId int primary key
);

insert into @ActiveCatalog
select distinct co.ActiveCatalogId
from @CatalogOverview co
where co.HasActiveProposal = 1

-- render result set
if (@showCatalogOverView = 1)
begin;
	select 
		DBName,
		ClientCode,
		HasOldCatalog,
		HasNewCatalog,
		HasActiveProposal,
		ActiveCatalogId,
		LocalUrl
	from @CatalogOverview
end;

/* ===================
** Catalog Proposal Overview
** ===================
*/
declare @CatalogProposalOverview table
(
	Id int identity primary key,
	CatalogId int,
	Title nvarchar(max),
	CreatedOn datetime,
	ProposalType nvarchar(max),
	StatusBase nvarchar(max),
	PreviousId int,
	BaseModuleId int,
	StartDate datetime,
	EndDate datetime,
	ImplementDate datetime,
	Client sysname
);

insert into @CatalogProposalOverview
	select m.Id as CatalogId
	, m.Title
	, m.CreatedOn
	, pt.Title as PropType
	, sb.Title as [Status]
	, m.PreviousId
	, m.BaseModuleId
	, cd.CatalogStartDate
	, cd.CatalogEndddate
	, pr.ImplementDate
	, cl.Code
	from Module m
		left join Client cl on m.ClientId = cl.Id
		left join Proposal pr on m.ProposalId = pr.Id
		left join CatalogDetail cd on m.Id = cd.ModuleId
		inner join BaseModule bm on m.BaseModuleId = bm.Id
		inner join ModuleDetail md on m.Id = md.ModuleId
		inner join ProposalType pt on m.ProposalTypeId = pt.Id
		inner join ClientEntityType cet on pt.ClientEntityTypeId = cet.Id
								and cet.EntitySpecializationTypeId = 1
		inner join StatusAlias sa on m.StatusAliasId = sa.Id
		inner join StatusBase sb on sa.StatusBaseId = sb.Id
	where m.Active = 1
	order by m.BaseModuleId, m.Id

-- render result set
if (@showCatalogProposalOverview = 1)
begin;
	select 
	  Client
	, CatalogId
	, Title
	, CreatedOn
	, ProposalType
	, StatusBase
	, BaseModuleId
	, PreviousId
	, StartDate
	, EndDate
	, ImplementDate
	from @CatalogProposalOverview
	order by Client, BaseModuleId, CatalogId
end;

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



/* ===================
** Catalog Curriculum Block Overview
** ===================
*/
declare @catalogAggregationMetadataAttributeTypeId int = 35; --35 = CatalogAggregation
declare @courseSummaryFullAggregationType nvarchar(25) = 'CourseSummaryFull';
declare @queryTextMetaPresentationTypeId int = 103

-- render result set
if (@showCatalogCurriculumBlockOverview = 1)
begin;
	select 
		cpo.CatalogId,
		cpi.CurriculumPresentationId as CPId,
		cpi.CurriculumPresentation as CP,
		cpi.CurriculumPresentationConfig as CPConfig,
		cpi.CurriculumBlockCount as BlockCount,

		tmi.CurriculumPresentationOutputFormatId as MappingId,

		tmi.IsModelOverride as [IsOverride],
		tmi.ModelQueryId as Id,
		tmi.ModelQuery as Model,

		tmi.IsTemplateOverride as [IsOverride],
		tmi.TemplateQueryId as Id,
		tmi.TemplateQuery as Template

	from (
		select c.CatalogId
		from @CatalogProposalOverview c
		where (@filterCatalogId is null  or c.CatalogId = @filterCatalogId)
		and (isnull(@filterShowOnlyActiveCatalog, 0) = 0 or c.CatalogId in (select a.CatalogId from @ActiveCatalog a))
	) cpo
		cross apply (
			select cp.Id as CurriculumPresentationId
			, cp.Title as CurriculumPresentation
			, count(cb.Id) as [CurriculumBlockCount]
			, cp.Config as CurriculumPresentationConfig
			from CatalogBlock cb
				inner join CatalogBlockType cbt on cb.CatalogBlockTypeId = cbt.Id
				cross apply openjson(cb.CatalogListCustomSqlQuery) 
					with (
						CurriculumPresentationId int '$.CurriculumPresentationId'
						, FilterSql nvarchar(max) '$."FilterSQL"' as json
					) o
				inner join CurriculumPresentation cp on o.CurriculumPresentationId = cp.Id
				--inner join CurriculumPresentationOutputFormat cpof on cp.Id = cpof.CurriculumPresentationId
				--												and cpof.OutputFormatId = 5
			where 1 = 1
			-- filter - curriculum blocks
			and cb.CatalogBlockTypeId = 4
			and cb.Active = 1
			and cb.ModuleId = cpo.CatalogId
			and exists (
				select 1
				from CatalogLayout cl
					inner join CatalogSection cs on cl.CatalogSectionId = cs.Id
				where cb.Id = cl.CatalogBlockId
				and cl.Active = 1
				and cs.Active = 1
				and cb.ModuleId = cl.ModuleId
			)
			group by cp.Id, cp.Title, cp.Config
		) cpi
		cross apply (
			select
			cpof.Id as CurriculumPresentationOutputFormatId,

			-- model
			--select omb.Title as ModelBase
			--, omb.ModelQuery as ModelBaseQuery
			--, omc.Title as ModelClient
			--, omc.ModelQuery as ModelClientQuery

			coalesce(omc.ModelQuery, c_omb.ModelQuery, omb.ModelQuery) as ModelQuery,
			coalesce(omc.Id, c_omb.Id, omb.Id) as ModelQueryId,
			case when omc.Id is not null then 1 else 0 end as IsModelOverride,

			--, otb.Title as TemplateBase
			--, otb.TemplateQuery as TemplateBaseQuery
			--, otc.Title as TemplateClient
			--, otc.TemplateQuery as TemplateClientQuery
		
			-- template
			coalesce(otc.TemplateQuery, c_otb.TemplateQuery, otb.TemplateQuery) as TemplateQuery,
			coalesce(otc.Id, c_otb.Id, otb.Id) as TemplateQueryId,
			case when otc.Id is not null then 1 else 0 end as IsTemplateOverride

			from CurriculumPresentationOutputFormat cpof
				left join OutputTemplateModelMappingBase otmmb on cpof.OutputTemplateModelMappingBaseId = otmmb.Id
				left join OutputModelBase omb on otmmb.OutputModelBaseId = omb.Id
				left join OutputTemplateBase otb on otmmb.OutputTemplateBaseId = otb.Id

				left join OutputTemplateModelMappingClient otmmc on cpof.OutputTemplateModelMappingClientId = otmmc.Id
				left join OutputModelBase c_omb on otmmc.OutputModelBaseId = c_omb.Id
				left join OutputModelClient omc on otmmc.OutputModelClientId = omc.Id
				left join OutputTemplateBase c_otb on otmmc.OutputTemplateBaseId = c_otb.Id
				left join OutputTemplateClient otc on otmmc.OutputTemplateClientId = otc.Id

			where cpi.CurriculumPresentationId = cpof.CurriculumPresentationId
			and cpof.OutputFormatId = 5
		) tmi
	order by cpo.CatalogId, cpi.CurriculumPresentationId;

	select distinct msf.DisplayName as MSFName
	, mfkcc.Id as mfkccId
	, mfkcc.CustomSql as CourseCatalogQueryText
	from @InUsedTemplate iut
		inner join MetaSelectedSection mss on iut.MT_Id = mss.MetaTemplateId
		inner join MetaSelectedField msf on (mss.MetaSelectedSectionId = msf.MetaSelectedSectionId and msf.MetaPresentationTypeId = @queryTextMetaPresentationTypeId)
		cross apply dbo.GetFieldMetadataAttributesByType(msf.MetaSelectedFieldId, @catalogAggregationMetadataAttributeTypeId) ma
		inner join MetaAvailableField maf on (ma.ValueText = @courseSummaryFullAggregationType and msf.MetaAvailableFieldId = maf.MetaAvailableFieldId)
		left outer join MetaForeignKeyCriteriaBase mfkcb on maf.MetaForeignKeyLookupSourceId = mfkcb.Id
		left outer join MetaForeignKeyCriteriaClient mfkcc on msf.MetaForeignKeyLookupSourceId = mfkcc.Id
	where iut.MTT_EntityTypeId = 1
end;
