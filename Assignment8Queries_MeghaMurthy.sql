SELECT
    playerid,
    nameFirst + ' ( ' + nameGiven + ' ) ' + nameLast AS Full_Name,
    dbo.CareerOBP(playerId) AS careerOBP
FROM
    People 

SELECT
    t.teamID,
    AVG(dbo.CareerOBP(p.playerID)) AS avgCareerOBP
FROM Teams t
LEFT JOIN Batting b ON t.teamID = b.teamID
LEFT JOIN People p ON b.playerID = p.playerID
GROUP BY
    t.teamID
ORDER BY
    avgCareerOBP DESC