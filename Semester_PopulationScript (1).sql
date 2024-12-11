/*********************************************************************************************************************************************************************************************
 *	This script is for generating semester records to populate the semester table
 *  
 *  Instructions for running script:
 *  1.  Set the Use statement Line 37
 *  2.  If you are adding semesters to a single client database the clientId will be automatically generated for the script.  
 *      If you are dealing with a multi-client database add the client Id of the client you wish to add semesters for to the declare statement for the ClientId variable.
 *  3.  If the database has client Course and/or Program data, set the @ClientDatabaseHasData bit to one and script will set the @Startyear to the earliest course or program createdon date.
 *  4.  If the database does not have client Course and/or Program data, set the @StartYear to the year you want your terms to start.
 *  5.  The script generates term data through the year that the @EndYear is set to.  @EndYear is automatically set to 30 years in the future.
 *  6.  Add the following records to the #SeedTable table that starts on Line 50 
 *      a.  TermName: 
 *            i)  Find out what the client calls thier Terms (Example: Fall Semester or Fall Quarter) and enter a record for each in the #SeedTable You can also add special custom terms if needed.
 *           ii)  Note: setting the bit @YearPosition to 1 puts the Year after the TermName when inserted into the semester Table (Fall Semester 2020), 0 puts the year Before TermName (2020 Fall Semester)
 *      b.  StartMonthAndDay: 
 *			  i)  Findout the start month and day for each term and add them to the #SeedTable records in the format 01-01-
 *      c.  EndMonthAndDay: 
 *			  i)  Findout the end month and day for each term and add them to the #SeedTable records in the format 05-31-
 *      d.  SortOrder: 
 *			  i)  Add a sort order for the order of the terms in the academic year to the #SeedTable records.  For example Fall 1, Spring 2, and Summer 3
 *      e.  AddStartYear: 
 *            i)  The term with a SortOrder of 1 should always have 0 for this field
 *           ii)  Any term that starts in the same calendar year as (the term with a SortOrder of 1) should also be 0
 *          iii)  Any term that starts in the next calendar year from (the term with a SortOrder of 1) should be 1
 *      f.  AddEndYear: 
 *            i)  Any term that ends in the same calendar year as (the start term with a SortOrder of 1) should be 0
 *           ii)  Any term that ends in the next calendar year after (the start term with a SortOrder of 1) should be 1
 *  7.  Run the script with the testing bit set to 1 to see what the script will produce.  Change the bit to 0 to Run and commit the changes.
 *  8.  For Deploy run the script with testing set to 0 and deploy set to 1 the script will run but will not auto commit.  If both @Testing and @Deploy are set to 0 then the script will auto commit.
 *
 *  Script Created by Steve Peters on 1/31/2020
 ********************************************************************************************************************************************************************************************/
 Declare @Testing bit = 1;
 Declare @Deploy bit = 0; /*Set to 1 for deploying and leaving the transaction open*/
 Declare @AddMFKCCRecords int = 1

Use ;

Declare @ClientId int = 1;
Declare @ClientDatabaseHasData bit = 0
Declare @StartYear int = 2008;
Declare @EndYear int = (Select year(Current_TimeStamp)+30)
Declare @YearPosition bit = 1; /* 1 puts the year after the title 0 puts the year before the title */

Select @StartYear as StartYear, @EndYear as EndYear

Drop table if exists #SeedTable
Create table #SeedTable (TermName nvarchar(50),StartMonthAndDay Nvarchar(6),EndMonthAndDay Nvarchar(6),SortOrder int,AddStartYear int,AddEndYear int);

Insert into #SeedTable (TermName,StartMonthAndDay,EndMonthAndDay ,SortOrder,AddStartYear,AddEndYear)
output 'Seed Records' as Context,inserted.*
Values
 ('Fall','08-26-','12-23-', 1,0,0)
,('Spring','01-09-','05-16-', 2,1,1)
,('Summer','05-27-','08-08-', 3,1,1)
/*
 ('Fall Semester','08-26-','12-23-', 1,0,0)
,('Spring Semester','01-09-','05-16-', 2,1,1)
,('Summer Semester','05-27-','08-08-', 3,1,1)
 ,
('Fall Quarter',  '09-01-','12-31-', 1,0,0)
,('Winter Quarter','01-01-','03-31-', 2,1,1)
,('Spring Quarter','04-01-','06-31-', 3,1,1)
,('Summer Quarter','07-01-','09-31-', 4,1,1)*/
;

/* Error Checking data that was entered in the #SeedTable */

If (select Count(*) 
from #SeedTable
Where Left(StartMonthAndDay,2) > 12 
or Left(StartMonthAndDay,2) < 01
or  Left(EndMonthAndDay,2) > 12 
or Left(EndMonthAndDay,2) < 00) >0
Begin
	select 'Error: These records have invalid month data!' as Message, * 
	from #SeedTable
	Where Left(StartMonthAndDay,2) > 12 
	or Left(StartMonthAndDay,2) < 01
	or  Left(EndMonthAndDay,2) > 12 
	or Left(EndMonthAndDay,2) < 00;
END


Update #SeedTable /*  This query is to fix potential errors where the day entered in StartMonthAndDay is greater than the number of days in the month entered*/
Set StartMonthAndDay =
Case When Left(StartMonthAndDay,2) in ('01','03','05','07','08','12') and Convert( int,(Left(Right( StartMonthAndDay,3),2))) > 31
		Then Left(StartMonthAndDay,2)+ '-31-'	
	 When Left(StartMonthAndDay,2) in ('04','06','09','11') and Convert( int,(Left(Right( StartMonthAndDay,3),2))) > 30
		Then Left(StartMonthAndDay,2)+ '-30-'
	 When Left(StartMonthAndDay,2) = '02' and Convert( int,(Left(Right( StartMonthAndDay,3),2))) > 28
		Then Left(StartMonthAndDay,2)+ '-28-'
	Else StartMonthAndDay
End

Update #SeedTable /*  This query is to fix potential errors where the day entered in EndMonthAndDay is greater than the number of days in the month entered*/
Set EndMonthAndDay =
Case When Left(EndMonthAndDay,2) in ('01','03','05','07','08','12') and Convert( int,(Left(Right( EndMonthAndDay,3),2))) > 31
		Then Left(EndMonthAndDay,2)+ '-31-'	
	 When Left(EndMonthAndDay,2) in ('04','06','09','11') and Convert( int,(Left(Right( EndMonthAndDay,3),2))) > 30
		Then Left(EndMonthAndDay,2)+ '-30-'
	 When Left(EndMonthAndDay,2) = '02' and Convert( int,(Left(Right( EndMonthAndDay,3),2))) > 28
		Then Left(EndMonthAndDay,2)+ '-28-'
	Else EndMonthAndDay
End

/* End Error Checking data entered in the #SeedTable */

If (Select Count(Id) from Client where active = 1) =1
Begin
	 set @ClientId = (Select Top 1 Id from Client Where active = 1);
End

If @ClientDatabaseHasData = 1 
Begin
	Drop table if exists #BaseYear 
	;With BaseYears as (
	Select min(year(createdOn)) as StartYear from Course 
	Union
	Select Min(year(CreatedOn)) as StartYear from Program
	)  select Min(StartYear) as Startyear into #BaseYear From BaseYears

	Set @StartYear = (Select Startyear from #BaseYear);
End


Drop table if exists #Years 
Create Table #Years (Yr int);

While @StartYear < @EndYear+1
Begin

	Insert into #Years (yr)
	Values
	(@StartYear);

	Set @StartYear = (@StartYear+1)
End

Set xact_Abort on
Begin Tran

Update Semester set Active = 0, Enddate = Current_Timestamp Where ClientId = @ClientId;

drop table if exists #SemesterTemp
select Case when @YearPosition= 1 and AddStartYear = 0 then  TermName + ' ' + Cast(Yr as nvarchar(4)) 
			when @YearPosition= 1 and AddStartYear = 1 then  TermName + ' ' + Cast(Yr + 1 as nvarchar(4)) 
            When @YearPosition= 0 and AddStartYear = 0 then  Cast(Yr as nvarchar(4)) + ' ' + TermName
			When @YearPosition= 0 and AddStartYear = 1 then  Cast(Yr + 1 as nvarchar(4)) + ' ' + TermName
End as Title 
, Case when (Select Sum(AddEndYear) from #SeedTable)  > 0 Then  Cast(Yr as nvarchar(4)) + '-' + Cast((Yr + 1) as nvarchar(4))
  Else Cast(Yr as nvarchar(4)) + '-' + Cast(Yr as nvarchar(4))
  End as CatalogYear
, 1 as Active
, @ClientId as ClientId
, NUll as EndDate
, Row_Number() Over ( Order By Case when AddStartYear = 0 then  Cast(yr as nvarchar(4))  + Left(StartMonthAndDay, 2)
                                    When AddStartYear = 1 then  Cast((Yr + 1) as nvarchar(4)) + Left(StartMonthAndDay, 2) END ) As SortOrder
, Case when AddStartYear = 0 then  Cast(yr as nvarchar(4))  + Left(StartMonthAndDay, 2)
       When AddStartYear = 1 then  Cast((Yr + 1) as nvarchar(4)) + Left(StartMonthAndDay, 2)
End as Code
,Current_Timestamp as StartDate
, Case when AddStartYear = 0 then Convert(datetime, (StartMonthAndDay + Cast(Yr as nvarchar(4))))  
	   When AddStartYear = 1  then  Convert(datetime, (StartMonthAndDay + Cast((Yr + 1) as nvarchar(4))))
  End as TermStartDate
, Case when AddendYear = 0 then Convert(datetime, (EndMonthAndDay + Cast(Yr as nvarchar(4))))  
	   When AddEndYear = 1  then  Convert(datetime, (EndMonthAndDay + Cast(Yr + 1 as nvarchar(4))))
  End as TermEndDate
, Yr as AcademicYearStart
, Case when (Select Sum(AddEndYear) from #SeedTable)  > 0 Then Cast((Yr + 1) as nvarchar(4))
  Else Cast(Yr as nvarchar(4)) 
  End as AcademicYearEnd
  into #semesterTemp
from #SeedTable st cross join #Years y
Where ((Left(st.StartMonthAndDay,2) < 13 and Left(st.StartMonthAndDay,2) > 00)
And  (Left(st.EndMonthAndDay,2) < 13 and Left(st.EndMonthAndDay,2) > 00))
order by Code

merge semester as target
using (
Select Title,	CatalogYear,	Active,	ClientId,	EndDate,	SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,AcademicYearStart,	AcademicYearEnd
from #semesterTemp
)as Source (Title,	CatalogYear,	Active,	ClientId,	EndDate,	SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd)
on 1=0 WHEN not matched THEN
insert (Title,	CatalogYear,	Active,	ClientId,	EndDate,	SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd)
Values (Source.Title,	Source.CatalogYear,	Source.Active,	Source.ClientId,	Source.EndDate,	Source.SortOrder,	Source.Code,	Source.StartDate,	Source.TermStartDate,	Source.TermEndDate,	Source.AcademicYearStart,	Source.AcademicYearEnd)
output inserted.*;

Declare @NewMFKCCId int = (Select Max(Id)+1 from MetaForeignKeyCriteriaClient);
If @AddMFKCCRecords = 1
Begin
	
	Insert into MetaForeignKeyCriteriaClient
	(Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,Title,LookupLoadTimingType)
	output inserted.*
	Values
	(@NewMFKCCId, 'Semester', 'Id', 'Title',
		';With AllTerms as(
		select Id,	Title,	CatalogYear,	Active,	ClientId,	EndDate,	Code as SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd	
		from semester where active = 1
		and AcademicYearStart > year(current_timestamp)-3
		and AcademicYearStart < year(current_timestamp)+7 
		union
		select Id,	Title,	CatalogYear,	Active,	ClientId,	EndDate,	Code * 10 as SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd	
		from semester where active = 1
		and AcademicYearStart < year(current_timestamp) -2
		/* or AcademicYearStart > year(current_timestamp) +6 */
		union
		select Id,	Title + '' (Inactive)'' as title,	CatalogYear,	Active,	ClientId,	EndDate,	Id * 1000000 as SortOrder,	Code,	StartDate,	TermStartDate,	TermEndDate,	AcademicYearStart,	AcademicYearEnd	
		from semester where active = 0
		) 
		Select Id as Value, Title as Text
		from AllTerms
		Order by SortOrder ',
		'Select Title As Text from Semester where Id = @Id', 'Order By SortOrder', 'Rolling Semester Query with All Terms',1);

End;

If @Testing = 1
Begin
	Select @StartYear as StartYear, @EndYear as EndYear
	select * from Semester
	Select 'Testing is set to 1, transaction has been rolled back.' as Message
	Print 'Testing is set to 1, transaction has been rolled back.' 
Rollback
End
Else If (select Count(*) 
from #SeedTable
Where Left(StartMonthAndDay,2) > 12 
or Left(StartMonthAndDay,2) < 01
or  Left(EndMonthAndDay,2) > 12 
or Left(EndMonthAndDay,2) < 00) > 0
Begin
	Select 'Invalid Date in Seed table transaction has been rolled back.' as Message
	Print 'Invalid Date in Seed table transaction has been rolled back.' 
	rollback
END
ELSE if @Deploy = 1
Begin
	Select 'You have an open Transaction Terms have been added to the Semester table but not committed.' as Message
	Print 'You have an open Transaction Terms have been added to the Semester table but not committed.' 
End
Else
BEGIN
	Select 'Terms added to the Semester table and committed.' as Message
	Print 'Terms added to the Semester table and committed.' 
	commit
END


/*
Commit
*/