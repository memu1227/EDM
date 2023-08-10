-- Create a geospatial column in AQS Sites
IF NOT EXISTS(
    SELECT *
FROM sys.columns
WHERE Name
= N'geolocation' AND Object_ID = Object_ID(N'AQS_Sites'))
BEGIN
ALTER TABLE AQS_Sites ADD geolocation Geography NULL 
END
GO
UPDATE aqs_sites
SET [geolocation] = geography::Point (Latitude, Longitude, 4326)
where ([LATITUDE] > 0 and latitude <> '') or (Latitude is not null and longitude is not null)

-- Create Stored Procedure
IF OBJECT_ID('Summer2023_Calc_GEO_Distance', 'P') IS NOT NULL
    DROP PROCEDURE Summer2023_Calc_GEO_Distance;
GO

CREATE PROCEDURE Summer2023_Calc_GEO_Distance
    @longitude FLOAT,
    @latitude FLOAT,
    @State VARCHAR(50),
    @rownum INT
AS 
BEGIN
    DECLARE @h GEOGRAPHY
    SET @h = geography::Point(@latitude, @longitude, 4326)

    SELECT TOP(@rownum)
        Site_Number,
        ISNULL(Local_Site_Name, CONVERT(VARCHAR(100), Site_Number) + ' ' + City_Name) AS Local_Site_Name,
        Address,
        City_Name,
        State_Name,
        Zip_Code,
        geolocation.STDistance(@h) AS Distance_In_Meters,
        Latitude,
        Longitude,
        (geolocation.STDistance(@h) * 0.000621371) / 55 AS Hours_of_Travel
    FROM AQS_Sites
    WHERE State_Name = @State
    ORDER BY geolocation.STDistance(@h)
END
GO

EXEC Summer2023_Calc_GEO_Distance @latitude = 40.006645, @longitude = -75.703381, @State = 'Pennsylvania', @rownum = 10;
EXEC Summer2023_Calc_GEO_Distance @latitude = 37.441883, @longitude = -122.14302, @State = 'California', @rownum = 15;