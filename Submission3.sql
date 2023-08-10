-- add geolocation table to guns_all_incidents table
IF NOT EXISTS(
    SELECT *
FROM sys.columns
WHERE Name
= N'geolocation' AND Object_ID = Object_ID(N'Gun_All_Incidents'))
BEGIN
ALTER TABLE Gun_All_Incidents ADD geolocation Geography NULL 
END
GO
UPDATE Gun_All_Incidents
SET [GeoLocation] = geography::Point (Latitude, Longitude, 4326)
where ([LATITUDE] > 0 and latitude <> '') or (Latitude is not null and longitude is not null)


-- Pivot Table
SELECT *
FROM (
    SELECT 
        State, 
        YEAR(Date) as IncidentYear,
        Sum(Killed + Injured) as Total_Shootings
    FROM Gun_All_Incidents
    GROUP BY Date, State, Injured, Killed
) AS GunData
PIVOT (
    SUM(Total_Shootings)
    FOR IncidentYear IN ([2015], [2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023]) 
) AS PivotTable
ORDER BY State

-- Modified Query
SELECT *
FROM (
    SELECT 
        State, 
        City,
        YEAR(Date) as IncidentYear,
        Sum(Killed + Injured) as Total_Shootings
    FROM Gun_All_Incidents
    WHERE State = 'California'
    GROUP BY Date, State, Injured, Killed,City
) AS GunData
PIVOT (
    SUM(Total_Shootings)
    FOR IncidentYear IN ([2015], [2016], [2017], [2018], [2019], [2020], [2021], [2022], [2023]) 
) AS PivotTable
ORDER BY City

-- updating stored procedure
IF OBJECT_ID('Summer2023_Calc_GEO_Distance_Crimes', 'P') IS NOT NULL
    DROP PROCEDURE Summer2023_Calc_GEO_Distance_Crimes;
GO

CREATE PROCEDURE Summer2023_Calc_GEO_Distance_Crimes
    @longitude FLOAT,
    @latitude FLOAT,
    @State VARCHAR(50),
    @rownum INT
AS 
BEGIN
    DECLARE @h GEOGRAPHY
    SET @h = geography::Point(@latitude, @longitude, 4326)

    SELECT TOP(@rownum)
        a.Site_Number,
        ISNULL(Local_Site_Name, CONVERT(VARCHAR(100), a.Site_Number) + ' ' + City_Name) AS Local_Site_Name,
        a.Address,
        City_Name,
        State_Name,
        Zip_Code,
        a.geolocation.STDistance(@h) AS Distance_In_Meters,
        a.Latitude,
        a.Longitude,
        (a.geolocation.STDistance(@h) * 0.000621371) / 55 AS Hours_of_Travel,
        SUM(CASE WHEN a.geolocation.STDistance(gi.geolocation) <= 16000 THEN (gi.killed + gi.injured) ELSE 0 END) AS Total_Shootings,
        YEAR(gi.Date) AS Crime_Year
    FROM AQS_Sites a
    CROSS JOIN Gun_all_incidents gi
    WHERE a.State_Name = @State
        AND a.geolocation.STDistance(gi.geolocation) <= 16000
    GROUP BY a.Site_Number, Local_Site_Name, a.Address, City_Name, State_Name, Zip_Code, a.Latitude, a.Longitude, a.geolocation.STDistance(@h), YEAR(gi.Date)
END
GO


EXEC Summer2023_Calc_GEO_Distance_Crimes @latitude = 41.8781, @longitude = -87.6298, @State = 'Illinois', @rownum = 10

-- 6) rank by state
DECLARE @state VARCHAR(50) = 'New Jersey'; -- Replace with your desired state
DECLARE @rownum INT = (SELECT COUNT(*) FROM AQS_Sites WHERE State_Name = @state);

WITH RankedCities AS (
    SELECT
        a.City_Name,
        SUM(CASE WHEN a.geolocation.STDistance(gi.geolocation) <= 16000 THEN (gi.killed + gi.injured) ELSE 0 END) AS Total_Shootings
    FROM AQS_Sites a
    CROSS JOIN Gun_all_incidents gi
    WHERE a.State_Name = @state
    AND a.geolocation.STDistance(gi.geolocation) <= 16000
    GROUP BY a.City_Name
)
SELECT
    City_Name,
    Total_Shootings,
    DENSE_RANK() OVER (ORDER BY Total_Shootings) AS Shooting_Rank
FROM RankedCities
ORDER BY Total_Shootings;



--Extra Credit 



