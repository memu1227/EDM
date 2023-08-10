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