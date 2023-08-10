-- Creating Leagues Table
IF OBJECT_ID (N'dbo.[Leagues]', N'U') IS NOT NULL
    DROP TABLE dbo.[Leagues]


GO
CREATE TABLE Leagues(
    lgID VARCHAR(25) PRIMARY KEY
)


-- Insert Distinct lgID into Leagues table from teams table
INSERT INTO Leagues
    SELECT DISTINCT lgID 
    FROM Teams

-- Adding foreign key constraints to the Teams table (franchID and lgID)
ALTER TABLE Teams
    ADD CONSTRAINT franchID_FK FOREIGN KEY (franchID) REFERENCES TeamsFranchises (franchID)

ALTER TABLE Teams
    ADD CONSTRAINT lgID_FK FOREIGN KEY (lgID) REFERENCES Leagues (lgID)

-- ALLSTAR FULL TABLE CHANGES AND FOREIGN KEYS

-- All Star Full Table: adding foreign keys and data cleanup
ALTER TABLE AllstarFull
    ADD CONSTRAINT playerID_FK FOREIGN KEY(playerID) REFERENCES People(playerID)
ALTER TABLE AllstarFull
    ADD CONSTRAINT AllstarFull_Teams_FK FOREIGN KEY (yearID, lgID, teamID)
    REFERENCES Teams (yearID, lgID, teamID)

UPDATE AllstarFull
SET yearID = t.yearID, lgID = t.lgID, teamID = t.teamID
FROM AllstarFull a
JOIN Teams t ON a.yearID = t.yearID AND t.teamID = a.teamID AND a.lgID = t.lgID
    

--set Braves teamID to ML1 in Allstar Table  where it is not ML1 after checking... 
SELECT DISTINCT a.teamID, a.yearID,t.teamID as 'Teams TeamID', t.name FROM AllstarFull a
JOIN Teams t ON t.yearID = a.yearID AND t.lgID = a.lgID 
WHERE t.teamID != a.teamID 


--updating Braves teamID
UPDATE AllstarFull
SET teamID = 'ML1'
WHERE teamID = 'MLN' AND yearID BETWEEN '1953' AND '1965'

UPDATE AllstarFull
SET teamID = t.teamID
FROM AllstarFull a
JOIN Teams t ON t.yearID = a.yearID AND t.lgID = a.lgID
WHERE a.teamID != t.teamID
 

--checking teamID for LAA
SELECT t.teamID as 'Teams TeamID',a.teamID as 'Allstar TeamID' FROM AllstarFull a
JOIN Teams t ON t.yearID = a.yearID AND t.lgID = a.lgID
WHERE t.teamID = 'LAA'

--update allstarfullteamID for LAA to match teams.teamID
UPDATE AllstarFull
SET teamID = t.teamID
FROM AllstarFull a
JOIN Teams t ON t.yearID = a.yearID AND t.lgID = a.lgID
WHERE t.teamID = 'LAA' AND a.teamID != t.teamID

--Updating the lgID for teamID SLN where lgID = AL and not NL (for AllstarFull Table)
UPDATE AllstarFull
SET lgID = 'NL'
WHERE teamID = 'SLN' AND lgID != 'NL'


-- APPEARACES TABLE FOREIGN KEY AND DATA CLEANUP

-- Appearances Table foreign Keys
ALTER TABLE Appearances
    ADD CONSTRAINT Appearances_playerID_FK FOREIGN KEY(playerID) REFERENCES People(playerID)
ALTER TABLE Appearances
    ADD CONSTRAINT Appearances_Teams_FK FOREIGN KEY (yearID, lgID, teamID)
    REFERENCES Teams (yearID, lgID, teamID)

--finding invalid playerID
--SELECT a.playerID
--FROM Appearances a
--LEFT JOIN People p ON a.playerID = p.playerID
--WHERE p.playerID IS NULL

SELECT a.playerID as 'Appearances playerID', p.playerID as 'Players playerID'
FROM Appearances a 
LEFT JOIN People p ON a.playerID = p.playerID
WHERE a.playerID LIKE 
    (
        --result is thompan01
        SELECT a.playerID
        FROM Appearances a
        LEFT JOIN People p ON a.playerID = p.playerID
        WHERE p.playerID IS NULL
    )
--Delete invalid player
DELETE FROM Appearances
WHERE playerID IN (
    SELECT a.playerID
    FROM Appearances a
    LEFT JOIN People p ON a.playerID = p.playerID
    WHERE p.playerID IS NULL
)

-- HOME GAMES

-- HomeGames Table FOREIGN KEYS
ALTER TABLE HomeGames
    ADD CONSTRAINT HomeGames_Teams_FK FOREIGN KEY (yearID, lgID, teamID)
    REFERENCES Teams (yearID, lgID, teamID)

ALTER TABLE HomeGames
    ADD CONSTRAINT park_FK FOREIGN KEY (parkID) REFERENCES Parks(parkID)

--adding missing parks data?(so ill just add park name bc the instructions say to add minimum data?)
ALTER TABLE HomeGames
ADD parkName VARCHAR(255)

UPDATE HomeGames
SET parkName = p.parkName
FROM HomeGames hg 
JOIN Parks p ON hg.parkID = p.parkID
WHERE hg.parkName is NULL


-- Managers Table

ALTER TABLE Managers
    ADD CONSTRAINT Managers_playerID_FK FOREIGN KEY(playerID) REFERENCES People(playerID)
ALTER TABLE Managers
    ADD CONSTRAINT Managers_Teams_FK FOREIGN KEY (yearID, lgID, teamID)
    REFERENCES Teams (yearID, lgID, teamID)


-- Award Managers Table

-- foreign keys
ALTER TABLE AwardsManagers
    ADD CONSTRAINT AwardsManager_lgID_FK FOREIGN KEY(lgID) REFERENCES Leagues(lgID)
ALTER TABLE AwardsManagers
    ADD CONSTRAINT AwardsManagers_playerID_FK FOREIGN KEY(playerID) REFERENCES People(playerID)

--fixing lgid problem
SELECT t.name, aw.lgID as 'Awards Manager lgID', t.lgID as 'Teams lgID'
FROM AwardsManagers aw 
JOIN Teams t ON t.yearID = aw.yearID

UPDATE AwardsManagers
SET lgID = t.lgID
FROM AwardsManagers aw 
JOIN Teams t ON t.yearID = aw.yearID
WHERE aw.lgID != t.lgID