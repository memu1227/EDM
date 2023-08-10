CREATE VIEW mm2836_Player_Summary AS
WITH BattingSummary AS (
    SELECT
        playerID,
        COUNT(DISTINCT yearID) as num_years,
        COUNT(DISTINCT teamID) as num_teams,
        SUM(HR) as runs,
        CONVERT(DECIMAL(5, 4), ISNULL(SUM(H * 1.0) / NULLIF(SUM(AB), 0), 0)) as career_ba,
        MAX(yearID) as last_year_played
    FROM Batting
    GROUP BY playerID
),
SalarySummary AS (
    SELECT 
        playerID,
        SUM(salary) AS tot_sal,
        AVG(salary) AS avg_sal,
        MIN(salary) AS min_salary,
        MAX(salary) AS max_salary,
        ((MAX(salary) - MIN(salary)) / NULLIF(MIN(salary), 0)) AS perct_incr
    FROM Salaries
    GROUP BY playerID
),
PitchingSummary AS (
    SELECT
        playerID,
        SUM(W) AS tot_wins,
        SUM(SO) AS tot_so,
        (SUM(SO) + SUM(BB)) / NULLIF((SUM(IPouts / 3)), 0) AS career_pfr
    FROM Pitching
    GROUP BY playerID
),
FieldingSummary AS (
    SELECT 
        playerID,
        SUM(G) AS tot_games,
        SUM(CONVERT(INT, GS)) AS tot_games_started
    FROM Fielding
    GROUP BY playerID
),
AwardsPlayersSummary AS (
    SELECT
        ap.playerID,
        COUNT(DISTINCT ap.awardID) + COUNT(DISTINCT asp.awardID) AS tot_player_awds
    FROM AwardsPlayers ap 
    JOIN AwardsSharePlayers asp ON ap.playerID = asp.playerID AND ap.yearID = asp.yearID AND ap.lgID = asp.lgID
    GROUP BY ap.playerID
),
AwardsManagersSummary AS (
    SELECT
        am.playerID,
        COUNT(DISTINCT am.awardID) + COUNT(DISTINCT asm.awardID) AS tot_manager_awds
    FROM AwardsManagers am
    JOIN AwardsShareManagers asm ON am.playerID = asm.playerID AND am.yearID = asm.yearID AND am.lgID = asm.lgID
    GROUP BY am.playerID
),
HallofFameSummary AS (
    SELECT 
        playerID,
        MAX(CASE WHEN inducted = 'Y' THEN yearID ELSE NULL END) AS year_inducted,
        COUNT(CASE WHEN inducted = 'N' THEN yearID END) AS nominated
    FROM HallOfFame
    GROUP BY playerID
)
SELECT 
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast) AS Full_Name,
    SUM(p.Total_401K) AS Total_401K,
    B.num_years AS num_years,
    B.num_teams AS num_teams,
    B.runs AS runs,
    S.tot_sal AS total_salary,
    B.career_ba AS career_ba,
    S.avg_sal AS average_salary,
    S.min_salary AS min_salary,
    S.max_salary AS max_salary,
    S.perct_incr AS percent_increase,
    B.last_year_played AS last_year_played,
    Pt.tot_wins AS total_wins,
    Pt.tot_so AS total_shutouts,
    Pt.career_pfr AS power_fitness_ratio,
    F.tot_games AS total_games,
    F.tot_games_started AS total_games_started,
    A.tot_player_awds AS total_player_awards,
    M.tot_manager_awds AS total_manager_awards,
    H.year_inducted AS HoF_yr_inducted,
    H.nominated AS num_of_noms
FROM People AS p
LEFT JOIN BattingSummary AS B ON p.playerID = B.playerID
LEFT JOIN SalarySummary AS S ON p.playerID = S.playerID
LEFT JOIN PitchingSummary AS Pt ON p.playerID = Pt.playerID
LEFT JOIN FieldingSummary AS F ON p.playerID = F.playerID
LEFT JOIN AwardsPlayersSummary AS A ON p.playerID = A.playerID
LEFT JOIN AwardsManagersSummary AS M ON p.playerID = M.playerID
LEFT JOIN HallofFameSummary AS H ON p.playerID = H.playerID
GROUP BY 
    P.playerID,
    CONCAT(p.nameGiven, ' (', p.nameFirst, ')', ' ', p.nameLast),
    B.num_years,
    B.num_teams,
    B.runs,
    B.career_ba,
    B.last_year_played,
    S.tot_sal,
    S.avg_sal,
    S.min_salary,
    S.max_salary,
    S.perct_incr,
    Pt.tot_wins,
    Pt.tot_so,
    Pt.career_pfr,
    F.tot_games,
    F.tot_games_started,
    A.tot_player_awds,
    M.tot_manager_awds,
    H.year_inducted,
    H.nominated



