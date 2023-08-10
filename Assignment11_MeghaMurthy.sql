-- 1) Create and populate a column called  UCID_Total_G_Played in the People Table
ALTER TABLE People
    ADD mm2836_Total_G_Played INT
--populate column: Total _G_Played is simply the sum of all the G columns for a player in the FIELDING table
UPDATE People
SET mm2836_Total_G_Played = (
    SELECT SUM(G)
    FROM Fielding
    WHERE People.playerID = Fielding.playerID
)

-- 2) and a column called UCID_Career_Range_Factor in the PEOPLE table. 
ALTER TABLE People
    ADD mm2836_Career_Range_Factor DECIMAL(10,4)

-- populate column: Career_Range_Factor (RF) = 9*sum(PO+A)/(sum(InnOuts)/3)
UPDATE People
SET mm2836_Career_Range_Factor = (
    SELECT (9*SUM(PO+A))/NULLIF((SUM(CAST(InnOuts AS INT))/3), 0)
    FROM Fielding
    WHERE People.playerID = Fielding.playerID
)

--3) write a trigger that updates the both of the columns whenever there is a row inserted, updated or deleted from the FIELDING table 
-- DDL that creates the trigger must also check to see if the trigger exists before creating it.
IF OBJECT_ID('mm2836' + '_ColFieldingUpdates', 'TR') IS NOT NULL
    DROP TRIGGER mm2836_ColFieldingUpdates

GO

--create trigger on fielding
CREATE TRIGGER mm2836_ColFieldingUpdates
ON FIELDING
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    --update CRF
    UPDATE People
    SET mm2836_Career_Range_Factor = (
        SELECT (9*SUM(PO+A))/NULLIF((SUM(CAST(InnOuts AS INT))/3), 0)
        FROM Fielding
        WHERE People.playerID = Fielding.playerID
    );

    --update total g played
    UPDATE PEOPLE 
    SET mm2836_Total_G_played = (
        SELECT ISNULL(SUM(INSERTED.G), 0) - ISNULL(SUM(DELETED.G), 0)
        FROM INSERTED 
        FULL JOIN DELETED ON INSERTED.playerID = DELETED.playerID
        WHERE People.playerID = ISNULL(INSERTED.playerID,DELETED.playerID)
    );
END;

--4) Verify Triggers

--INSERTING
-- Checking before insertion
SELECT * FROM People 
SELECT * FROM Fielding

--insert playerID into people table
INSERT INTO People (playerID)
Values ('drake01')

INSERT INTO Fielding (playerID, G, PO, A, InnOuts)
VALUES ('drake01', 1, 3, 3, 4)

-- check after insertion and before update
SELECT * FROM People 
SELECT * FROM Fielding

--updates
UPDATE Fielding
SET G = 2 
WHERE playerID = 'drake01'

--check after update and before deletion
SELECT * FROM People 
SELECT * FROM Fielding

--deletion
DELETE FROM Fielding 
WHERE playerID = 'drake01'

--check after deletion
SELECT * FROM People 
SELECT * FROM Fielding

-- disable 
DISABLE TRIGGER mm2836_ColFieldingUpdates ON Fielding

