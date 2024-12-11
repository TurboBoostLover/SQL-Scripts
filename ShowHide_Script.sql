/* ----------------- Script for Show/Hide ----------------- */

DECLARE @TriggerselectedFieldId INT = NULL;     -----SET TRIGGER
-- The id for the field that triggers the show/hide 

DECLARE @TriggerselectedSectionId INT = NULL; 

DECLARE @displayRuleTypeId INT = 2;              
-- DisplayRuleType 1 = FieldValidation, 2 = FieldDisplay, 3 = FieldCalculation, 4 = SectionDisplay   
-- Always set to 2

DECLARE @ExpressionOperatorTypeId INT = 16;       
-- SELECT * FROM ExpressionOperatorType 
-- ExpressionOperatorType 16 = NotEqual - Operand 1 must not be the same value as Operand 2
-- Note: EOT 16 will throw an error if ComparisonDataType is 1

DECLARE @ComparisonDataTypeId INT = 3;           
-- ComparisonDataType 1 = Decimal, 2 = DateTime, 3 = String, 4 = Boolean    

DECLARE @Operand2Literal NVARCHAR(50) = NULL;  ---------SET VALUE
-- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked     
-- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
-- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
-- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.    

DECLARE @listenerSelectedFieldId INT = NULL;			------SET LISTENER

DECLARE @listenerSelectedSectionId INT = NULL;		------SET LISTENER
-- The id for the section that will show/hide based on the trigger

DECLARE @DisplayRuleName NVARCHAR(50) = 'Show/hide';    
DECLARE @SubscriberName NVARCHAR(50) = 'Show/hide';    
-- Inserts a new Expression Id into the Expression table 
-- This syntax is needed since the auto-incremented Id is the only field in the Expression table 

INSERT INTO Expression
    OUTPUT inserted.*    
	DEFAULT VALUES    
-- The new Expression Id you just inserted above    
	
DECLARE @expressionId INT;    
SET @expressionId = SCOPE_IDENTITY();    
-- Inserts a new ExpressionPart Id into the ExpressionPart table

INSERT INTO MetaDisplayRule (DisplayRuleName, DisplayRuleValue, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleTypeId, ExpressionId)    
	OUTPUT inserted.*    
	VALUES (@DisplayRuleName, NULL, @TriggerselectedFieldId, @TriggerselectedSectionId, @displayRuleTypeId, @expressionId)    
-- Inserts a new MetaDisplayRule into the MetaDisplayRule table based on the variable values chosen above
	
DECLARE @displayRuleId INT;    
	SET @displayRuleId = SCOPE_IDENTITY();
-- Creates a new Id for the MetaDisplayRule inserted above

INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)   
	OUTPUT inserted.*    
	VALUES (@expressionId, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL)   ----If need more parents for an or add here and adjust below accordingly 
-- The new ExpressionPart Id you just inserted above 
	
DECLARE @parentExpressionPartId INT;    
SET @parentExpressionPartId = SCOPE_IDENTITY();
-- Keep in mind that if this condition is true, it will hide the field or section  
-- Inserts a new ExpressionPart Id into the ExpressionPart table and makes the previous ExpressionPart Id the Parent_ExpressionPartId for this one


INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)    
	OUTPUT inserted.*    
	VALUES (@expressionId, @parentExpressionPartId, 1, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerSelectedFieldId, NULL, @Operand2Literal, NULL, NULL)  -----------compound rule add more here
	
	--- share rule
INSERT INTO MetaDisplaySubscriber (SubscriberName, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleId)    
	OUTPUT inserted.*    
	VALUES (@SubscriberName, @listenerSelectedFieldId, @listenerSelectedSectionId, @displayRuleId)
