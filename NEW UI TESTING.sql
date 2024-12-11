use []
/********************Generic client setting bits*********************/
SELECT 
	CASE 
		WHEN
		PublicSearch = 1
		THEN 'Enabled'
	ELSE 'OFF'
END AS [Public Search],
	CASE
		WHEN
		AllowReactivation = 1
		THEN 'Enabled'
	ELSE 'OFF'
END AS [Reactivation],
	CASE 
		WHEN
		AllowNotes = 1
		THEN 'Enabled'
	ELSE 'OFF'
END AS [AllowNotes], 
	CASE 
		WHEN
		AllowAnonymousAllFieldsReport = 1
		THEN 'Enabled'
	ELSE 'OFF'
END AS [Public Reports],  
	CASE 
		WHEN
		EnableCBManagement = 1
		THEN 'Enabled'
	ELSE 'OFF'
END AS [CB Managment],
	CASE 
		WHEN
		EnableCrossListing = 1
		THEN 'Enabled'
	ELSE 'OFF'
END AS [Cross Listing],
	CASE 
		WHEN
		EnableNewCatalog = 1
		THEN 'Enabled'
	ELSE 'OFF'
END AS [Catalog],
	CASE 
		WHEN
		EnableOrgManagementTool = 1
		THEN 'Enabled'
	ELSE 'OFF'
END AS [Org Managment],
c.Code AS [Client]
	FROM config.ClientSetting AS cc
	INNER JOIN Client AS c on cc.ClientId = c.Id
	WHERE c.Active = 1

	/********************Look up Manager*********************/
SELECT DISTINCT 
CASE
	WHEN cl.Id IS NOT NULL
		THEN 'Enabled'
	ELSE 'OFF'
END AS [LookUpManager]
FROM ClientLookupType AS cl
	INNER JOIN Client AS c on cl.ClientId = c.Id
WHERE c.Active = 1

/********************Group Vote*********************/
SELECT DISTINCT 
CASE
	WHEN pg.Id IS NOT NULL
		THEN 'Enabled'
	ELSE 'OFF'
END AS [Group Vote]
FROM PositionGroup AS pg	--group vote
	INNER JOIN Client AS c on pg.ClientId = c.Id
WHERE c.Active = 1

/********************Custom Workflow Conditions*********************/
SELECT DISTINCT
	'Custom Workflow Condition exist' AS [Custom Workflow Condition],
	pt.Title AS [Proposal Type],
	wf.ConditionSQL AS [ConditionSql],
	wf.Description AS [Condition Definition],
	po.Title AS [Position]
FROM WorkflowCondition AS wf
	INNER JOIN Step AS s on s.WorkflowConditionId = wf.Id
	INNER JOIN StepLevel AS sl on s.StepLevelId = sl.Id
	INNER JOIN ProcessVersion AS pv on sl.ProcessVersionId = pv.Id
	INNER JOIN Process AS p on pv.ProcessId = p.Id
	INNER JOIN ProcessProposalType AS ppt on ppt.ProcessId = p.Id
	INNER JOIN ProposalType AS pt on ppt.ProposalTypeId = pt.Id
	INNER JOIN Position AS po on s.PositionId = po.Id
	INNER JOIN Client As c on po.ClientId = c.Id
WHERE wf.Active = 1
	AND s.Active = 1
	AND pv.Active = 1 
	AND pv.EndDate IS NULL
	AND p.Active = 1
	AND pt.DeletedDate IS NULL
	AND pt.Active = 1
	AND po.Active = 1
	AND c.Active = 1

/********************Custom Org Binding*********************/
SELECT 
	'Custom Org Binding' AS [Custom Org Binding],
	msf.DisplayName AS [Field],
	pt.Title AS [Proposal Type],
	p.Title AS [Postion]
FROM StepToSelectedFieldMapping AS sts
	INNER JOIN Step As s on sts.StepId = s.Id
	INNER JOIN Position AS p on s.PositionId = p.Id
	INNER JOIN MetaSelectedField AS msf on sts.MetaSelectedFieldId = msf.MetaSelectedFieldId
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	INNER JOIN ProposalType AS pt on pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	INNER JOIN Client AS c on pt.ClientId = c.Id
WHERE pt.Active = 1
	AND mtt.Active = 1
	AND mt.Active = 1
	AND mt.EndDate IS NULL
	AND c.Active = 1

/********************CrossListing*********************/
SELECT DISTINCT 
CASE
	WHEN cl.Id IS NOT NULL
		THEN 'Has Crosslistings'
	ELSE 'OFF'
END AS [Existing CrossListings]
FROM CrossListing AS cl--cross listing
	INNER JOIN Client AS c on cl.ClientId = c.Id
WHERE cl.Active = 1
	AND c.Active = 1

/*****************************Proposal Validation*************************************************/
SELECT 
	'Proposal Validation' AS [Proposal Validation],
	mcp.CommandSQL AS [SQL],
	pt.Title AS [Proposal Type]
FROM MetaCommandProcessor AS mcp
	INNER JOIN MetaCommandProcessorMap AS mcpa on mcpa.MetaCommandProcessorId = mcp.Id
	INNER JOIN ProposalType AS pt on mcpa.ProposalTypeId = pt.Id
	INNER JOIN Client AS c on pt.ClientId = c.Id
WHERE pt.Active = 1
	AND mcpa.Active = 1
	AND c.Active = 1

/****************************Section Validation*****************************************/
SELECT 
	'Section Validation' AS [Section Validation],
	mca.Description AS [Description],
	mca.CustomMessage AS [Custom Message],
	msq.SqlStatement AS [SQL],
	mss2.SectionName AS [Tab],
	pt.Title AS [Proposal Type]
FROM MetaControlAttribute AS mca
	INNER JOIN MetaSqlStatement AS msq on mca.MetaSqlStatementId = msq.Id
	INNER JOIN MetaSelectedSection AS mss on mca.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	INNER JOIN ProposalType AS pt on pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	INNER JOIN Client As c on pt.ClientId = c.Id
WHERE pt.Active = 1
	AND mtt.Active = 1
	AND mt.Active = 1
	AND c.Active = 1

/***********************************Test all Proposal Types****************************************/
--;WITH RankedTemplates AS (
--    SELECT
--        pt.Title,
--        mtt.TemplateName,
--        ROW_NUMBER() OVER (PARTITION BY mtt.TemplateName ORDER BY pt.Title) AS RowNum
--    FROM ProposalType AS pt
--    INNER JOIN MetaTemplateType AS mtt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--		INNER JOIN Client AS c on mtt.ClientId = c.Id
--    WHERE mtt.TemplateName IN (
--        SELECT DISTINCT TemplateName FROM MetaTemplateType WHERE Active = 1
--			)
--		AND pt.Active = 1
--		AND c.Active = 1
--)
--SELECT Title, TemplateName, 'Unique Templates' AS [Unique Templates]
--FROM RankedTemplates
--WHERE RowNum = 1;

/**************************************Public Reports***********************************************/
SELECT 
'Public Reports' AS [Public Reports],
mr.Title AS [Report Title]
FROM MetaReport AS mr
	INNER JOIN Client AS c on mr.ClientId = c.Id
WHERE JSON_VALUE(ReportAttributes, '$.isPublicReport') = 'true'
	and mr.Id in (
		SELECT DISTINCT mr.Id FROM MetaReport AS mr
		INNER JOIN MetaReportTemplateType AS mrtt on mrtt.MetaReportId = mr.Id
		INNER JOIN MetaReportActionType AS mrat on mrat.MetaReportId = mr.Id
		)
	AND c.Active = 1

/**************************************Reports and their Proposal Types they are mapped to**********/
--SELECT DISTINCT
--	mr.Title AS [Report Name],
--	pt.Title AS [Proposal Type]
--FROM MetaReport AS mr
--	INNER JOIN MetaReportActionType AS mrat on mrat.MetaReportId = mr.Id
--	INNER JOIN MetaReportTemplateType AS mrtt on mrtt.MetaReportId = mr.Id
--	INNER JOIN ProcessActionType AS pat on mrat.ProcessActionTypeId = pat.Id
--	INNER JOIN MetaTemplateType AS mtt on mrtt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	INNER JOIN ProposalType AS pt on pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	INNER JOIN Client As c on pt.ClientId = c.Id
--WHERE mrtt.Active = 1
--	AND pt.Active = 1
--	AND c.Active = 1
--order by pt.Title

/**************************************Ids for unique templates**********************************/
DECLARE @TABLE TABLE (Id int)
INSERT INTO @TABLE
SELECT DISTINCT mt.MetaTemplateId
FROM MetaTemplate AS mt 
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mt.Active = 1
AND mtt.IsPresentationView = 0
AND mtt.Active = 1
AND mt.IsDraft = 0

;WITH NumberedResults AS (
    SELECT
        t.Id AS TemplateId,
        c.Id AS CourseId,
        p.Id AS ProgramId,
        m.Id AS ModuleId,
        pkg.Id AS PackageId,
		cl.Title AS Client,
        ROW_NUMBER() OVER (PARTITION BY t.Id ORDER BY c.Id, p.Id, m.Id, pkg.Id) AS RowNum
    FROM @TABLE AS t
    LEFT JOIN Course AS c ON c.MetaTemplateId = t.Id AND c.Active = 1
    LEFT JOIN Program AS p ON p.MetaTemplateId = t.Id AND p.Active = 1
    LEFT JOIN Module AS m ON m.MetaTemplateId = t.Id AND m.Active = 1
    LEFT JOIN Package AS pkg ON pkg.MetaTemplateId = t.Id
	LEFT JOIN Client cl ON c.ClientId = cl.Id OR p.ClientId = cl.Id OR m.ClientId = cl.Id OR pkg.ClientId = cl.Id
		WHERE (c.Id IS NOT NULL OR p.Id IS NOT NULL OR m.Id IS NOT NULL OR pkg.Id IS NOT NULL)
		AND cl.Active = 1
)
SELECT
    TemplateId,
    CourseId AS [Course],
    ProgramId AS [Program],
    ModuleId AS [Module],
    PackageId AS [Package],
		Client AS [Client]
FROM NumberedResults
WHERE RowNum = 1

/********************Static Text*********************/
--SELECT 
--	'Static Text in new Form "Broken on AS of 10/10/203, will be fixed 10/19/2023"' AS [Text],
--	msf.DisplayName AS [Field Name],
--	mss2.SectionName AS [Tab],
--	pt.Title AS [Proposal Type] 
--FROM MEtaSelectedField AS msf
--	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
--	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
--	INNER JOIN MetaTemplate AS mt ON mss2.MetaTemplateId = mt.MetaTemplateId
--	INNER JOIN MetaTemplateType AS mtt ON mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	INNER JOIN ProposalType AS pt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	INNER JOIN Client As c on pt.ClientId = c.Id
--WHERE mss2.MetaSectionTypeId = 30
--	AND msf.MetaAvailableFieldId IS NULL
--	AND (msf.LabelVisible IS NULL or msf.LabelVisible = 1)
--	AND c.Active = 1

/**********************OL's with no list item type***************/
SELECT DISTINCT 
	mbs.ForeignTable AS [Table],
	pt.Title AS [Proposal Type],
	mss2.SectionName AS [Tab Name],
	mss.SectionName AS [Section Name],
	'OL with no list item type'
FROM
	MetaSelectedSection AS mss
INNER JOIN MetaSelectedSection As mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaBaseSchema AS mbs on mss.MetaBaseSchemaId = mbs.Id
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN ProposalType As pt on pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mss.MetaSectionTypeId in (16, 31, 2, 500) 
	AND  mbs.ForeignTable not in (
		SELECT ListItemTableName FROM ListItemType WHERE Active = 1
		)
	AND pt.Active = 1
	AND mt.EndDate IS NULL
and mss.SectionName <> 'Catalog Block'

/**********************Show Hide*****************************/
--SELECT
--    msf.DisplayName AS [Trigger Field],
--    mss4.SectionName AS [Tab of trigger field],
--    mss.SectionName AS [Show/Hide Section],
--    mss2.SectionName AS [Tab of showhide],
--    mds.SubscriberName AS [Name of show hide],
--    pt.Title AS [Proposal Type],
--    mdrt.RuleTypeName AS [Rule],
--    eot.Title AS [operator],
--    Operand2Literal AS [Value],
--    CASE WHEN mfkcc.CustomSql IS NULL THEN  mfkcb.CustomSql  ELSE NULL END AS [Query]
--FROM
--    MetaDisplaySubscriber AS mds
--INNER JOIN MetaSelectedSection AS mss ON mds.MetaSelectedSectionId = mss.MetaSelectedSectionId
--INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
--INNER JOIN MetaDisplayRule AS mds2 ON mds.MetaDisplayRuleId = mds2.Id
--INNER JOIN Expression AS e ON mds2.ExpressionId = e.Id
--INNER JOIN ExpressionPart AS ep ON ep.ExpressionId = e.Id
--INNER JOIN MetaTemplate AS mt ON mss2.MetaTemplateId = mt.MetaTemplateId
--INNER JOIN MetaTemplateType AS mtt ON mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--INNER JOIN ProposalType AS pt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--INNER JOIN MetaSelectedField AS msf ON mds2.MetaSelectedFieldId = msf.MetaSelectedFieldId
--INNER JOIN MetaSelectedSection AS mss3 ON msf.MetaSelectedSectionId = mss3.MetaSelectedSectionId
--INNER JOIN MetaSelectedSection AS mss4 ON mss3.MetaSelectedSection_MetaSelectedSectionId = mss4.MetaSelectedSectionId
--INNER JOIN MetaDisplayRuleType AS mdrt ON mds2.MetaDisplayRuleTypeId = mdrt.Id
--INNER JOIN ExpressionOperatorType AS eot ON ep.ExpressionOperatorTypeId = eot.Id
--LEFT JOIN MetaForeignKeyCriteriaClient AS mfkcc ON msf.MetaForeignKeyLookupSourceId = mfkcc.Id
--LEFT JOIN MetaAvailableField AS maf ON msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
--LEFT JOIN MetaForeignKeyCriteriaBase AS mfkcb ON maf.MetaForeignKeyLookupSourceId = mfkcb.Id
--WHERE Operand2Literal IS NOT NULL
--    AND pt.Active = 1
--    AND mt.EndDate IS NULL
--    AND mtt.Active = 1
--Order BY pt.Title
---------Paste Query below to run it to test what the value stands for in the show hide
DECLARE @ClientId int = (SELECT TOP 1 Id FROM Client WHERE Active = 1) --or change if district

/***********************Check List with more then 1 field in them***********************/
--select 
--mss.SectionName AS [Section],
--mss2.SectionName AS [Tab],
--pt.Title AS [Proposal Type],
--mt.MetaTemplateId AS [Template Id]
--from MetaSelectedSection mss
--	INNER JOIN MetaSelectedField msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
--	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
--	INNER JOIN MetaTemplate AS mt ON mss2.MetaTemplateId = mt.MetaTemplateId
--	INNER JOIN MetaTemplateType AS mtt ON mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	INNER JOIN ProposalType AS pt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	INNER JOIN Client As c on pt.ClientId = c.Id
--where mss.MetaSectionTypeId = 3
--	AND c.Active = 1
--group by mss.SectionName, mss2.SectionName, pt.Title, mt.MetaTemplateId
--having count(msf.MetaSelectedFieldId) > 1
--order by mt.MetaTemplateId

--DECLARE @TABLE2 TABLE (Id int)
--INSERT INTO @TABLE2
--select DISTINCT
--mt.MetaTemplateId AS [Template Id]
--from MetaSelectedSection mss
--	INNER JOIN MetaSelectedField msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
--	INNER JOIN MetaTemplate As mt on mss.MetaTemplateId = mt.MetaTemplateId
--where mss.MetaSectionTypeId = 3
--group by mt.MetaTemplateId
--having count(msf.MetaSelectedFieldId) > 1

--;WITH NumberedResults2 AS (
--    SELECT
--        t.Id AS TemplateId,
--        c.Id AS CourseId,
--        p.Id AS ProgramId,
--        m.Id AS ModuleId,
--        pkg.Id AS PackageId,
--		cl.Title AS Client,
--        ROW_NUMBER() OVER (PARTITION BY t.Id ORDER BY c.Id, p.Id, m.Id, pkg.Id) AS RowNum
--    FROM @TABLE2 AS t
--    LEFT JOIN Course AS c ON c.MetaTemplateId = t.Id AND c.Active = 1
--    LEFT JOIN Program AS p ON p.MetaTemplateId = t.Id AND p.Active = 1
--    LEFT JOIN Module AS m ON m.MetaTemplateId = t.Id AND m.Active = 1
--    LEFT JOIN Package AS pkg ON pkg.MetaTemplateId = t.Id
--	LEFT JOIN Client cl ON c.ClientId = cl.Id OR p.ClientId = cl.Id OR m.ClientId = cl.Id OR pkg.ClientId = cl.Id
--		WHERE (c.Id IS NOT NULL OR p.Id IS NOT NULL OR m.Id IS NOT NULL OR pkg.Id IS NOT NULL)
--		AND cl.Active = 1
--)
--SELECT
--    TemplateId,
--    CourseId AS [Course],
--    ProgramId AS [Program],
--    ModuleId AS [Module],
--    PackageId AS [Package],
--		Client AS [Client]
--FROM NumberedResults2
--WHERE RowNum = 1

--/*******************Required checkboxes*****************************/
--SELECT metaSelec FROM MetaSelectedField WHERE MetaPresentationTypeId = 5 AND IsRequired = 1

/*******************************************************************/
DECLARE @TABLE5 INTEGERS
INSERT INTO @TABLE5
SELECT DISTINCT m1.Id
FROM MetaSelectedFieldAttribute m1
INNER JOIN (
    SELECT name, value, metaselectedfieldId
    FROM MetaSelectedFieldAttribute
    GROUP BY name, value, metaselectedfieldId
    HAVING COUNT(*) > 1
) m2 ON m1.name = m2.name AND m1.value = m2.value AND m1.metaselectedfieldId = m2.metaselectedfieldId;

SELECT *, 'Duplicate Attributes' FROM @TABLE5


/*
	Audit Script for helptext
*/

If (select Count(msfa1.MetaSelectedFieldId )
from MetaSelectedFieldAttribute msfa1
where Name = 'SubText'
And Not Exists 
	(
	select msfa2.MetaSelectedFieldId 
	from MetaSelectedFieldAttribute msfa2
	where Name = 'HelpText'
		And msfa2.MetaSelectedFieldId
		= msfa1.MetaSelectedFieldId 
	)
) > 0
BEGIN
	Declare @SubTextFieldWithNoHelpText Nvarchar(16) =
	(select Cast(Count(msfa1.MetaSelectedFieldId )as Nvarchar)
from MetaSelectedFieldAttribute msfa1
where Name = 'SubText'
And Not Exists 
	(
	select msfa2.MetaSelectedFieldId 
	from MetaSelectedFieldAttribute msfa2
	where Name = 'HelpText'
		And msfa2.MetaSelectedFieldId
		= msfa1.MetaSelectedFieldId 
	)
) 
	Select @SubTextFieldWithNoHelpText + ' fields have subtext but no helptext.'As 'Warning:'

	select msfa1.MetaSelectedFieldId  as 'Ids for fields with subtext but no help text'
from MetaSelectedFieldAttribute msfa1
where Name = 'SubText'
And Not Exists 
	(
	select msfa2.MetaSelectedFieldId 
	from MetaSelectedFieldAttribute msfa2
	where Name = 'HelpText'
		And msfa2.MetaSelectedFieldId
		= msfa1.MetaSelectedFieldId 
	)
	
END

SELECT *, 'Required Checkbox or Query Text' FROM MetaSelectedField WHERE 
(MetaPresentationTypeId = 5
or 
(MetaPresentationTypeId = 1 and FieldTypeId = 5)
or MetaPresentationTypeId = 103)
AND IsRequired = 1

SELECT 
	mtt.MetaTemplateTypeId,
	mtt.TemplateName as MetaTemplateType,
	mt.MetaTemplateId,
	mt.Title As MetaTemplate,
	mss.MetaSelectedSectionId,
	mss.SectionName,
	msf.MetaSelectedFieldId,
	msf.DisplayName,
	mpt.DisplayAction As MetaPresentationType,
	'This field is set up as a old calculated field need add a backing store and set up as a new calculated field' As [Description of Issue]
FROM MetaSelectedField msf
	Inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	Inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
	Inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	Inner join MetaPresentationType mpt on msf.MetaPresentationTypeId = mpt.Id
WHERE MetaAvailableFieldId is null
	and exists (
		SELECT 1 FROM MetaFieldFormula mff 
		where mff.MetaSelectedFieldId = msf.MetaSelectedFieldId
	)
	and (mt.MetaTemplateId in (
	SELECT MetaTemplateId FROM Course
	UNION
	SELECT MetaTemplateId FROM Program
	UNION
	SELECT MetaTemplateId FROM Module
	)
	or mt.Active = 1)
Order By MetaTemplateTypeId,MetaTemplateId,MetaSelectedSectionId, MetaSelectedFieldId

--------------------------------------------------------------------------------------------
DECLARE @titleFieldsMAF integers
Insert into @titleFieldsMAF
SELECT
	maf.MetaAvailableFieldId
FROM ListItemType lit
	Inner join MetaAvailableField maf on maf.TableName = lit.ListItemTableName
		and maf.ColumnName = lit.ListItemTitleColumn

--SELECT 
--	mtt.MetaTemplateTypeId,
--	mtt.TemplateName as MetaTemplateType,
--	mt.MetaTemplateId,
--	mt.Title As MetaTemplate,
--	mss.MetaSelectedSectionId,
--	mss.SectionName,
--	msf.MetaSelectedFieldId,
--	msf.DisplayName,
--	mpt.DisplayAction As MetaPresentationType,
--	'This field is the title field for a list Item type but does not have the list ''listitemtype'' metaselectedfieldAttribute' As [Description of Issue]
--FROM MetaSelectedField msf
--	Inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
--	Inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
--	Inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	Inner join MetaPresentationType mpt on msf.MetaPresentationTypeId = mpt.Id
--	Inner join @titleFieldsMAF tfmaf on msf.MetaAvailableFieldId = tfmaf.Id
--WHERE Not exists(
--	SELECT 1 FROM MetaSelectedFieldAttribute msfa
--	WHERE Name = 'listitemtype'
--		and msfa.MetaSelectedFieldId = msf.MetaSelectedFieldId
--)
--Union
--SELECT 
--	mtt.MetaTemplateTypeId,
--	mtt.TemplateName as MetaTemplateType,
--	mt.MetaTemplateId,
--	mt.Title As MetaTemplate,
--	mss.MetaSelectedSectionId,
--	mss.SectionName,
--	msf.MetaSelectedFieldId,
--	msf.DisplayName,
--	mpt.DisplayAction As MetaPresentationType,
--	'This field the Subject field for a OL that has the Course field as a list item type title but does not have the list ''listitemtype'' metaselectedfieldAttribute' As [Description of Issue]
--FROM MetaSelectedField msf
--	Inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
--	Inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
--	Inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	Inner join MetaPresentationType mpt on msf.MetaPresentationTypeId = mpt.Id
--	Inner Join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
--		and maf.ColumnName = 'SubjectId'
--WHERE Not exists(
--	SELECT 1 FROM MetaSelectedFieldAttribute msfa
--	WHERE Name = 'listitemtype'
--		and msfa.MetaSelectedFieldId = msf.MetaSelectedFieldId
--)
--	and Exists(
--		SELECT 1 FROM MetaAvailableField maf2
--			Inner Join @titleFieldsMAF tfmaf on maf2.MetaAvailableFieldId = tfmaf.Id
--		WHERE maf2.TableName = maf.TableName
--	)
--Union
--SELECT 
--	mtt.MetaTemplateTypeId,
--	mtt.TemplateName as MetaTemplateType,
--	mt.MetaTemplateId,
--	mt.Title As MetaTemplate,
--	mss.MetaSelectedSectionId,
--	mss.SectionName,
--	msf.MetaSelectedFieldId,
--	msf.DisplayName,
--	mpt.DisplayAction As MetaPresentationType,
--	'This field is the title field for a list Item type but is a RTE. This is not allowed.' As [Description of Issue],
--	msf.MetaAvailableFieldId
--FROM MetaSelectedField msf
--	Inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
--	Inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
--	Inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	Inner join MetaPresentationType mpt on msf.MetaPresentationTypeId = mpt.Id
--	Inner join @titleFieldsMAF tfmaf on msf.MetaAvailableFieldId = tfmaf.Id
--WHERE mpt.Id in (25,26)
--Union
--SELECT 
--	mtt.MetaTemplateTypeId,
--	mtt.TemplateName as MetaTemplateType,
--	mt.MetaTemplateId,
--	mt.Title As MetaTemplate,
--	mss.MetaSelectedSectionId,
--	mss.SectionName,
--	msf.MetaSelectedFieldId,
--	msf.DisplayName,
--	mpt.DisplayAction As MetaPresentationType,
--	'This field is the title field for a list Item type but parent section is not a OL. The title field for a List item type should be at the top level of detail of a OL.' As [Description of Issue]
--FROM MetaSelectedField msf
--	Inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
--	Inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
--	Inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
--	Inner join MetaPresentationType mpt on msf.MetaPresentationTypeId = mpt.Id
--	Inner join @titleFieldsMAF tfmaf on msf.MetaAvailableFieldId = tfmaf.Id
--WHERE mss.MetaSectionTypeId not in (31,500)
--Order By MetaTemplateTypeId,MetaTemplateId,MetaSelectedSectionId, MetaSelectedFieldId
---------------------------------------------------------------------------------------
-- ==============================
-- @TemplateMetadata
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


declare @TemplateMetadata table
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


insert into @TemplateMetadata (
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

/* =========================
** Block
** =========================
*/
select 'Sections with multiple show/hide rules' as [AuditMessage]
, fn2.MetaSelectedSectionId
, fn2.ExpressionCount
, tabs.TabMSSSectionName as Tab
, 'TemplateInfo=>'
, t.*
from (
	select fn.MetaSelectedSectionId
	, count(fn.Id) as [ExpressionCount]
	from (
		select distinct mds.MetaSelectedSectionId
		, e.Id
		from Expression e
			inner join ExpressionPart ep on e.Id = ep.ExpressionId
			inner join MetaDisplayRule mdr on ep.ExpressionId = mdr.ExpressionId
			inner join MetaDisplaySubscriber mds on mdr.Id = mds.MetaDisplayRuleId
			inner join MetaSelectedSection mss on mds.MetaSelectedSectionId = mss.MetaSelectedSectionId
			inner join @TemplateMetadata t on mss.MetaTemplateId = t.MT_Id
		where t.TemplateInUsed = 1
	) fn
	group by fn.MetaSelectedSectionId
) fn2
	inner join MetaSelectedSection mss on fn2.MetaSelectedSectionId = mss.MetaSelectedSectionId
	inner join @TemplateMetadata t on mss.MetaTemplateId = t.MT_Id
	inner join @MSSTabs tabs on mss.MetaSelectedSectionId = tabs.MSSId
where fn2.ExpressionCount > 1
and MTT_Name not like '%Catalog%'
order by t.MT_Id


;with MultipleFieldsWithSameMAF as (
	select t.MT_Id, msf.MetaAvailableFieldId, count(msf.MetaSelectedFieldId) as MSFCount
	from MetaSelectedField msf
		inner join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
		inner join MetaSelectedSection mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
		inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
		inner join @TemplateMetadata t on mt.MetaTemplateId = t.MT_Id
			and t.TemplateInUsed = 1
	group by t.MT_Id, msf.MetaAvailableFieldId
	having count(msf.MetaSelectedFieldId) > 1
)
, FieldHasShowHide as (
	select msf.MetaSelectedFieldId
	, msf.MetaAvailableFieldId
	, count(e.Id) as ExpressionCount
	from MetaSelectedField msf
		inner join MetaDisplaySubscriber mds on msf.MetaSelectedFieldId = mds.MetaSelectedFieldId
		inner join MetaDisplayRule mdr on mds.MetaDisplayRuleId = mdr.Id
		inner join ExpressionPart ep on mdr.ExpressionId = ep.ExpressionId
		inner join Expression e on ep.ExpressionId = e.Id
	group by msf.MetaSelectedFieldId, msf.MetaAvailableFieldId
)
	select 'Multiple fields with same MAF and has Show/Hide' as AuditMessage
	, m.MT_Id as MetaTemplateId
	, t.EntityCount as MetaTemplateEntityCount
	, t.ActiveTemplate as MetaTemplateActive
	, tabs.TabMSSSectionName as Tab
	, msf.MetaSelectedFieldId
	, msf.DisplayName
	, msf.MetaAvailableFieldId
	, sh.ExpressionCount
	from MultipleFieldsWithSameMAF m
		inner join MetaAvailableField maf on m.MetaAvailableFieldId = maf.MetaAvailableFieldId
		inner join MetaSelectedField msf on maf.MetaAvailableFieldId = msf.MetaAvailableFieldId
		inner join MetaSelectedSection mss on m.MT_Id = mss.MetaTemplateId
									and msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
		inner join @MSSTabs tabs on mss.MetaSelectedSectionId = tabs.MSSId
		inner join @TemplateMetadata t on mss.MetaTemplateId = t.MT_Id
		left join FieldHasShowHide sh on msf.MetaSelectedFieldId = sh.MetaSelectedFieldId
	where exists (
		select 1
		from FieldHasShowHide sh
		where maf.MetaAvailableFieldId = sh.MetaAvailableFieldId
	)
	order by m.MT_Id, m.MetaAvailableFieldId
	-----------------------------------------------------------------------
	-- ==============================
-- @TemplateMetadata
-- ==============================
declare @reportInUsed2 table (ReportId int, EntityCount int, reportTemplateId int)

insert into @reportInUsed2
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


declare @TemplateMetadata2 table
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


insert into @TemplateMetadata2 (
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
		from @reportInUsed2 riu
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

declare @MSSTabs2 table
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
	insert into @MSSTabs2 (MSSId, TabMSSId, TabMSSSectionName, IsTab)
	select p.MSSId, p.MainParentId, mss.SectionName, p.IsTab
	from Pages p
		inner join MetaSelectedSection mss on p.MainParentId = mss.MetaSelectedSectionId




select t.MT_Id as MetaTemplateId
, t.EntityCount as MetaTemplateEntityCount
, t.ActiveTemplate as MetaTemplateActive
, tabs.TabMSSSectionName as Tab
, mss.MetaSelectedSectionId
, mssa.[Name]
, mssa.[Value]
from MetaSelectedSection mss
	inner join MetaSelectedSectionAttribute mssa on mss.MetaSelectedSectionId = mssa.MetaSelectedSectionId
	inner join @TemplateMetadata2 t on mss.MetaTemplateId = t.MT_Id
	inner join @MSSTabs2 tabs on mss.MetaSelectedSectionId = tabs.MSSId
where mss.MetaSectionTypeId = 31 -- CurriQUnetlist
and mssa.[Name] not in (
	'NoRequireOption',
	'AllowConditions',
	'AllowCalcExclude',
	'AllowCalcOverride',
	'CalcMinLabel',
	'CalcMaxLabel',
	'triggersectionrefresh'
)
------------------------------------------------------------------------------
Drop table if exists #Results

;with ProgramSequenceQuery as (
	Select MetaSelectedSectionId, MetaTemplateId, MetaSelectedSection_MetaSelectedSectionId as TabSection, 'ProgramSequence' as TableName
	from MetaSelectedSection 
	where MetaBaseSchemaId = 857 --ProgramSequence
), ProgramCourseQuery as ( 
	Select mss1.MetaSelectedSectionId, mss1.MetaTemplateId,
	mss2.MetaSelectedSection_MetaSelectedSectionId as TabSection, 'ProgramCourse' as TableName
	from MetaSelectedSection mss1
	inner join MetaSelectedSection mss2 on mss2.MetaSelectedSectionId
	= mss1.MetaSelectedSection_MetaSelectedSectionId
		And mss1.MetaBaseSchemaId = 164 --ProgramCourse
		And mss1.MetaSectionTypeId in (31,500)
), OutcomeMatchingQuery as ( 
	Select MetaSelectedSectionId, MetaTemplateId, MetaSelectedSection_MetaSelectedSectionId as TabSection, 'ProgramOutcomeMatching' as TableName
	from MetaSelectedSection
	Where MetaBaseSchemaId	= 204 --ProgramOutcomeMatching
) Select 	ps.MetaTemplateId,
		ps.MetaSelectedSectionId as ProgramSequenceSectionId
		,ps.TabSection as ProgramSequenceTabId
		,pc.MetaSelectedSectionId as ProgramCourseSectionId
		,pc.TabSection as ProgramCourseTabId
		,om.MetaSelectedSectionId as OutcomeMatchingSectionId
		,om.TabSection as OutcomeMatchingTabId
	into #Results
from ProgramSequenceQuery ps
	left join ProgramCourseQuery pc 
		on pc.MetaTemplateId = ps.MetaTemplateId
	left join OutcomeMatchingQuery om 
		on om.MetaTemplateId = ps.MetaTemplateId

Declare @CountProgramCourseTemplates int;
Declare @CountPLOSLOMappingTemplates int;

If (Select Count(*) from #Results) > 0
BEGIN
		Set @CountProgramCourseTemplates =
				(
					select Count(ProgramCourseSectionId) 
					From #Results 
				)
		Set @CountPLOSLOMappingTemplates =
				(
					select Count(OutcomeMatchingSectionId) 
					From #Results 
				)
		If @CountProgramCourseTemplates > 0
		Begin
			Select Cast(@CountProgramCourseTemplates As Nvarchar(8)) + ' Templates Need the triggersectionrefresh Attribute for Program Mapper'

			select ProgramCourseSectionId 
			From #Results 
			Where ProgramCourseSectionId is not NULL
		End
		If @CountPLOSLOMappingTemplates > 0
		Begin
			Select Cast(@CountPLOSLOMappingTemplates As Nvarchar(8)) +  ' Templates Need the triggersectionrefresh Attribute for PLO-SLO mapping'

			select OutcomeMatchingSectionId 
			From #Results 
			Where OutcomeMatchingSectionId is not NULL
		End
END
--------------------------------------------------------------------
--fields
select et.Title, mtt.TemplateName, mss2.SectionName as ParentSectionName, msf.DisplayName, 'html field' as [html]
from MetaSelectedField msf
    inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
    inner join MetaSelectedSection mss2 on mss2.MetaSelectedSectionId = mss.MetaSelectedSection_MetaSelectedSectionId
    inner join MetaTemplate mt on mt.MetaTemplateId = mss.MetaTemplateId
    inner join MetaTemplateType mtt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    inner join EntityType et on et.Id = mtt.EntityTypeId
where msf.DisplayName <> dbo.Format_RemoveAccents(dbo.stripHtml(msf.DisplayName))
	and msf.MetaAvailableFieldId is not null
	and mtt.IsPresentationView = 0
	and mt.Active = 1
	and mtt.Active = 1
order by et.Title

--sections
select et.Title, mtt.TemplateName, mss2.SectionName as ParentSectionName, mss.SectionName, dbo.stripHtml(mss.SectionName), mss.SectionDescription, 'html' as [html]
from MetaSelectedSection mss
    inner join MetaSelectedSection mss2 on mss2.MetaSelectedSectionId = mss.MetaSelectedSection_MetaSelectedSectionId
    inner join MetaTemplate mt on mt.MetaTemplateId = mss.MetaTemplateId
    inner join MetaTemplateType mtt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    inner join EntityType et on et.Id = mtt.EntityTypeId
where mss.SectionName <> dbo.Format_RemoveAccents(dbo.stripHtml(mss.SectionName))
	and mtt.IsPresentationView = 0
	and mt.Active = 1
	and mtt.Active = 1
order by et.Title
--------------------------------------------------------------------------------------------
-- Create a temporary table to hold the results
CREATE TABLE #TempTable (
    ID INT IDENTITY(1,1), -- Identity column for insertion order
    MetaSelectedSectionId INT,
    SectionName NVARCHAR(MAX),
    ParentSectionId INT,
    LevelName NVARCHAR(MAX),
    TemplateId INT,
    RowPosition INT
);

-- Your recursive CTE
WITH SectionHierarchy AS (
    -- Anchor member: select top-level sections
    SELECT
        MetaSelectedSectionId,
        ISNULL(SectionName, 'NO SECTION NAME') AS SectionName,
        MetaSelectedSection_MetaSelectedSectionId AS ParentSectionId,
        ISNULL(SectionName, 'NO SECTION NAME') AS Path,
        CONCAT(ISNULL(SectionName, 'NO SECTION NAME'), ' - Top Level') AS LevelName,
        mt.MetaTemplateId AS TemplateId,
        mss.RowPosition, -- Include RowPosition
        0 AS Level,
        ROW_NUMBER() OVER (PARTITION BY MetaSelectedSection_MetaSelectedSectionId ORDER BY mss.RowPosition) AS ParentOrder
    FROM
        MetaSelectedSection AS mss
    INNER JOIN 
        MetaTemplate AS mt ON mss.MetaTemplateId = mt.MetaTemplateId
    INNER JOIN 
        MetaTemplateType AS mtt ON mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
    WHERE
        MetaSelectedSection_MetaSelectedSectionId IS NULL
        AND mtt.IsPresentationView = 0
        AND mtt.Active = 1
        AND mt.Active = 1

    UNION ALL

    -- Recursive member: select child sections
    SELECT
        mss.MetaSelectedSectionId,
        ISNULL(mss.SectionName, 'NO SECTION NAME') AS SectionName,
        mss.MetaSelectedSection_MetaSelectedSectionId AS ParentSectionId,
        CONCAT(parent.Path, ' -> ', ISNULL(mss.SectionName, 'NO SECTION NAME')) AS Path,
        CONCAT(parent.LevelName, ' -> ', ISNULL(mss.SectionName, 'NO SECTION NAME')) AS LevelName,
        parent.TemplateId,
        mss.RowPosition, -- Include RowPosition
        parent.Level + 1 AS Level,
        parent.ParentOrder
    FROM
        MetaSelectedSection AS mss
    INNER JOIN
        SectionHierarchy AS parent ON mss.MetaSelectedSection_MetaSelectedSectionId = parent.MetaSelectedSectionId
)

-- Insert into the temporary table
INSERT INTO #TempTable (MetaSelectedSectionId, SectionName, ParentSectionId, LevelName, TemplateId, RowPosition)
SELECT
    MetaSelectedSectionId,
    SectionName,
    ParentSectionId,
    LevelName,
    TemplateId,
    RowPosition -- Include RowPosition
FROM
    SectionHierarchy
ORDER BY
    TemplateId, -- Group by MetaTemplateId
    ParentOrder, -- Order by ParentOrder to get parents first
    RowPosition; -- Then order by RowPosition within each level

-- Select from the temporary table
--SELECT ID, MetaSelectedSectionId FROM #TempTable ORDER BY ID; -- Order by the identity column

DECLARE @TABLE2 TABLE (orders int, fieldId int, formulaId int)
INSERT INTO @TABLE2
SELECT t.Id, msf.MetaSelectedFieldId, mff.Id FROM MetaFieldFormula AS mff
INNER JOIN MetaSelectedField AS msf on mff.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN #TempTable AS t on msf.MetaSelectedSectionId = t.MetaSelectedSectionId
order by t.ID --order


DECLARE @TABLE3 TABLE (orders int, fieldId int, formulaId int)
INSERT INTO @TABLE3
SELECT t.Id, msf.MetaSelectedFieldId, mffd.MetaFieldFormulaId FROM MetaFieldFormulaDependency AS mffd
INNER JOIN MetaSelectedField As msf on mffd.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN #TempTable AS t on msf.MetaSelectedSectionId = t.MetaSelectedSectionId
order by t.Id

IF EXISTS (
    SELECT 1
    FROM @TABLE2 AS t2
    INNER JOIN @TABLE3 AS t3 ON t2.formulaId = t3.formulaId
    WHERE t3.orders > t2.orders
)
BEGIN
    SELECT 
        CONVERT(NVARCHAR(MAX), t2.orders) AS [Field Order], 
        CONVERT(NVARCHAR(MAX), t2.fieldId) AS [Field Id], 
        CONVERT(NVARCHAR(MAX), t3.orders) AS [Dependencies order], 
        CONVERT(NVARCHAR(MAX), t3.fieldId) AS [Dependencies FieldId], 
        CONVERT(NVARCHAR(MAX), t2.formulaId) AS [FormulaId]
    FROM @TABLE2 AS t2
    INNER JOIN @TABLE3 AS t3 ON t2.formulaId = t3.formulaId
    WHERE t3.orders > t2.orders
    ORDER BY t2.fieldId
END
ELSE
BEGIN
    SELECT 'Pass' AS [Result]
END
-- Drop the temporary table
DROP TABLE #TempTable;

SELECT mfkcc.Id, CustomSql, msf.MetaSelectedFieldId, msf.MetaAvailableFieldId, msf.DisplayName FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaForeignKeyCriteriaClient AS mfkcc on mfkcc.Id = msf.MetaForeignKeyLookupSourceId
WHERE mfkcc.CustomSql like '%@ContextId%'
and mtt.Active = 1
and mt.Active = 1