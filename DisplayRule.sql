use sdccd

declare @topSectionId int = 108;
 
with hierarchy
as (
	select
		mds.MetaDisplayRuleId as ruleid,
		mdr.MetaSelectedFieldId as triggerid,
		mss.MetaSelectedSectionId as targetid,
		ep.Id as expressionpartid,
		ep.ExpressionOperatorTypeId,
		ep.Parent_ExpressionPartId,
		ep.ComparisonDataTypeId,
		ep.Operand1_MetaSelectedFieldId,
		ep.Operand2_MetaSelectedFieldId,
		ep.Operand2Literal,
		ep.Operand3_MetaSelectedFieldId,
		ep.Operand3Literal
	from
		MetaSelectedSection mss
		left join MetaDisplaySubscriber mds on mds.MetaSelectedSectionId = mss.MetaSelectedSectionId
		left join MetaDisplayRule mdr on mds.MetaDisplayRuleId = mdr.Id
		left join ExpressionPart ep on ep.ExpressionId = mdr.ExpressionId
	where
		mss.MetaSelectedSectionId = @topSectionId
 
	union all
 
	select
		mds.MetaDisplayRuleId as ruleid,
		mdr.MetaSelectedFieldId as triggerid,
		mss.MetaSelectedSectionId as targetid,
		ep.Id as expressionpartid,
		ep.ExpressionOperatorTypeId,
		ep.Parent_ExpressionPartId,
		ep.ComparisonDataTypeId,
		ep.Operand1_MetaSelectedFieldId,
		ep.Operand2_MetaSelectedFieldId,
		ep.Operand2Literal,
		ep.Operand3_MetaSelectedFieldId,
		ep.Operand3Literal
	from
		MetaSelectedSection mss
		inner join MetaDisplaySubscriber mds on mds.MetaSelectedSectionId = mss.MetaSelectedSectionId
		inner join MetaDisplayRule mdr on mds.MetaDisplayRuleId = mdr.Id
		inner join ExpressionPart ep on ep.ExpressionId = mdr.ExpressionId
		inner join hierarchy h on mss.MetaSelectedSection_MetaSelectedSectionId = h.targetid
)
select 
	ruleid,
	triggerid,
	targetid,
	expressionpartid,
	ExpressionOperatorTypeId,
	Parent_ExpressionPartId,
	ComparisonDataTypeId,
	Operand1_MetaSelectedFieldId,
	Operand2_MetaSelectedFieldId,
	Operand2Literal,
	Operand3_MetaSelectedFieldId,
	Operand3Literal
from 
	hierarchy
where ruleid is not null
order by
	ruleid
option(maxrecursion 5)