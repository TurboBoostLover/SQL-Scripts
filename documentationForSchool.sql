/* 
    Created by Brenton Trebilcock (last updated 3/9/2023)
    Gets the documentation info for all the proposal types for a school including all of the subsections!

	version 2: Added the values of the fields
    version 3: Added advanced show hide, ability to get the reports, made the order for subsections better, gets values from literal list table if there is no customsql
    version 4: Added field, section, and tab permissions
    version 5: Made report faster (when there are a lot of proposal types), commented out customsql by default

    Things to note:
    - This may not be perfect and may take longer to run on schools with lots of proposal types
    - By default static text fields are ommited, tabs with only static text on them will not show up
	- A * will be added automatically to the end of Field Name of fields that are required
    - Tabs and sections that have no fields in them will not show.
	- If the values or customsql have more than 32650 characters, they will get cut off (32767 is the max that microsoft excel allows in a cell), it will add a ... if this occurs
	- If the values for fields that have complicated custom sql may not show
	- The values, descriptions (for show/hide), and trigger fields (for show/hide) will all ve separated by commas
	- Show/hide descriptions may appear to get cut off this is because there is a character limit for show hide descriptions
	- Currently the show / hide information (for the parent section) will not show for the subsections if the parent section has show / hide
	- This will only get values for custom reports and not standard reports
	- Reports will have "Report" added before their proposal name and added to the end of the proposal type, to distinquish them from other proposals (reports will also be at the bottom of the results)
    - Some fields may appear to be out of order (fields that are in columns, but are on new forms) (The documentation should match the builder)
*/

	-- Might want to add the show hide for the sections the section resides in (if it is a subsection) !!!!

USE []; -- Enter the school code here (make sure to change to proper school before running the report)

/* Note: set clientId to NULL to get documentation for every client in the district
   set it to a specific client to only get documentation for that client */
DECLARE @clientId int = NULL, -- Select Id, Title, CASE WHEN Active = 1 THEN 'Yes' ELSE 'NO' END AS [Is Active] FROM Client 
		@includeReports bit = 1, -- 0 = No, 1 = Yes (If you want to include reports, this needs to be set to 1)
		@includeStaticText bit = 0; -- 0 = No, 1 = Yes

/*
	!!! Don't edit anything below this !!! 
*/

-- Error checking
IF NOT EXISTS (SELECT Id FROM Client WHERE @clientId IS NULL OR Id = @clientId)
RAISERROR('Error: Invalid clientId!',20,-1) WITH log

DECLARE @fields TABLE(Id int IDENTITY, MetaSelectedFieldId int, MetaSelectedSectionId int, IdHierarchy varchar(200), RowPosHierarchy varchar(200), Level int, SortOrder varchar(50));

DECLARE @documentationInfo TABLE(Id int IDENTITY,
    ClientName nvarchar(200),
    -- ProposalId nvarchar(200),
    -- ProposalType nvarchar(200),
	TemplateId int,
    ProposalForm nvarchar(200),
    TabName nvarchar(200),
    SectionName nvarchar(max),
    FieldName nvarchar(max),
    FieldType nvarchar(200),
    ShowHide nvarchar(max),
    FieldValues nvarchar(max),
    FieldCustomSql nvarchar(max),
    [Permissions] nvarchar(max),
    TabPos int,
    SectionPos int,
    FieldPos int,
	ColPos int,
	Level int,
    SortOrder varchar(50)
    );

-- DECLARE @proposalTypes TABLE(Id int IDENTITY, TemplateId int, ClientName nvarchar(200), ProposalName nvarchar(200), ProposalType nvarchar(200), ProposalForm nvarchar(200));
DECLARE @proposalTypes TABLE(Id int IDENTITY, TemplateId int, ClientName nvarchar(200),  ProposalForm nvarchar(200));

-- only getting the templates here, to make the report run faster
INSERT INTO @proposalTypes
(TemplateId, ClientName, ProposalForm)
-- martin: for testing purposes I added a top 5
-- SELECT top 5 mt.MetaTemplateId,
-- output inserted.*
SELECT mt.MetaTemplateId,
    c.Title,
    -- CASE
    --     WHEN mtt.IsPresentationView = 1 THEN CONCAT('Report: ', mtt.TemplateName)
    --     ELSE pt.Title
    -- END,   
    -- CASE
    --     WHEN mtt.IsPresentationView = 1 THEN CONCAT(mtt.ReferenceTable, ' Report')
    --     ELSE et.Title
    -- END,
    mtt.TemplateName
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    -- LEFT JOIN ProposalType pt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
    LEFT JOIN EntityType et ON et.Id = mtt.EntityTypeId
    INNER JOIN Client c on c.Id = mtt.ClientId
WHERE mt.Active = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.active = 1
    AND (@includeReports = 1 OR mtt.IsPresentationView = 0)
    -- AND (mtt.IsPresentationView = 1 OR pt.Active = 1)
    AND c.Active = 1 -- Only get documentation for active clients
    AND (@clientId IS NULL OR mtt.ClientId = @clientId) -- Either get all of the clients if null or get the specified client
ORDER BY CASE WHEN mtt.IsPresentationView = 1 THEN 1 ELSE 0 END, CASE WHEN mtt.IsPresentationView = 1 THEN mtt.ReferenceTable ELSE et.Title END --, pt.Title;

-- select * from @proposalTypes
 
DECLARE @currentId int = (SELECT min(Id) FROM @proposalTypes)

WHILE @currentId IS NOT NULL
BEGIN

/*
	This is used to get all the fields that are in subsections
*/

-- Help with sorting the Hierarchy https://stackoverflow.com/questions/47830857/parent-child-hierarchy-with-order-by-on-name
-- Note: tabs use sort order to determine the position and sections use row position
-- Note need to add leading zeros to the sort order with FORMAT(,'D4') (see stack overflow post above) for tabs that have sections with sort orders > 9
	;WITH Sections 
	AS 
	(
		SELECT 
			0 as lvl,
			MetaSelectedSection_MetaSelectedSectionId,
			MetaSelectedSectionId,
			SectionName as [Parent Section],
			SectionName,
			SectionName as [Hierarchy],
			CAST(MetaSelectedSectionId as varchar(250)) as [IdHierarchy],
			CAST(RowPosition as varchar(250)) as [RowPosHierarchy],
            CAST(FORMAT(ROW_NUMBER() OVER(ORDER BY SortOrder, MetaSelectedSectionId), 'D4') as varchar(50)) As Sort -- use rowposition and the sectionId (in case they have the same sectionId)
		FROM MetaSelectedSection
		WHERE MetaSelectedSection_MetaSelectedSectionId IS NULL
			AND MetaTemplateId = (SELECT TemplateId FROM @proposalTypes WHERE Id = @currentId)

		UNION ALL

		SELECT
			lvl + 1 as lvl,
			mss.MetaSelectedSection_MetaSelectedSectionId,
			mss.MetaSelectedSectionId,
			Sections.SectionName as [Tab Name],
			mss.SectionName,
			Sections.[Hierarchy] + ' > ' + mss.SectionName as [Hierarchy],
			CAST(Sections.[IdHierarchy] + ' > ' + CAST(mss.MetaSelectedSectionId as varchar) as varchar(250)) as [IdHierarchy],
			CAST(Sections.[RowPosHierarchy] + ' > ' + CAST(mss.RowPosition as varchar) as varchar(250)) as [RowPosHierarchy],
            CAST(Sort + CAST(FORMAT(ROW_NUMBER() OVER(ORDER BY mss.RowPosition, mss.MetaSelectedSectionId),'D4') as varchar(50)) as varchar(50))
		FROM Sections 
			inner join MetaSelectedSection mss on mss.MetaSelectedSection_MetaSelectedSectionId = Sections.MetaSelectedSectionId
	)
	INSERT INTO  @fields
	(MetaSelectedFieldId, MetaSelectedSectionId, IdHierarchy, RowPosHierarchy, Level, SortOrder)
	SELECT msf.MetaSelectedFieldId, s.MetaSelectedSectionId, s.[IdHierarchy], s.[RowPosHierarchy], s.lvl, s.Sort
	FROM Sections s
		INNER JOIN MetaSelectedField msf ON msf.MetaSelectedSectionId = s.MetaSelectedSectionId
	ORDER BY Sort

	INSERT INTO @documentationInfo
	(ClientName, TemplateId, ProposalForm, TabName, SectionName, FieldName, FieldType, ShowHide, FieldValues, FieldCustomSql, [Permissions], TabPos, SectionPos, FieldPos, ColPos, [Level], SortOrder)
	SELECT DISTINCT pt.ClientName,
		pt.TemplateId,
		pt.ProposalForm,
		tab.SectionName,
		mss.SectionName,
		CASE 
			WHEN msf.IsRequired = 1
				THEN CONCAT(msf.DisplayName, ' *')
			ELSE
				msf.DisplayName
		END,
		CASE 
			WHEN msf.MetaPresentationTypeId IN (1,105)
				THEN 'Text Box'
			WHEN msf.MetaPresentationTypeId = 17
				THEN 'Text Area'
			WHEN msf.MetaPresentationTypeId = 25
				THEN 'RTE'
			WHEN msf.MetaPresentationTypeId = 27
				THEN 'Date Picker'
			WHEN msf.MetaPresentationTypeId = 103
				THEN 'Query Text'
			WHEN mss.MetaSectionTypeId = 3 AND msf.MetaPresentationTypeId IN (2,16,28,29,33,101)
				THEN 'Checklist'
			WHEN mss.MetaSectionTypeId = 18 AND msf.MetaPresentationTypeId IN (2,16,28,29,33,101)
				THEN 'Multiselect List'
			WHEN mss.MetaSectionTypeId = 13 AND msf.MetaPresentationTypeId IN (2,16,28,29,33,101)
				THEN 'Group Checklist'
			WHEN mss.MetaSectionTypeId = 23 AND msf.MetaPresentationTypeId IN (2,16,28,29,33,101)
				THEN 'Repeater'
			WHEN mss.MetaSectionTypeId = 32 AND msf.MetaPresentationTypeId IN (2,16,28,29,33,101)
				THEN 'Bridge List'
			WHEN msf.MetaPresentationTypeId IN (2,16,28,33,101)
				THEN 'Drop Down'
			ELSE 
				msf.DefaultDisplayType 
		END,
    	CASE  -- Show / Hide
			WHEN (mds.id IS NOT NULL OR mds2.Id IS NOT NULL)
                THEN CONCAT('Description(s): ', sh1.Descriptions, '. ', 'Trigger field(s): ', sh2.Triggers, '.')
     		ELSE ''
		END,
		CASE -- Field Values
			WHEN msf.[ReadOnly] = 1 THEN CONCAT('(Read only) ', COALESCE(qr.RenderedText, ll.[Values])) -- add a note if something is read only!
			ELSE COALESCE(qr.RenderedText, ll.[Values])
		END, 
		params.Query, -- Custom Sql
		-- Use regex_replace to get rid of last comma
        dbo.RegEx_Replace(CONCAT(fieldRolePermissions.permissions + ', ',
        	fieldPositionPermissions.permissions + ', ', 
        	sectionRolePermissions.permissions + ', ', 
        	sectionPositionPermissions.permissions + ', ', 
        	tabRolePermissions.permissions + ', ',
        	tabPositionPermissions.permissions), ',\s*$', ''),
        tab.SortOrder, -- Needed to use distinct -- change to sort order?????
		mss.RowPosition,
		msf.RowPosition,
		msf.ColPosition,
		f.[Level],
        f.SortOrder
	FROM @fields f
		INNER JOIN MetaSelectedField msf on msf.MetaSelectedFieldId = f.MetaSelectedFieldId
		INNER JOIN MetaSelectedSection mss ON mss.MetaSelectedSectionId = f.MetaSelectedSectionId
		INNER JOIN MetaSelectedSection tab ON tab.MetaSelectedSectionId = CAST(SUBSTRING(f.IdHierarchy,0, CHARINDEX(' >',f.IdHierarchy)) AS int)
		INNER JOIN @proposalTypes pt ON pt.TemplateId = mss.MetaTemplateId
		LEFT JOIN MetaDisplaySubscriber mds ON mds.MetaSelectedSectionId = mss.MetaSelectedSectionId -- for show / hide
		LEFT JOIN MetaDisplaySubscriber mds2 ON mds2.MetaSelectedFieldId = msf.MetaSelectedFieldId -- for show / hide
		LEFT JOIN MetaAvailableField maf ON maf.MetaAvailableFieldId = msf.MetaAvailableFieldId
		LEFT JOIN MetaForeignKeyCriteriaClient mfkcc ON mfkcc.Id = msf.MetaForeignKeyLookupSourceId
		LEFT JOIN MetaForeignKeyCriteriaBase mfkcb ON mfkcb.Id = maf.MetaForeignKeyLookupSourceId

        OUTER APPLY
        (
			SELECT COALESCE(mfkcc.CustomSql, mfkcb.CustomSql, mfkcb.LookupTableQuery) AS [Query]
			, mss.ClientId AS ClientId
			, 1 AS IsAdmin
			, 1 AS SerializedRows
			, NULL AS UserId
			, NULL AS EntityId
			, NULL AS ExtraParams
        ) params

		-- used to get the values
        OUTER APPLY
        (   
			SELECT ft.Success -- martin: just a status message of the query that got executed
			, fn1.StatusMessages
			-- martin: we are concatenating it as a JSON array, but you can displayed it as you want
			, CASE
				WHEN ft.Success = 1 THEN dbo.ConcatWithSep_Agg(', ', ft.RenderedTextItem) -- CONCAT('[', dbo.ConcatWithSep_Agg(', ', ft.RenderedTextItem), ']')
				ELSE NULL
				END AS RenderedText
            FROM (
				SELECT b.*
                FROM dbo.fnBulkResolveCustomSqlQuery(params.Query, params.SerializedRows, params.EntityId, params.ClientId, params.UserId, params.IsAdmin, params.ExtraParams) b
			) fn1
			OUTER APPLY (
				SELECT
            -- martin: for now I'm just using the 'SerializedFullRow' to be the rendered text for each item returned by the query, but you can formatted as you want using the columns 'Value' and 'Text' or the 'Serialized FullRow'
            fn1.Text AS RenderedTextItem,
            CASE
					WHEN
					  fn1.ValueSuccess = 1 AND fn1.TextSuccess = 1 AND fn1.SerializationSuccess = 1 AND fn1.QuerySuccess = 1 THEN 1 
					  ELSE 0
				END AS Success
			) ft
        GROUP BY ft.Success, fn1.StatusMessages 
		) qr -- query results

		-- Need to group both the descriptions (SubscriberName) and the trigger fields together for the show/hide
		-- Might want to add the show hide for the sections the section resides in (if it is a subsection)

		-- Note: needed to separate the show/hide outer applies in order to prevent duplicates
		-- show hide information for the descriptions (SubscriberName column on MetaDisplaySubscriber)
		OUTER APPLY
		(
            SELECT dbo.ConcatWithSep_Agg(', ', ShowHideInfo.Description) AS Descriptions -- get all of the show/hide descriptions
            FROM 
            (
            SELECT DISTINCT mds.SubscriberName AS [Description] -- get all of the show/hide descriptions
			FROM MetaDisplayRule mdr 
				INNER JOIN MetaDisplaySubscriber mds ON mds.MetaDisplayRuleId = mdr.Id 
			WHERE (mds.MetaSelectedSectionId = mss.MetaSelectedSectionId OR mds.MetaSelectedFieldId = msf.MetaSelectedFieldId) -- using the section / field that the show/hide is on
            ) ShowHideInfo
		) sh1 -- show / hide

		-- show hide information for the triggers
		OUTER APPLY
		(
            SELECT dbo.ConcatWithSep_Agg(', ', CONCAT(ShowHideInfo.TriggerName, ' (on ', ShowHideInfo.TriggerTab, ' tab)')) AS Triggers
            FROM 
            (
            SELECT DISTINCT triggermsf.DisplayName AS [TriggerName], -- get the trigger with the tab that it is on!
                triggertab.SectionName AS [TriggerTab]
			FROM MetaDisplayRule mdr 
				INNER JOIN MetaDisplaySubscriber mds ON  mds.MetaDisplayRuleId = mdr.Id 
				INNER JOIN ExpressionPart ep ON ep.ExpressionId = mdr.ExpressionId
				INNER JOIN MetaSelectedField triggermsf ON triggermsf.MetaSelectedFieldId = ep.Operand1_MetaSelectedFieldId
				INNER JOIN @fields f ON f.MetaSelectedFieldId = triggermsf.MetaSelectedFieldId
				INNER JOIN MetaSelectedSection triggertab ON triggertab.MetaSelectedSectionId = CAST(SUBSTRING(f.IdHierarchy,0, CHARINDEX(' >',f.IdHierarchy)) AS int)
			WHERE (mds.MetaSelectedSectionId = mss.MetaSelectedSectionId OR mds.MetaSelectedFieldId = msf.MetaSelectedFieldId) -- using the section / field that the show/hide is on
            ) ShowHideInfo
		) sh2 -- show / hide

		-- This is for literal drop downs and other fields that have their values from the meta literal list table
		-- literal lists seem to be depricated, but may still be used in some instances !!!
		OUTER APPLY 
		(
			SELECT dbo.ConcatWithSep_Agg(', ', DisplayValue) AS [Values]
			FROM MetaLiteralList mll
			WHERE mll.MetaSelectedFieldId = msf.MetaSelectedFieldId
		) ll -- literal list

        OUTER APPLY
        (
        SELECT
            dbo.ConcatWithSep_Agg(', ', CONCAT(RolePermissions.Title, ' (', RolePermissions.TypeDesc, ') [field]')) AS [Permissions]
            FROM (
            SELECT
                r.Title,
                art.TypeDesc
                FROM MetaSelectedFieldRolePermission msfrp
                    INNER JOIN Role r ON r.Id = msfrp.RoleId
                    INNER JOIN AccessRestrictionType art ON art.Id = msfrp.AccessRestrictionType
                    WHERE msfrp.MetaSelectedFieldId = msf.MetaSelectedFieldId) RolePermissions
        ) fieldRolePermissions

        OUTER APPLY
        (
        SELECT
            dbo.ConcatWithSep_Agg(', ', CONCAT(PositionPermissions.Title, ' (', PositionPermissions.TypeDesc, ') [field]')) AS [Permissions]
            FROM (
            SELECT
                p.Title,
                art.TypeDesc
                FROM MetaSelectedFieldPositionPermission msfpp
                    INNER JOIN Position p ON p.Id = msfpp.PositionId
                    INNER JOIN AccessRestrictionType art ON art.Id = msfpp.AccessRestrictionType
                    WHERE msfpp.MetaSelectedFieldId = msf.MetaSelectedFieldId) PositionPermissions
        ) fieldPositionPermissions

        OUTER APPLY
        (
        SELECT
            dbo.ConcatWithSep_Agg(', ', CONCAT(RolePermissions.Title, ' (', RolePermissions.TypeDesc, ') [section]')) AS [Permissions]
            FROM (
            SELECT
                r.Title,
                art.TypeDesc
                FROM MetaSelectedSectionRolePermission mssrp
                    INNER JOIN Role r ON r.Id = mssrp.RoleId
                    INNER JOIN AccessRestrictionType art ON art.Id = mssrp.AccessRestrictionType
                    WHERE mssrp.MetaSelectedSectionId = mss.MetaSelectedSectionId) RolePermissions
        ) sectionRolePermissions

        OUTER APPLY
        (
        SELECT
            dbo.ConcatWithSep_Agg(', ', CONCAT(PositionPermissions.Title, ' (', PositionPermissions.TypeDesc, ') [section]')) AS [Permissions]
            FROM (
            SELECT
                p.Title,
                art.TypeDesc
                FROM MetaSelectedSectionPositionPermission msspp
                    INNER JOIN Position p ON p.Id = msspp.PositionId
                    INNER JOIN AccessRestrictionType art ON art.Id = msspp.AccessRestrictionType
                    WHERE msspp.MetaSelectedSectionId = mss.MetaSelectedSectionId) PositionPermissions
        ) sectionPositionPermissions

        OUTER APPLY
        (
        SELECT
            dbo.ConcatWithSep_Agg(', ', CONCAT(RolePermissions.Title, ' (', RolePermissions.TypeDesc, ') [tab]')) AS [Permissions]
            FROM (
            SELECT
                r.Title,
                art.TypeDesc
                FROM MetaSelectedSectionRolePermission mssrp
                    INNER JOIN Role r ON r.Id = mssrp.RoleId
                    INNER JOIN AccessRestrictionType art ON art.Id = mssrp.AccessRestrictionType
                    WHERE mssrp.MetaSelectedSectionId = tab.MetaSelectedSectionId) RolePermissions
        ) tabRolePermissions

        OUTER APPLY
        (
        SELECT
            dbo.ConcatWithSep_Agg(', ', CONCAT(PositionPermissions.Title, ' (', PositionPermissions.TypeDesc, ') [tab]')) AS [Permissions]
            FROM (
            SELECT
                p.Title,
                art.TypeDesc
                FROM MetaSelectedSectionPositionPermission msspp
                    INNER JOIN Position p ON p.Id = msspp.PositionId
                    INNER JOIN AccessRestrictionType art ON art.Id = msspp.AccessRestrictionType
                    WHERE msspp.MetaSelectedSectionId = tab.MetaSelectedSectionId) PositionPermissions
        ) tabPositionPermissions

	WHERE mss.MetaTemplateId = (SELECT TemplateId FROM @proposalTypes WHERE Id = @currentId)
		AND pt.Id = @currentId -- Need this to prevent duplicates! (Or else you will get a duplicate for each proposal type that uses the meta template)
		AND (@includeStaticText = 1 OR msf.MetaPresentationTypeId != 35) -- exclude static text when the bit is set to 0
	ORDER BY tab.SortOrder, f.SortOrder, mss.RowPosition, msf.RowPosition, msf.ColPosition

	SET @currentId = (SELECT min(Id) FROM @proposalTypes WHERE Id > @currentId) -- Set currentId to the next value from proposalTypes

	DELETE FROM @fields -- Delete everything from fields
END

-- Select Everything to get all the documentation for the school / selected client
-- Inner joining to get all the proposal types, without running them all through the loop
SELECT ClientName AS [School],
        CASE
        WHEN mtt.IsPresentationView = 1 THEN CONCAT('Report: ', mtt.TemplateName)
        ELSE pt.Title
    END AS [Proposal Name],
    CASE
        WHEN mtt.IsPresentationView = 1 THEN CONCAT(mtt.ReferenceTable, ' Report')
        ELSE et.Title
    END AS [Proposal Type],
    ProposalForm AS [Proposal Form],
	-- Level AS [Lvl], --DELETE THIS!!! (FOR TESTING THE ORDER OF SECTIONS/SUBSECTIONS)
	-- SectionPos, --DELETE THIS!!! (FOR TESTING THE ORDER OF SECTIONS/SUBSECTIONS)
	-- FieldPos, --DELETE THIS!!! (FOR TESTING THE ORDER OF SECTIONS/SUBSECTIONS)
    -- SortOrder, --DELETE THIS!!! (FOR TESTING THE ORDER OF SECTIONS/SUBSECTIONS)
    COALESCE(REPLACE(REPLACE(REPLACE(TabName, CHAR (13), ' '), CHAR (10), ' '), CHAR (9), ' '), '') AS [Tab Name],
    COALESCE(REPLACE(REPLACE(REPLACE(SectionName, CHAR (13), ' '), CHAR (10), ' '), CHAR (9), ' '), '') AS [Section Name],
    COALESCE(REPLACE(REPLACE(REPLACE(FieldName, CHAR (13), ' '), CHAR (10), ' '), CHAR (9), ' '), '') AS [Field Name],
    COALESCE(REPLACE(REPLACE(REPLACE(FieldType, CHAR (13), ' '), CHAR (10), ' '), CHAR (9), ' '), '') AS [Field Type],
    COALESCE(REPLACE(REPLACE(REPLACE(ShowHide, CHAR (13), ' '), CHAR (10), ' '), CHAR (9), ' '), '') AS [Show Hide], 
    [Permissions],
	CASE -- Need to limit characters and remove formating
		WHEN LEN(FieldValues) > 32650  THEN CONCAT(REPLACE(REPLACE(REPLACE(SUBSTRING(FieldValues, 1, 32650), CHAR (13), ' '), CHAR (10), ' '), CHAR (9), ' '), ' ...')
		ELSE COALESCE(REPLACE(REPLACE(REPLACE(FieldValues, CHAR (13), ' '), CHAR (10), ' '), CHAR (9), ' '), '') 
	END AS [Field Values]
	-- CASE -- This is for the customsql, (not needed)
	-- 	WHEN LEN(FieldCustomSql) > 32650  THEN CONCAT(REPLACE(REPLACE(REPLACE(SUBSTRING(FieldCustomSql, 1, 32650), CHAR (13), ' '), CHAR (10), ' '), CHAR (9), ' '), ' ...')
	-- 	ELSE COALESCE(REPLACE(REPLACE(REPLACE(FieldCustomSql, CHAR (13), ' '), CHAR (10), ' '), CHAR (9), ' '), '') 
	-- END AS [Custom Sql] -- Need to replace new lines with spaces so copy and pasting is possible
FROM @documentationInfo di 
	INNER JOIN MetaTemplate mt ON mt.MetaTemplateId = di.TemplateId
	INNER JOIN MetaTemplateType mtt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
	LEFT JOIN ProposalType pt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	LEFT JOIN EntityType et ON et.Id = pt.EntityTypeId
WHERE (mtt.IsPresentationView = 1 OR pt.Active = 1) -- Either a report or an active proposal
ORDER BY  ClientName, CASE WHEN mtt.IsPresentationView = 1 THEN 1 ELSE 0 END, [Proposal Type], [Proposal Name], TabPos, di.SortOrder, SectionPos, FieldPos, ColPos

-- commented out the custom sql

-- Need field and col pos to make sure it orders the fields correctly 
-- 'CASE WHEN CHARINDEX('Report', ProposalType) > 0 THEN 1 ELSE 0 END' makes it so all that report types go to the end! Remove this if you don't want them separated

-- Might want to add the show hide for the sections the section resides in (if it is a subsection) !!!!

-- need to fix the seperator for the permissions to work properly