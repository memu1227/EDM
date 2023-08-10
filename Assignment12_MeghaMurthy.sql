-- Add 2 columns to the PEOPLE table. The columns should be UCID_Career_EqA and UCID_Date_Last_Update.
IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'People'
    AND COLUMN_NAME = 'mm2836_Career_EqA'
)
BEGIN
    ALTER TABLE People
    ADD mm2836_Career_Eqa DECIMAL(10,4)
END

IF NOT EXISTS (
    SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'People'
    AND COLUMN_NAME = 'mm2836_Date_Last_Updated'
)
BEGIN
    ALTER TABLE People
    ADD mm2836_Date_Last_Updated DATE NULL
END;


-- Creates a stored procedure containing an update cursor that contains the playerid and the sum of the player’s Equivalent Average 

---creates stored procedure
CREATE PROCEDURE careerEqA AS
BEGIN
    --turns of row count messages
    SET NOCOUNT ON;

    --creates variables
    DECLARE @today DATE
    DECLARE @playerID VARCHAR(255)
    DECLARE @hits INT
    DECLARE @totalBases INT
    DECLARE @walks INT
    DECLARE @hitByPitcher VARCHAR(255)
    DECLARE @stolenBases INT
    DECLARE @caughtSteal INT
    DECLARE @sacrificeHits VARCHAR(255)
    DECLARE @sacrifice VARCHAR(255)
    DECLARE @atBats INT
    DECLARE @eqA DECIMAL(10,4)
    DECLARE @updateCount INT
    DECLARE @msg VARCHAR(255)

    --populates variables
    SET @today = CONVERT(DATE, GETDATE());
    --sets counter to 0
    SET @updateCount = 0;
    
    --start message
    SELECT @msg = 'Starting:';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    --declares cursor and populates it
    DECLARE cEqA CURSOR STATIC FOR
        --select statement to populate cursor
        SELECT
            playerid,
            SUM(H) AS hits,
            SUM(H+(2*B2) + (3*B3)+(4*HR) + BB) AS totalBases,
            SUM(BB) AS walks,
            SUM(CAST(HBP AS INT)) AS hitByPitch,
            SUM(SB) AS stolenBases,
            SUM(CAST(SH AS INT)) AS sacrificeHits,
            SUM(CAST(SF AS INT)) AS sacrificeFlies,
            SUM(AB) AS atBats,
            SUM(CS) AS caughtStealing
        FROM BATTING
        GROUP BY playerid;
    --opens cursor
    OPEN cEqA;

    -- Retrieves rows from the cursor
    FETCH NEXT FROM cEqA INTO @playerID, @hits, @totalBases, @walks, @hitByPitcher, @stolenBases, @sacrificeHits, @sacrifice, @atBats, @caughtSteal;
    --create while loop to process cursor one row at a time
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- checks if denominator is zero
        IF @atBats + @walks + @hitByPitcher + @sacrificeHits + @sacrifice + @caughtSteal + (@stolenBases / 3) = 0
            SET @eqA = 0; 
        ELSE
            SET @eqA = (CONVERT(DECIMAL(10, 4), @hits) + CONVERT(DECIMAL(10, 4), @totalBases) +
                        (1.5 * (CONVERT(DECIMAL(10, 4), @walks) + CONVERT(DECIMAL(10, 4), @hitByPitcher))) +
                        CONVERT(DECIMAL(10, 4), @stolenBases) + CONVERT(DECIMAL(10, 4), @sacrificeHits) +
                        CONVERT(DECIMAL(10, 4), @sacrifice))
                      / (CONVERT(DECIMAL(10, 4), @atBats) + CONVERT(DECIMAL(10, 4), @walks) +
                         CONVERT(DECIMAL(10, 4), @hitByPitcher) + CONVERT(DECIMAL(10, 4), @sacrificeHits) +
                         CONVERT(DECIMAL(10, 4), @sacrifice) + CONVERT(DECIMAL(10, 4), @caughtSteal) +
                         (CONVERT(DECIMAL(10, 4), @stolenBases) / 3));
        --updates people table
        UPDATE People
        SET mm2836_Career_EqA = @eqA,
            mm2836_Date_Last_Updated = @today
        WHERE playerid = @playerID;
        
        SET @updateCount = @updateCount + 1;

        IF @updateCount % 1000 = 0
        BEGIN
            SELECT @msg = 'Processed ' + CAST(@updateCount AS VARCHAR) + ' records';
            RAISERROR(@msg, 0, 1) WITH NOWAIT;
        END;

        FETCH NEXT FROM cEqA INTO @playerID, @hits, @totalBases, @walks, @hitByPitcher, @stolenBases, @sacrificeHits, @sacrifice, @atBats, @caughtSteal;
    END;

    CLOSE cEqA;
    DEALLOCATE cEqA;

    SELECT playerid, mm2836_Career_EqA, mm2836_Date_Last_Updated
    FROM PEOPLE

    -- Show completion message
    SELECT @msg = 'Completed. Processed ' + CAST(@updateCount AS VARCHAR) + ' records';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

END;

--uncomment to drop procedure to rerun
-- DROP PROCEDURE IF EXISTS careerEqA

EXEC careerEqA;

--another stored procedure for #3
CREATE PROCEDURE UpdatedcareerEqA AS
BEGIN
    --turns off row count messages
    SET NOCOUNT ON;

    --creates variables
    DECLARE @today DATE
    DECLARE @playerID VARCHAR(255)
    DECLARE @eqA DECIMAL(10,4)
    DECLARE @updateCount INT
    DECLARE @msg VARCHAR(255)

    --populates variables
    SET @today = CONVERT(DATE, GETDATE());
    --sets counter to 0
    SET @updateCount = 0;
    
    --start message
    SET @msg = 'Starting:';
    PRINT @msg

    --declares cursor and populates it
    DECLARE UcEqA CURSOR STATIC FOR
        --select statement to populate cursor with playerid and EqA value
        SELECT
            b.playerid,
            (SUM(H) + SUM(H+(2*B2) + (3*B3)+(4*HR) + BB) * 1.5 + SUM(BB) + SUM(CAST(HBP AS INT)) + SUM(SB) + SUM(CAST(SH AS INT)) + SUM(CAST(SF AS INT)))
            /NULLIF((SUM(AB) + SUM(BB) + SUM(CAST(HBP AS INT)) + SUM(CAST(SH AS INT)) + SUM(CAST(SF AS INT)) + SUM(CAST(CS AS INT)) + SUM(SB) / 3),0) AS EqA
        FROM BATTING b
        INNER JOIN PEOPLE p ON b.playerid = p.playerid
        --where clause for does not equal current date
        WHERE p.mm2836_Date_Last_Updated != @today
        GROUP BY b.playerid;
    --opens cursor
    OPEN UcEqA;

    -- Get the number of rows in the cursor
    SELECT @msg = 'Number of rows in the cursor: ' + CAST(@@CURSOR_ROWS AS VARCHAR);
    PRINT @msg

    -- Retrieves rows from the cursor
    FETCH NEXT FROM UcEqA INTO @playerID, @eqA;
    --create while loop to process cursor one row at a time
    WHILE @@FETCH_STATUS = 0
    BEGIN
        --updates people table
        UPDATE People
        SET mm2836_Career_EqA = @eqA,
            mm2836_Date_Last_Updated = getdate()-1
        WHERE playerid = @playerID;
        
        SET @updateCount = @updateCount + 1;

        IF @updateCount % 1000 = 0
        --get time and date
        BEGIN
            SET @msg = 'Processed ' + CAST(@updateCount AS VARCHAR) + ' records at ' + CONVERT(VARCHAR, GETDATE(), 120)
            PRINT @msg
        END;

        FETCH NEXT FROM UcEqA INTO @playerID, @eqA;
    END;

    CLOSE UcEqA;
    DEALLOCATE UcEqA;

    SELECT playerid, mm2836_Career_EqA, mm2836_Date_Last_Updated
    FROM PEOPLE

    -- Show completion message
    SET @msg = 'Completed. Processed ' + CAST(@updateCount AS VARCHAR) + ' records';
    PRINT @msg

END;

--uncomment to drop procedure to rerun
-- DROP PROCEDURE IF EXISTS UpdatedcareerEqA

EXEC UpdatedcareerEqA

