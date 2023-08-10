-- 1) Query that selects playerid,teamid,wins,losses,ERA for every player from pitching table
SELECT playerID, teamID, W, L, ERA FROM Pitching

-- 2) Sort Query from above by era in descending order
SELECT playerID, teamID, W, L, ERA FROM Pitching
ORDER BY ERA DESC

-- 3) Return team name and park name sorted by park descending order using teams table
SELECT DISTINCT name, park, teamID from Teams
ORDER BY park DESC

-- 4) Calculate the bases touched for each player and team they played for each year using the BATTING table
SELECT playerID, yearID, teamID, (((B2*2) + (B3*3) + (HR*4))+ BB + H) as 'Total_Bases_Touched' FROM Batting
ORDER BY yearID

-- 5) Add a where clause to #4 tp select only yankees and red sox, sort by bases touched descending order, then playerid ascending
SELECT playerID, yearID, teamID, (B2*2 + B3*3 + HR*4 + BB + H) as 'Total_Bases_Touched' FROM Batting
WHERE teamID IN ('NYA', 'BOS')
ORDER BY Total_Bases_Touched DESC, playerID ASC

-- 6) Calculate Touched percentage of teams touched bases each player was responsible for
SELECT 
    b.playerID, 
    b.yearID, 
    b.teamID, 
   (b.B2 * 2 + b.B3 * 3 + b.HR * 4 + b.BB + b.H) AS 'Total_Bases_Touched',
   (t.B2 * 2 + t.B3 * 3 + t.HR * 4 + t.BB + t.H) AS 'Teams_Total_Bases_Touched',
   FORMAT(CAST((b.B2 * 2 + b.B3 * 3 + b.HR * 4 + b.BB + b.H) AS DECIMAL) * 100.0 / NULLIF((t.B2 * 2 + t.B3 * 3 + t.HR * 4 + t.BB + t.H), 0), 'N2') + '%' AS 'Percent_Teams_Total_Bases_Touched'
FROM Batting b, Teams t 
WHERE 
    b.teamID IN ('NYA', 'BOS')
    AND b.teamID = t.teamID
    AND b.yearID = t.yearID
ORDER BY 
    Percent_Teams_Total_Bases_Touched DESC,
    playerID ASC

-- 7) rewrite query above using join
SELECT 
    b.playerID, 
    b.yearID, 
    b.teamID, 
    (b.B2*2 + b.B3*3 + b.HR*4 + b.BB + b.H) as 'Total_Bases_Touched', 
    (t.B2*2 + t.B3*3 + t.HR*4 + t.BB + t.H) as 'Teams_Total_Bases_Touched',
    FORMAT(CAST((b.B2 * 2 + b.B3 * 3 + b.HR * 4 + b.BB + b.H) AS DECIMAL) * 100.0 / NULLIF((t.B2 * 2 + t.B3 * 3 + t.HR * 4 + t.BB + t.H), 0), 'N2') + '%' AS 'Percent_Teams_Total_Bases_Touched'
FROM Batting b
JOIN Teams t ON b.teamID = t.teamID AND b.yearID = t.yearID
WHERE b.teamID IN ('NYA', 'BOS')
ORDER BY 
    Percent_Teams_Total_Bases_Touched DESC,
    playerID ASC

-- 8) Calculate batting average of players that use their initials as their first name and play for the yankees or redsox
SELECT
    p.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS 'Full_Name',
    t.teamID,
    t.yearID,
    CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) AS 'Batting_Average'
FROM People p
JOIN Batting b ON p.playerID = b.playerID
JOIN 
    Teams t ON b.teamID = t.teamID 
    AND b.yearID = t.yearID
WHERE
    (nameFirst LIKE '%.%' OR nameGiven LIKE '%.%')
    AND CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) IS NOT NULL
    AND t.teamID IN ('NYA', 'BOS')
ORDER BY t.yearID

-- 9) Calculate batting average of players that use their initials as their first name and play for the yankees or redsox 
-- and have a batting average between 0.2 and 0.4999
SELECT
    p.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS 'Full_Name',
    t.teamID,
    t.yearID,
    CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) AS 'Batting_Average'
FROM People p
JOIN Batting b ON p.playerID = b.playerID
JOIN
    Teams t ON b.teamID = t.teamID 
    AND b.yearID = t.yearID
WHERE
    (nameFirst LIKE '%.%' OR nameGiven LIKE '%.%')
    AND CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) BETWEEN 0.2 AND 0.4999
    AND t.teamID IN ('NYA', 'BOS')
ORDER BY
    CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) DESC,
    p.playerID ASC,
    t.yearID ASC

-- 10) Write a query that shows the player’s Total_bases_touched from question #5, the batting_averages from #9 (between .2and .4999)
-- calculate the percentage of the team’s batting average and eliminate any results where the player has an AB less than 50
SELECT
    b.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS 'Full_Name',
    b.yearID,
    t.name AS 'Team_Name',
    (b.B2 * 2 + b.B3 * 3 + b.HR * 4 + b.BB + b.H) AS 'Total_Bases_Touched',
    CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) AS 'Batting_Average',
    CONVERT(DECIMAL(5, 4), ISNULL(t.H * 1.0 / NULLIF(t.AB, 0), 0)) AS 'Team_Batting_Average',
    FORMAT((CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) / CONVERT(DECIMAL(5, 4), ISNULL(t.H * 1.0 / NULLIF(t.AB, 0), 0))), 'P') AS '%_Team_Batting_Average'
FROM Batting b
JOIN People p ON b.playerID = p.playerID
JOIN
    Teams t ON b.teamID = t.teamID 
    AND b.yearID = t.yearID
WHERE
    (p.nameFirst LIKE '%.%' OR p.nameGiven LIKE '%.%')
    AND CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) BETWEEN 0.2 AND 0.4999
    AND b.AB >= 50
ORDER BY
    Batting_Average DESC,
    b.playerID ASC,
    b.yearID ASC


    
