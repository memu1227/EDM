select * from mm2836_Player_Summary 

SELECT
    COUNT(*) AS row_count,
    AVG(num_years) AS avg_years_played,
    AVG(average_salary) AS avg_salary,
    AVG(career_ba) AS avg_cba,
    AVG(power_fitness_ratio) AS avg_career_pfr
FROM mm2836_Player_Summary
WHERE RIGHT(Full_Name, CHARINDEX(' ', REVERSE(Full_Name)) - 1) LIKE 'A%'

