-- 1) Stats for Cali born players 
SELECT 
    p.playerID, 
    p.birthCity, 
    p.birthState,
    b.yearID, 
    b.HR, 
    b.RBI, 
    b.AB, 
    FORMAT(s.salary,'C') as salary,
    CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) AS 'Batting_Avg'
FROM 
    Batting b, 
    People p, 
    Salaries s
WHERE
    p.playerID = b.playerID
    AND p.playerID = s.playerID
    AND b.yearID = s.yearID
    AND b.teamID = s.teamID
    AND b.lgId = s.lgID
    AND p.birthState = 'CA'
    AND b.AB > 0
ORDER BY    
    p.nameFirst ASC,
    b.yearID ASC

-- 2) The same thing as above but with Left Joins
SELECT 
    p.playerID, 
    p.birthCity, 
    p.birthState,
    b.yearID, 
    b.HR, 
    b.RBI, 
    b.AB, 
    FORMAT(s.salary,'C') as salary,
    CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) AS 'Batting_Avg'
FROM People p
LEFT JOIN Batting b on p.playerID = b.playerID
LEFT JOIN Salaries s on b.playerID = s.playerID AND b.yearID = s.yearID AND b.teamID = s.teamID AND b.lgID = s.lgID
WHERE 
    p.birthState = 'CA'
    AND b.AB > 0
ORDER BY 
    p.nameFirst ASC,
    b.yearID ASC

-- 3) Ivy League Stats
SELECT 
    p.playerID,
    p.nameFirst,
    p.nameLast,
    cp.schoolID,
    cp.yearID,
    b.HR,
    b.AB,
    CONVERT(DECIMAL(5, 4), ISNULL(b.H * 1.0 / NULLIF(b.AB, 0), 0)) AS 'Batting_Avg'
    FROM 
        People p,
        CollegePlaying cp,
        Batting b 
    WHERE
        schoolID IN ('upenn','brown','columbia','dartmouth','cornell','harvard','yale','princeton')
        AND p.playerID = b.playerID
        AND b.playerID = cp.playerID
    ORDER BY
        b.HR DESC,
        b.yearID DESC

-- 4) longevity of career
SELECT playerID, teamID
FROM Batting
WHERE yearID = '2016'
INTERSECT
SELECT playerID, teamID
FROM Batting
WHERE yearID = '2021'

-- 5) played for different teams
SELECT playerID, teamID
FROM Batting
WHERE yearID = '2016'
EXCEPT
SELECT playerID, teamID
FROM Batting
WHERE yearID = '2021'

-- 6) average and total salary for player
SELECT 
    playerID,
    FORMAT(AVG(salary), 'C') AS Average_Salary,
    FORMAT(SUM(salary), 'C') AS Total_Salary
FROM Salaries
GROUP BY playerID
ORDER BY SUM (salary) DESC

-- 7) modifying ivy leagues
SELECT 
    p.playerID,
    p.nameFirst,
    p.nameLast,
    cp.schoolID,
    SUM (b.HR) as Total_HR,
    FORMAT(SUM(salary), 'C') AS Total_Salary
FROM People p
LEFT JOIN Batting b ON p.playerID = b.playerID
LEFT JOIN CollegePlaying cp ON p.playerID = cp.playerID
LEFT JOIN Salaries s ON p.playerID = s.playerID AND b.yearID = s.yearID AND b.lgID = s.lgID
WHERE
    cp.schoolID IN ('upenn', 'brown', 'columbia', 'dartmouth', 'cornell', 'harvard', 'yale', 'princeton')
    AND cp.schoolID IS NOT NULL
GROUP BY
    p.playerID,
    p.nameFirst,
    p.nameLast,
    cp.schoolID
ORDER BY Total_HR DESC

-- 8) > 400 HRS
SELECT
    p.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS Full_Name,
    SUM(b.HR) AS Total_HR,
    (MAX(b.yearID) - MIN(b.yearID)) + 1 AS Years_Played -- +1 to count the last yr 
FROM People p, Batting b
WHERE p.playerID = b.playerID
GROUP BY p.playerID, CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast)
HAVING SUM(b.HR) > 400
ORDER BY Total_HR DESC

-- 9) Projection over 500 HRS
SELECT 
    p.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS Full_Name,
    SUM(b.HR) AS Total_HR,
    (MAX(b.yearID) - MIN(b.yearID)) + 1 AS Years_Played,
    (SUM(b.HR)/((MAX(b.yearID) - MIN(b.yearID)) + 1))*22 AS Projected_HR
FROM People p, Batting b
WHERE 
    p.playerID = b.playerID
GROUP BY p.playerID, CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast)
HAVING 
    SUM(b.HR) BETWEEN 400 AND 499
    AND (SUM(b.HR)/((MAX(b.yearID) - MIN(b.yearID)) + 1))*22 >= 500
ORDER BY SUM(b.HR) DESC

-- 10) Appearances tables 
SELECT
    t.name AS Team_Name,
    a.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS Full_Name  
FROM Appearances a
JOIN People p ON a.playerID = p.playerID
JOIN Teams t ON a.teamID = t.teamID AND a.yearID = t.yearID
WHERE
    a.yearID = 2022
    AND t.teamID IN (
        SELECT teamID
        FROM Teams
        WHERE yearID < 1900
    )
ORDER BY
    Team_Name,
    p.nameLast

-- 11) 
SELECT
    p.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS Full_Name,
    ta.teamID,
    Last_Year,
    FORMAT(Player_Average,'C') AS Player_Average,
    FORMAT(Team_Average,'C') AS Team_Average,
    FORMAT((Player_Average - Team_Average),'C') AS Difference
FROM People p,
    (
        SELECT 
            teamID,
            AVG(salary) as Team_Average
        FROM Salaries 
        GROUP BY teamID

    )ta,
    (
        SELECT 
            teamID,
            playerID,
            AVG(salary) as Player_Average,
            max(yearId) AS Last_Year
        FROM Salaries
        GROUP BY playerID, teamID
    )pa
WHERE 
    ta.teamID = pa.teamID
    AND p.playerID = pa.playerID
ORDER BY 
    Last_Year DESC, 
    Difference DESC, 
    playerID ASC

-- 12) 
GO
WITH TeamAverage AS (
    SELECT 
        teamID,
        AVG(salary) as Team_Average
    FROM Salaries 
    GROUP BY teamID
),
PlayerAverage AS (
    SELECT 
        teamID,
        playerID,
        AVG(salary) as Player_Average,
        MAX(yearId) AS Last_Year
    FROM Salaries
    GROUP BY playerID, teamID
)
SELECT
    p.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS Full_Name,
    ta.teamID,
    Last_Year,
    FORMAT(Player_Average, 'C') AS Player_Average,
    FORMAT(Team_Average, 'C') AS Team_Average,
    FORMAT((Player_Average - Team_Average), 'C') AS Difference
FROM 
    People p
    JOIN PlayerAverage pa ON p.playerID = pa.playerID
    JOIN TeamAverage ta ON ta.teamID = pa.teamID
ORDER BY 
    Last_Year DESC, 
    Difference DESC, 
    playerID ASC
GO

--13) 
SELECT
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS Full_Name,
    (
        SELECT COUNT(DISTINCT teamID)
        FROM Batting
        WHERE playerID = p.playerID
    ) AS Total_Teams,
    (
        SELECT FORMAT(AVG(salary),'C') as Average_Salary
        FROM Salaries
        WHERE playerID = p.playerID
    ) AS Avg_Salary,
    (
        SELECT CONVERT(DECIMAL(10, 2), ISNULL(AVG(ERA), 0))
        FROM Pitching
        WHERE playerID = p.playerID
    ) AS Avg_ERA,
    (
        SELECT SUM(E)
        FROM Fielding
        WHERE playerID = p.playerID
    ) AS Total_Errors,
    (
        SELECT CONVERT(DECIMAL(10, 4), ISNULL(SUM(H * 1.0) / NULLIF(SUM(AB), 0), 0))
        FROM Batting
        WHERE playerID = p.playerID
    ) AS Avg_BA
FROM
    People p

-- 14) Updating Salaries
UPDATE Salaries
SET [401K_Player_Contributions] = salary * 0.06

SELECT 
    playerID, 
    salary, 
    [401K_Player_Contributions]
FROM Salaries
ORDER BY playerID

-- 15)
UPDATE Salaries
SET [401K_Team_Contributions] = 
    CASE
        WHEN salary < 1000000 THEN salary * 0.05
        ELSE salary * 0.025
    END

SELECT 
    playerID, 
    salary, 
    [401K_Player_Contributions] as [401K_Contributions],
    [401K_Team_Contributions]
FROM Salaries
ORDER BY playerID

--16) 
UPDATE People
SET Total_HR = (
    SELECT SUM(HR)
    FROM Batting
    WHERE Batting.playerID = PEOPLE.playerID
),
High_BA = (
    SELECT MAX(CONVERT(DECIMAL(5, 4), ISNULL(H * 1.0 / NULLIF(AB, 0), 0)))
    FROM Batting
    WHERE Batting.playerID = PEOPLE.playerID
)
WHERE EXISTS (
    SELECT playerID
    FROM Batting
    WHERE 
        Batting.playerID = PEOPLE.playerID
        AND AB > 0
)

SELECT 
    playerID, 
    Total_HR, 
    FORMAT(High_BA, '0.0000') AS Career_BA
FROM PEOPLE
ORDER BY playerID

-- 17) 
UPDATE PEOPLE
SET Total_401K = (
    SELECT SUM([401K_Player_Contributions] + [401K_Team_Contributions]) 
    FROM Salaries
    WHERE Salaries.playerID = PEOPLE.playerID
)
WHERE EXISTS (
    SELECT playerID
    FROM Salaries
    WHERE Salaries.playerID = PEOPLE.playerID
)
SELECT 
    playerID,
    CONCAT(nameGiven, ' (', nameFirst, ')', ' ', nameLast) AS Full_Name,
    Total_401K as [401K_Total]
FROM People
WHERE Total_401K > 0
ORDER BY playerID
    
-- 18) Extra Credit
SELECT
    t.teamID,
    t.name,
    FORMAT(loss.Total_Loss, 'C') AS Total_Team_Loss,
    FORMAT(loss.Avg_Loss, 'C') AS CV_per_Game$_Loss,
    FLOOR(loss.Total_Loss / NULLIF(loss.Avg_Loss, 0)) AS Games_To_Recover,
    loss.PreCovid_Avg_Attendance AS PreCovid_Avg_Attendance,
    loss.Covid_Avg_Attendance AS Covid_Avg_Attendance,
    loss.Covid_Avg_Attendance - loss.PreCovid_Avg_Attendance as Drop_In_Attendance,
    FORMAT(loss.Covid_Avg_Attendance/loss.PreCovid_Avg_Attendance,'P') as Percentage_Drop
    
FROM Teams t
JOIN (
    SELECT
        t.teamID,
        (CONVERT(NUMERIC, ca.Covid_Attendance) - CONVERT(NUMERIC, pca.PreCovid_Attendance)) * 256.41 AS Total_Loss,
        ((CONVERT(NUMERIC, ca.Covid_Attendance) - CONVERT(NUMERIC, pca.PreCovid_Attendance)) * 256.41) / NULLIF(SUM(CONVERT(NUMERIC, t.Ghome)), 0) AS Avg_Loss,
        (CONVERT(NUMERIC, pca.PreCovid_Attendance)) / NULLIF(pca.PreCovid_HGames, 0) AS PreCovid_Avg_Attendance,
        (CONVERT(NUMERIC, ca.Covid_Attendance)) / NULLIF(SUM(CONVERT(NUMERIC, t.Ghome)), 0) AS Covid_Avg_Attendance
    FROM Teams t
    JOIN (
        SELECT
            teamID,
            attendance AS PreCovid_Attendance,
            CONVERT(NUMERIC, GHome) AS PreCovid_HGames
        FROM Teams
        WHERE yearID = '2019'
        GROUP BY teamID, attendance, Ghome
    ) AS pca ON t.teamID = pca.teamID
    JOIN (
        SELECT
            teamID,
            attendance AS Covid_Attendance,
            CONVERT(NUMERIC, GHome) AS Covid_HGames
        FROM Teams
        WHERE yearID IN ('2020', '2021')
        GROUP BY teamID, attendance, GHome
    ) AS ca ON t.teamID = ca.teamID
    WHERE CONVERT(NUMERIC, ca.Covid_Attendance) > 0
    GROUP BY t.teamID, ca.Covid_Attendance, pca.PreCovid_Attendance, pca.PreCovid_HGames
) AS loss ON t.teamID = loss.teamID















