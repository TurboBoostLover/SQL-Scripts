use ;

--==========

set xact_abort on;

begin transaction;

select 'Environment' as __Environment, @@servername as ServerName, db_name() as DatabaseName;

declare @newReports table (
	Id int primary key not null,
	Title nvarchar(200) not null,
	MetaReportTypeId int not null,
	ClientId int,
	CompanionFor_MetaReportId int not null,
	IsPublicReport bit,
	ReportAttributes nvarchar(max)
);

insert into @newReports(Id, Title, MetaReportTypeId, ClientId, CompanionFor_MetaReportId, IsPublicReport, ReportAttributes)
values
--Course compare; reportId 43 is the Id for the standard course comparison report
(258, 'Abridged Comparison', 2, null, 43, 0, '{"showDifferencesOnly":true}'),
--Program compare; reportId 44 is the Id for the standard program comparison report
(259, 'Abridged Comparison', 6, null, 44, 0, '{"showDifferencesOnly":true}')
;

select '@newReports' as [@newReports], nr.*
from @newReports nr;

merge into MetaReport t
using (
	select
		nr.Id, nr.Title, nr.MetaReportTypeId, nr.ClientId,
		json_modify(coalesce(nr.ReportAttributes, '{}'), '$.isPublicReport', nr.IsPublicReport) as ReportAttributes
	from @newReports nr
) s
on (t.Id = s.Id)
when not matched then insert (Id, Title, MetaReportTypeId, ClientId, ReportAttributes)
values (s.Id, s.Title, s.MetaReportTypeId, s.ClientId, s.ReportAttributes)
output 'Adding new MetaReport records' as __AddingNewMetaReportRecords, inserted.*;

merge into MetaReportActionType t
using(
	select
		IdCounter.StartNum + row_number() over (order by nr.Id) as Id,
		nr.Id as MetaReportId, pat.Id as ProcessActionTypeId
	from @newReports nr
	cross join (select coalesce(max(Id), 0) as StartNum from MetaReportActionType) as IdCounter
	cross join (select * from ProcessActionType pat where pat.Id in (2, 3)) pat
	--The not exists clause isn't strictly necessary for the merge, as records that already exist
	--will not be inserted.
	--However, this exists clause keeps this merge from causing gaps in the Id sequence.
	where not exists (
		select 1
		from MetaReportActionType mrat
		where mrat.ProcessActionTypeId = pat.Id
		and mrat.MetaReportId = nr.Id
	)
) s (Id, MetaReportId, ProcessActionTypeId)
on (t.MetaReportId = s.MetaReportId and t.ProcessActionTypeId = s.ProcessActionTypeId)
when not matched then insert (Id, MetaReportId, ProcessActionTypeId)
values (s.Id, s.MetaReportId, s.ProcessActionTypeId)
output 'Adding MetaReportActionType records' as __AddingModuleMetaReportActionTypeRecords, inserted.*;

merge into MetaReportTemplateType t
using (
	select
		mrtt.Id, mrtt.MetaReportId as CurrentReportId, mr.Title as CurrentReportTitle,
		nr.Id as NewMetaReportId, nmr.Title as NewReportTitle,
		mtt.MetaTemplateTypeId, mtt.TemplateName as TemplateType
	from MetaReportTemplateType mrtt
	inner join MetaReport mr on mrtt.MetaReportId = mr.Id
	inner join MetaTemplateType mtt on mrtt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	inner join @newReports nr on mrtt.MetaReportId = nr.CompanionFor_MetaReportId
	inner join MetaReport nmr on nr.Id = nmr.Id
) s
on (t.MetaReportId = s.NewMetaReportId and t.MetaTemplateTypeId = s.MetaTemplateTypeId)
when not matched then insert (MetaReportId, MetaTemplateTypeId)
values (s.NewMetaReportId, s.MetaTemplateTypeId)
output
	'Adding MetaReportTemplateType records to accompany current report' as __AddingMetaReportTemplateTypeRecordsToAccompanyCurrentReport,
	deleted.Id, s.CurrentReportId, s.CurrentReportTitle, inserted.MetaTemplateTypeId, s.TemplateType,
	inserted.MetaReportId, s.NewReportTitle
;

--commit;
--rollback;
