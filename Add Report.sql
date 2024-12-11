USE [];


DECLARE @reportId int = 44
DECLARE @reportTitle NVARCHAR(MAX) = 'Comparison'
DECLARE @newMT int = 9999
DECLARE @entityId int = 2	--1-Courses, 2-Programs, 6-Modules
DECLARE @reportType int = 6		--2-CourseCompare, 4-CourseAllFields, 6-Program/ModuleCompare, 13-Program/ModuleAllFields

DECLARE @reportAttribute NVARCHAR(MAX) = concat('{"reportTemplateId":', @newMt,'}')

INSERT INTO MetaReport
(Id,Title,MetaReportTypeId,OutputFormatId,ReportAttributes)
VALUES
(@reportId, @reportTitle, @reportType, 5, @reportAttribute)


INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
SELECT
	@reportId,
	mtt.MetaTemplateTypeId,
	GETDATE()
FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = @entityId
AND mt.Active = 1
AND mt.IsDraft = 0
AND mtt.Active = 1
AND mtt.IsPresentationView = 0

DECLARE @MAX INT = (SELECT MAX(ID) FROM MetaReportActionType) + 1

INSERT INTO MetaReportActionType
(Id, MetaReportId, ProcessActionTypeId)
VALUES
(@MAX,@reportId,1),
(@MAX + 1,@reportId,2),
(@MAX + 2,@reportId,3)


UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId = @newMT

