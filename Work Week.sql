DECLARE @Holiday DECIMAL(16, 2);

--Set Above to how many days off we have for the week
/**************Do not edit anything below here**************/
/***********************************************************/
DECLARE @DAY NVARCHAR(MAX) = FORMAT(GETDATE(), 'dddd');		--Grabs Day
DECLARE @CurrentTime TIME = FORMAT(GETDATE(), 'HH:mm:ss');-- Get the current time

DECLARE @WorkHours TABLE (		-- Create a table to store work hours
    DayOfWeek VARCHAR(20),
    StartTime TIME,
    EndTime TIME
);

INSERT INTO @WorkHours (DayOfWeek, StartTime, EndTime)		-- Insert your work hours for each day of the week
VALUES 
    ('Monday', '08:00:00', '18:00:00'),
    ('Tuesday', '08:00:00', '18:00:00'),
    ('Wednesday', '08:00:00', '18:00:00'),
    ('Thursday', '08:00:00', '18:00:00');

-- Calculate the total work minutes until the current time today
DECLARE @TotalMinutesToday DECIMAL(10, 2);
SET @TotalMinutesToday = (
    SELECT SUM(CAST(
        DATEDIFF(MINUTE, StartTime, CASE 
            WHEN @CurrentTime > EndTime THEN EndTime
            ELSE @CurrentTime
        END) AS DECIMAL(10, 2))
    ) AS TotalMinutes
    FROM @WorkHours 
    WHERE DayOfWeek = @DAY
);

-- Calculate the total work minutes for the preceding days in the current week
DECLARE @TotalMinutesPreviousDays DECIMAL(10, 2);
SET @TotalMinutesPreviousDays = (
    SELECT SUM(CAST(
        DATEDIFF(MINUTE, StartTime, EndTime) AS DECIMAL(10, 2))
    ) + 
    CASE 
        WHEN @DAY = 'Thursday' THEN +1200
        WHEN @DAY = 'Wednesday' THEN -600
        WHEN @DAY = 'Tuesday' THEN -600
        ELSE +0
    END + (ISNULL(@Holiday, 0) * 600) AS TotalMinutes
    FROM @WorkHours
    WHERE DayOfWeek < @DAY
    AND (@CurrentTime <= EndTime OR DayOfWeek <> FORMAT(GETDATE(), 'dddd'))
);

-- Calculate the total work minutes for the current week
DECLARE @TotalWeekMinutes DECIMAL(10, 2);
SET @TotalWeekMinutes = @TotalMinutesPreviousDays + @TotalMinutesToday;

-- Calculate the percentage of the work week completed
DECLARE @PercentageCompleted DECIMAL(10, 2);
SET @PercentageCompleted = 
    CASE 
        WHEN @DAY = 'Monday' THEN (@TotalMinutesToday / (4 * 10 * 60)) * 100
        ELSE (@TotalWeekMinutes / (4 * 10 * 60)) * 100
    END;

-- Print the result
SELECT CONCAT(@PercentageCompleted, '%') AS [Percentage Completed For Week];