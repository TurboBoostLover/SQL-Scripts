DECLARE @cp int = 10, -- SELECT * FROM curriculumpresentation
	@entityTypeId int = 2,
	@EntityList integers;

Insert into @EntityList
VALUES
(1089)


EXEC upRenderCurriculumPresentation 
	@curriculumpresentationID = @cp,
	@entityTypeId = @entityTypeId,
	@entityList = @EntityList,
	@outputFormatId = 5



--{"orderBy":"dbo.fnCourseNumberToNumeric(c.CourseNumber),SuffixCode","statusBaseMapping":[{"catalogStatusBaseId":1,"entityStatusBaseId":1},{"catalogStatusBaseId":1,"entityStatusBaseId":2},{"catalogStatusBaseId":2,"entityStatusBaseId":1},{"catalogStatusBaseId":2,"entityStatusBaseId":2},{"catalogStatusBaseId":4,"entityStatusBaseId":1},{"catalogStatusBaseId":4,"entityStatusBaseId":2},{"catalogStatusBaseId":4,"entityStatusBaseId":4},{"catalogStatusBaseId":4,"entityStatusBaseId":6},{"catalogStatusBaseId":5,"entityStatusBaseId":1},{"catalogStatusBaseId":5,"entityStatusBaseId":2},{"catalogStatusBaseId":5,"entityStatusBaseId":5},{"catalogStatusBaseId":6,"entityStatusBaseId":1},{"catalogStatusBaseId":6,"entityStatusBaseId":2},{"catalogStatusBaseId":6,"entityStatusBaseId":4},{"catalogStatusBaseId":6,"entityStatusBaseId":5},{"catalogStatusBaseId":6,"entityStatusBaseId":6},{"catalogStatusBaseId":7,"entityStatusBaseId":1},{"catalogStatusBaseId":7,"entityStatusBaseId":2},{"catalogStatusBaseId":7,"entityStatusBaseId":4},{"catalogStatusBaseId":7,"entityStatusBaseId":5},{"catalogStatusBaseId":7,"entityStatusBaseId":6}]}
--The parameter @curriculumPresentationId must be a valid CurriculumPresentation Id; the supplied value (9) was not found as an Id in the CurriculumPresentation table

--SELECT * FROM Semester

--The parameter @entityTypeId must be a valid EntityType Id; the supplied value (1091) was not found as an Id in the EntityType table

SELECT * FROM ProposalTypeRestriction