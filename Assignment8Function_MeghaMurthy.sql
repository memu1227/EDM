IF OBJECT_ID('dbo.CareerOBP', 'FN') IS NOT NULL
    DROP FUNCTION dbo.CareerOBP
GO

CREATE FUNCTION CareerOBP (@playerID VARCHAR(255))
RETURNS DECIMAL(5, 4)
BEGIN
    DECLARE @career_obp DECIMAL(5, 4)

    SELECT @career_obp = 
        CAST(H + BB + HBP AS DECIMAL(10, 4)) / NULLIF(CAST(AB AS DECIMAL(10, 4)), 0)
    FROM Batting
    WHERE playerID = @playerID

    RETURN @career_obp
END
