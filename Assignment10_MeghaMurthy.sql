use BaseBall_Summer_2023
/****** Object:  Table [dbo].[AllstarFull]    Script Date: 8/5/2017 2:08:04 PM ******/
IF OBJECT_ID (N'dbo.salaries_backup', N'U') IS NOT NULL
DROP TABLE [dbo].[salaries_backup]
GO

select * into salaries_Backup from salaries

-- 1) Alter Table to add primary key --

-- delete rows causing problems after saving them to a backup table --
IF OBJECT_ID (N'dbo.deleted_salaries_rows',N'U') IS NOT NULL
DROP TABLE [dbo].[deleted_salaries_rows]

GO
SELECT * INTO dbo.deleted_salaries_rows
FROM dbo.salaries_backup
WHERE lgid IS NULL;

--delete problem rows--
GO
DELETE FROM dbo.salaries_backup
WHERE lgid IS NULL;

-- checking -- 
GO
SELECT * FROM deleted_salaries_rows
SELECT * FROM salaries_backup WHERE lgID is NULL OR teamID is NULL OR yearID is NULL or playerID is NULL;


-- delete duplicate keys
GO
WITH dupKeys AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY yearID, teamID, lgID, playerID ORDER BY (SELECT NULL)) AS RowNum
    FROM dbo.salaries_backup
)
DELETE FROM dupKeys
WHERE RowNum > 1;


-- Alter Table to add primary key --
GO
ALTER TABLE dbo.salaries_backup
    ALTER COLUMN playerID VARCHAR(255) NOT NULL
GO
ALTER TABLE dbo.salaries_backup
    ALTER COLUMN yearID INT NOT NULL
GO
ALTER TABLE dbo.salaries_backup
    ALTER COLUMN lgID VARCHAR(25) NOT NULL
GO
ALTER TABLE dbo.salaries_backup
    ALTER COLUMN teamID VARCHAR(255) NOT NULL
GO
ALTER TABLE dbo.salaries_backup
    ADD CONSTRAINT PK_salaries_backup PRIMARY KEY (yearID, teamID, lgID, playerID);


--B) Foreign Keys
-- i.	Delete rows in the salaries_backup table not found in the people table. 
DELETE FROM salaries_backup
WHERE playerid NOT IN (SELECT playerid FROM people)

-- ii.	Delete rows in the salaries_backup table not found in the teams table. 

DELETE FROM salaries_backup
WHERE teamid NOT IN (SELECT teamid FROM teams)

-- iii. Create Foreign Keys
--People Table
ALTER TABLE salaries_backup
ADD CONSTRAINT FK_sb_ppl
FOREIGN KEY (playerid)
REFERENCES people (playerid)

--Teams Table

Alter Table salaries_backup
Add CONSTRAINT FK_sb_teams
FOREIGN KEY (teamid)
REFERENCES teams (teamid);


-- 2) uses the RANK function to rank the careerBA column where the careerBA < 0.3240 and > 0.10. --
GO
WITH ranked_players AS (
    SELECT playerID, [Full NAme], careerBA,
        RANK() OVER (ORDER BY careerBA DESC) AS Rank
    FROM IS631View
    WHERE careerBA > 0.10 AND careerBA < 0.3240
)
SELECT playerID, [Full NAme], careerBA, Rank
FROM ranked_players;

-- 3) same thing as above but using dense rank
GO
WITH ranked_players AS (
    SELECT playerID, [Full NAme], careerBA,
        DENSE_RANK() OVER (ORDER BY careerBA DESC) AS Rank
    FROM IS631View
    WHERE careerBA > 0.10 AND careerBA < 0.3240
)
SELECT playerID, [Full NAme], careerBA, Rank
FROM ranked_players;

--4) same as two but ranking by year
GO
WITH ranked_players AS (
    SELECT playerID, [Full NAme], careerBA, LastPlayed,
        RANK() OVER (PARTITION BY LastPlayed ORDER BY careerBA DESC) AS RankbyYear
    FROM IS631View
    WHERE careerBA > 0.10 AND careerBA < 0.3240
)
SELECT playerID, [Full NAme], careerBA, LastPlayed, RankbyYear
FROM ranked_players
ORDER BY LastPlayed DESC, RankbyYear; 

--5) same as 3 but with nTILE
GO
WITH ranked_players AS (
    SELECT playerID, [Full NAme], LastPlayed, careerBA,
        NTILE(10) OVER (ORDER BY careerBA DESC) AS TenthRanking
    FROM IS631View
    WHERE careerBA > 0.10 AND careerBA < 0.3240
)
SELECT playerID, [Full NAme], LastPlayed, careerBA, TenthRanking
FROM ranked_players
ORDER BY LastPlayed DESC;

--6) windowed salary
GO
SELECT teamID, yearID, FORMAT(Avg_Salary,'C') as Avg_Salary,
    FORMAT(AVG(Avg_Salary) OVER (PARTITION by teamID ORDER BY yearID ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING),'C') AS Windowed_Salary
FROM (
    SELECT teamID, yearID, AVG(salary) as Avg_Salary
    FROM Salaries
    GROUP BY teamID, yearID
) AS Team_Salaries
ORDER BY teamID, yearID

--7)
SELECT
    b.teamID,
    t.name AS team_name,
    b.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS Full_Name,
    SUM(b.H) AS total_hits,
    SUM(b.AB) AS total_at_bats,
    FORMAT(SUM(b.H) * 1.0 / NULLIF(SUM(b.AB), 0), '0.0000') AS player_batting_average,
    RANK() OVER (PARTITION BY b.teamID ORDER BY SUM(b.H) DESC) AS team_batting_rank,
    RANK() OVER (ORDER BY SUM(b.H) DESC) AS all_players_rank
FROM Batting b
JOIN People p ON b.playerID = p.playerID
JOIN Teams t ON b.teamID = t.teamID AND b.yearID = t.yearID AND b.lgID = t.lgID
GROUP BY b.teamID, b.playerID, p.nameGiven, p.nameFirst, p.nameLast, t.name
HAVING SUM(b.H) >= 150
ORDER BY b.teamID, all_players_rank


--8) Months 
GO
WITH MonthCTE AS (
    SELECT 1 AS MonthNumber
    UNION ALL
    SELECT MonthNumber + 1
    FROM MonthCTE
    WHERE MonthNumber < 12
)
SELECT
    MonthNumber,
    DATENAME(MONTH, DATEFROMPARTS(YEAR(GETDATE()), MonthNumber, 1)) AS MonthName
FROM MonthCTE

--9) 
GO
SELECT *
FROM (
    SELECT teamID,HR,yearID
    FROM Batting
    WHERE yearID IN ('1895', '1896', '1897', '1898', '1899', '1995', '1996', '1997', '1998', '1999', '2018', '2019', '2020', '2021', '2022')
) as yrcol
PIVOT (
    COUNT(HR)
    FOR yearID IN ([1895], [1896], [1897], [1898], [1899], [1995], [1996], [1997], [1998], [1999], [2018], [2019], [2020], [2021], [2022])
) AS PivotTable




