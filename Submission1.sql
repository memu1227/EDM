 -- Submission 1 Problems: 

 -- 1) Find the minimum, maximum and average of the average temperature column for each state sorted by state name.

SELECT 
    a.State_Name, 
    MAX(t.Average_Temp) as [Maximum Temperature],
    MIN(t.Average_Temp) as [Minimum Temperature],
    AVG(t.Average_Temp) as [Average Temperature]
FROM AQS_Sites a 
JOIN Temperature t ON a.State_Code = t.State_Code AND a.Site_Number = t.Site_Num AND a.County_Code = t.County_Code
GROUP BY a.State_Name
ORDER BY a.State_Name

-- 2) Write a query to count all the suspect temperatures (below -39o and above 105o)
 SELECT
    a.State_Name,
    a.State_Code,
    a.Site_Number,
    a.County_Code,
    COUNT(t.Average_Temp) as Num_Bad_Entries
FROM AQS_Sites a
JOIN Temperature t ON a.State_Code = t.State_Code AND a.Site_Number = t.Site_Num AND a.County_Code = t.County_Code
WHERE t.Average_Temp < -39 OR t.Average_Temp > 105
GROUP BY a.State_Name, a.State_Code, a.Site_Number, a.County_Code
ORDER BY a.State_Name,a.State_Code,a.County_Code,a.Site_Number

-- 3) include site name
 SELECT
    a.State_Name,
    a.State_Code,
    a.Site_Number,
    a.County_Code,
    a.Local_Site_Name,
    COUNT(t.Average_Temp) as Num_Bad_Entries
FROM AQS_Sites a
JOIN Temperature t ON a.State_Code = t.State_Code AND a.Site_Number = t.Site_Num AND a.County_Code = t.County_Code
WHERE t.Average_Temp < -39 OR t.Average_Temp > 105
GROUP BY a.State_Name, a.State_Code, a.Site_Number, a.County_Code, a.Local_Site_Name
ORDER BY a.State_Name,a.State_Code,a.County_Code,a.Site_Number

-- 4) Create View 
-- Drop the view if it exists
IF OBJECT_ID('dbo.AQS_TempView', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.AQS_TempView;
END

CREATE VIEW dbo.AQS_TempView
AS 
SELECT 
    a.State_Code,
    a.State_Name,
    a.County_Code,
    a.Site_Number,
    a.City_Name,
    a.Local_Site_Name,
    t.Average_Temp,
    t.Date_Local
FROM AQS_Sites a 
JOIN Temperature t ON a.State_Code = t.State_Code AND a.Site_Number = t.Site_Num AND a.County_Code = t.County_Code
WHERE 
    a.State_Code = t.State_Code
    AND a.County_Code = t.County_Code
    AND a.Site_Number = t.Site_Num
    AND a.Local_Site_Name IS NOT NULL 
    AND a.state_code NOT IN ('CC', '80','178','72','66')
    AND t.Average_Temp >= -39
    AND ((t.Average_Temp <=125) OR (t.Average_Temp <=105 AND a.state_code IN (18, 26, 29, 30, 37, 38)))


-- 5) delete duplicate rows
WITH CTE_Duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY State_Code, County_Code, Site_Num, average_temp, Date_Local ORDER BY (SELECT NULL)) AS RowNum
    FROM dbo.Temperature
)
DELETE FROM CTE_Duplicates
WHERE RowNum > 1;
-- Step 2: Create the filtered view with the correct columns 
SELECT
    A.State_Code,
    A.State_Name,
    A.County_Code,
    A.Site_Number,
    A.City_name,
    A.Local_Site_Name,
    T.Average_Temp,
    T.Date_Local
FROM
    dbo.Temperature AS T
JOIN
    dbo.Aqs_sites AS A
    ON T.State_Code = A.State_Code
    AND T.County_Code = A.County_Code
    AND T.Site_Num = A.Site_Number
WHERE
    T.Average_Temp >= -39 AND T.Average_Temp <= 125
    AND T.State_Code NOT IN ('30', '29', '37', '26', '18', '38')
    AND A.State_Name NOT IN ('Canada', 'US territories')
    AND A.Local_Site_Name IS NOT NULL;


-- Drop the indexed view if it exists
IF OBJECT_ID('dbo.AQS_TempIndexedView', 'V') IS NOT NULL
BEGIN
    DROP VIEW dbo.AQS_TempIndexedView;
END

-- Drop tables if they exist
IF OBJECT_ID('dbo.AQS_TempTable1', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.AQS_TempTable1;
END

IF OBJECT_ID('dbo.AQS_TempTable2', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.AQS_TempTable2;
END

-- Create temporary tables to hold original view
SELECT 
    a.State_Code,
    a.State_Name,
    a.County_Code,
    a.Site_Number,
    a.City_Name,
    a.Local_Site_Name,
    t.Average_Temp,
    t.Date_Local
INTO dbo.AQS_TempTable1
FROM AQS_Sites a 
JOIN Temperature t ON a.State_Code = t.State_Code AND a.Site_Number = t.Site_Num AND a.County_Code = t.County_Code
WHERE 
    a.State_Code = t.State_Code
    AND a.County_Code = t.County_Code
    AND a.Site_Number = t.Site_Num
    AND a.Local_Site_Name IS NOT NULL 
    AND a.state_code NOT IN ('CC', '80', '178', '72', '66')
    AND t.Average_Temp >= -39
    AND ((t.Average_Temp <= 125) OR (t.Average_Temp <= 105 AND a.state_code IN (18, 26, 29, 30, 37, 38)));

-- Create the indexed view using the temporary table
CREATE VIEW dbo.AQS_TempIndexedView
WITH SCHEMABINDING
AS
SELECT 
    State_Code,
    State_Name,
    County_Code,
    Site_Number,
    City_Name,
    Local_Site_Name,
    Average_Temp,
    Date_Local
FROM dbo.AQS_TempTable1;


-- Verify the indexed view 
SELECT State_Code, State_Name, COUNT(*) AS Num_of_Days
FROM dbo.AQS_TempIndexedView
GROUP BY State_Code, State_Name
ORDER BY State_Code, State_Name;

/* 6. Using the SQL RANK statement, rank the states by Average Temperatu
*/
SELECT
    State_Name,
    MIN(Average_Temp) AS [Minimum Temp],
    MAX(Average_Temp) AS [Maximum Temp],
    AVG(Average_Temp) AS [Average Temp],
    RANK() OVER (ORDER BY AVG(Average_Temp) DESC) AS State_rank
FROM
    dbo.AQS_TempIndexedView
GROUP BY
    State_Name;

/* 7.	You’ve decided that you want to see the ranking of each high temperatures for 
each city in each state to see if that helps you decide where to live. Write a query 
that ranks (using the rank function) the states by averages temperature and then ranks 
the cities in each state. The ranking of the cities should restart at 1 when the query 
returns a new state. You also want to only show results for the 10 states and the 4 cities 
within each state with the highest average temperatures.
Note: you will need to use multiple nested queries to get the State and City rankings,
join them together and then apply a where clause to limit the state ranks shown.
*/
WITH RankedStates AS (
    SELECT
        State_Name,
        AVG(Average_Temp) AS [Average Temp],
        RANK() OVER (ORDER BY AVG(Average_Temp) DESC) AS State_Rank
    FROM
        dbo.AQS_TempIndexedView
    GROUP BY
        State_Name
),
RankedCities AS (
    SELECT
        State_Name,
        City_Name,
        AVG(Average_Temp) AS [Average Temp],
        RANK() OVER (PARTITION BY State_Name ORDER BY AVG(Average_Temp) DESC) AS State_City_Rank
    FROM
        dbo.AQS_TempIndexedView
    GROUP BY
        State_Name, City_Name
)
SELECT
    RS.State_Rank,
    RS.State_Name,
    RC.State_City_Rank,
    RC.City_Name,
    RC.[Average Temp]
FROM
    RankedStates AS RS
JOIN
    RankedCities AS RC ON RS.State_Name = RC.State_Name
WHERE
    RS.State_Rank <= 10 AND RC.State_City_Rank <= 4
ORDER BY
    RS.State_Rank, RC.State_City_Rank;

/*8.	You notice in the results that sites with Not in a City as the City Name are 
include but do not provide you useful information. Exclude these sites from all future answers. 
You can do this by either adding it to the where clause in the remaining queries or updating the view 
you created in #4. Include the SQL for #7 with the revised answer. Notice Florida now only has 3 rows.
*/
-- Step 1: Update the view to exclude sites with "Not in a City" as City Name
SELECT
    A.State_Code,
    A.State_Name,
    A.County_Code,
    A.Site_Number,
    A.City_name,
    A.Local_Site_Name,
    T.Average_Temp,
    T.Date_Local
FROM
    dbo.Temperature AS T
JOIN
    dbo.Aqs_sites AS A
    ON T.State_Code = A.State_Code
    AND T.County_Code = A.County_Code
    AND T.Site_Num = A.Site_Number
WHERE
    T.Average_Temp >= -39 AND T.Average_Temp <= 125
    AND T.State_Code NOT IN ('30', '29', '37', '26', '18', '38')
    AND A.State_Name NOT IN ('Canada', 'US territories')
    AND A.Local_Site_Name IS NOT NULL
    AND A.City_name != 'Not in a City';

-- Step 2: Revised SQL from #7
WITH RankedStates AS (
    SELECT
        State_Name,
        AVG(Average_Temp) AS [Average Temp],
        RANK() OVER (ORDER BY AVG(Average_Temp) DESC) AS State_Rank
    FROM
       dbo.AQS_TempIndexedView
    GROUP BY
        State_Name
),
RankedCities AS (
    SELECT
        State_Name,
        City_Name,
        AVG(Average_Temp) AS [Average Temp],
        RANK() OVER (PARTITION BY State_Name ORDER BY AVG(Average_Temp) DESC) AS State_City_Rank
    FROM
        dbo.AQS_TempIndexedView
    GROUP BY
        State_Name, City_Name
)
SELECT
    RS.State_Rank,
    RS.State_Name,
    RC.State_City_Rank,
    RC.City_Name,
    RC.[Average Temp]
FROM
    RankedStates AS RS
JOIN
    RankedCities AS RC ON RS.State_Name = RC.State_Name
WHERE
    RS.State_Rank <= 10 AND RC.State_City_Rank <= 4
ORDER BY
    RS.State_Rank, RC.State_City_Rank;

/* 9. You decide you like the monthly average temperature to be at least 70 degrees. 
Write a query that returns the states and cities that meets this condition, the number 
of months where the average is above 70, the number of days in the database where the 
days are about 70 and calculate the average monthly temperature by month. 
Hint, use the datepart function to identify the month for your calculations.
*/
WITH MonthlyAvg AS (
    SELECT
        State_Name,
        City_Name,
        DATEPART(MONTH, Date_Local) AS Month,
        AVG(Average_Temp) AS Avg_Temp
    FROM
        dbo.AQS_TempIndexedView
    GROUP BY
        State_Name, City_Name, DATEPART(MONTH, Date_Local)
),
CityStats AS (
    SELECT
        State_Name,
        City_Name,
        COUNT(DISTINCT Month) AS Num_Months,
        SUM(CASE WHEN Avg_Temp > 70 THEN 1 ELSE 0 END) AS Num_Days_Above_70,
        COUNT(CASE WHEN Avg_Temp > 70 THEN 1 END) AS Num_Days_Above_70_Average,
        AVG(Avg_Temp) AS Avg_Monthly_Temp
    FROM
        MonthlyAvg
    GROUP BY
        State_Name, City_Name
)
SELECT
    State_Name,
    City_Name,
    Num_Months,
    Num_Days_Above_70,
    Num_Days_Above_70_Average,
    Avg_Monthly_Temp
FROM
    CityStats
WHERE
    Avg_Monthly_Temp >= 70;

/* 10. You assume that the temperatures follow a normal distribution and that the majority 
of the temperatures will fall within the 40% to 60% range of the cumulative distribution. 
Using the CUME_DIST function, show the temperatures for the cities having an average temperature 
of at least 70 degree. Only show the first temperature and the last temperature that fall within 
the 40% and 60% range s that fall within the range. 
Hint: use min and max in the top select statement. */
WITH CityStats AS (
    SELECT
        State_Name,
        City_Name,
        Average_Temp,
        CUME_DIST() OVER (PARTITION BY State_Name, City_Name ORDER BY Average_Temp) AS Cumulative_Dist
    FROM
        dbo.AQS_TempIndexedView
    WHERE
        Average_Temp >= 70
)
SELECT
    State_Name,
    City_Name,
    MIN(CASE WHEN Cumulative_Dist >= 0.4 THEN Average_Temp END) AS [40 Percentile Temp],
    MAX(CASE WHEN Cumulative_Dist <= 0.6 THEN Average_Temp END) AS [60 Percentile Temp]
FROM
    CityStats
GROUP BY
    State_Name, City_Name
HAVING
    MIN(CASE WHEN Cumulative_Dist >= 0.4 THEN Average_Temp END) IS NOT NULL
    AND MAX(CASE WHEN Cumulative_Dist <= 0.6 THEN Average_Temp END) IS NOT NULL;

    
/* 11. You remember from your statistics classes that to get a smoother distribution 
of the temperatures and eliminate the small daily changes that you should use a moving 
average instead of the actual temperatures. Using the windowing within a ranking function 
to create a 4 day moving average (3 previous, 1 after), calculate the moving average for 
each day of the year for Mission Texas, 
Hint: You will need to datepart to get the day of the year for your moving average. 
You moving average should use the 3 days prior and 3 days after for the moving average.
*/
WITH DailyTemps AS (
    SELECT
        State_Name,
        City_Name,
        DATEPART(DAYOFYEAR, Date_Local) AS Day_of_the_Year,
        Average_Temp,
        RANK() OVER (PARTITION BY State_Name, City_Name ORDER BY DATEPART(DAYOFYEAR, Date_Local)) AS Day_Rank
    FROM
        dbo.AQS_TempIndexedView
    WHERE
        State_Name = 'Texas' AND City_Name = 'Mission'
)
SELECT
    State_Name,
    City_Name,
    Day_of_the_Year,
    AVG(Average_Temp) OVER (PARTITION BY State_Name, City_Name ORDER BY Day_Rank
                           ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING) AS Rolling_Avg_Temp
FROM
    DailyTemps;







