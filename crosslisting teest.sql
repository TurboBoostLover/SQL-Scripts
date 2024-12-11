use sac

SELECT DISTINCT
CONCAT(c.EntityTitle, ' (', sa.Title, ')', c.ID),
CONCAT(c3.EntityTitle, ' (', sa2.Title, ')', c3.Id)
FROM Course As c
INNER JOIN StatusAlias As sa on c.StatusAliasId = sa.Id
INNER JOIN CourseRelatedCourse AS crc on crc.CourseId = c.Id
INNER JOIN Course As c2 on crc.RelatedCourseId = c2.Id
INNER JOIN BaseCourse As bc on c2.BaseCourseId = bc.Id
INNER JOIN Course AS c3 on bc.ActiveCourseId = c3.Id
INNER JOIN StatusAlias As sa2 on c3.StatusAliasId = sa2.Id
where c.StatusAliasId =1
and c.Active = 1
and c2.Active = 1
and crc.Active = 1
and c.Id <> c3.Id
and c.Id not in (
	SELECT RelatedCourseId FROM CourseRelatedCourse AS crc
	INNER JOIN Course AS c on crc.CourseId = c.Id
	WHERE c.Active = 1
	and c.StatusAliasId = 1
)

SELECT CourseId
FROM CourseRelatedCourse as crc
INNER JOIN Course AS c on crc.CourseId = c.Id
where CourseId not in (
8547,
8858,
11470,
12490,
12791
)
and c.StatusAliasId = 1
and c.Active = 1
GROUP BY CourseId
HAVING COUNT(crc.id) > 1;

SELECT * FROM CourseRelatedCourse WHERE CourseId = 12490