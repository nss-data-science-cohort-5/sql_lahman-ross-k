		-- NSS DS5 - SQL_LAHMAN - ROSS KIMBERLIN --

/*
	## Lahman Baseball Database Exercise
- this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
- you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)

	1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total salary they earned in the major leagues.  Sort this list in descending order by the total salary earned.  Which Vanderbilt player earned the most money in the majors?
	
	A - It looks like David Price at $81,851,296.
*/

-- THIS MULTIPLIES THE CORRECT ANSWER BY 3
--		BECAUSE OF THE YEARS IN THE collegeplaying TABLE - USE SUB-QUERY INSTEAD
SELECT DISTINCT -- p.playerid,
	p.namefirst || ' ' || p.namelast AS playername,
--	cp.schoolid,
--	s.lgid,
	SUM(s.salary) AS total_salary
FROM people p
	INNER JOIN collegeplaying cp
		ON p.playerid = cp.playerid
	INNER JOIN salaries s
		ON p.playerid = s.playerid
WHERE cp.schoolid = 'vandy'
--	AND lgid = 'ML'	??
GROUP BY 1
ORDER BY 2 DESC;


	-- CONNOR MERRY HAD:
	SELECT DISTINCT playerid,
		sum(salary)
	FROM salaries
	WHERE playerid = 'priceda01'
	GROUP BY playerid


	-- VAMSI HAD:
	SELECT
		name,
		SUM(salary) AS salary
	FROM
		(
			SELECT 
				DISTINCT namefirst || ' ' || namelast AS name,
				salary::numeric::money
			FROM people
				JOIN salaries
					USING(playerid)
				JOIN collegeplaying
					USING(playerid)
			WHERE schoolid = 'vandy' 
			 	AND salary IS NOT null
			ORDER BY salary DESC
		) AS sub
	GROUP BY name
	ORDER BY salary DESC;


-- JOSHUA HAD:
SELECT 
	namefirst, 
	namelast, 
	SUM(salary)::numeric::money AS total_salary
FROM people
	INNER JOIN salaries
		USING (playerid)
WHERE playerid IN
(
	SELECT playerid
	FROM collegeplaying
	WHERE schoolid = 'vandy'
)
GROUP BY namefirst, namelast
ORDER BY total_salary DESC;


-- BRYAN HAD:
with vandy_players as 
(
  select playerid 
	from collegeplaying
    	inner join schools s 
			on collegeplaying.schoolid = s.schoolid
    where schoolname = 'Vanderbilt University'
)
select distinct p.playerid, 
	namefirst, 
	namelast, 
	sum(salary) over(partition by p.playerid) total_salary
from people p
	inner join salaries s2 
		on p.playerid = s2.playerid
where p.playerid in 
(
	select * 
	from vandy_players
)
order by total_salary desc;


	-- JAMES GILBERT HAD:
	SELECT PEOPLE.NAMEFIRST || ' ' || PEOPLE.NAMELAST AS PLAYER_NAME,
		SUM(SALARIES.SALARY) AS TOTAL_SALARY,
		SCHOOLS.SCHOOLNAME
	FROM PEOPLE
		INNER JOIN SALARIES 
			ON SALARIES.PLAYERID = PEOPLE.PLAYERID
		INNER JOIN COLLEGEPLAYING 
			ON COLLEGEPLAYING.PLAYERID = PEOPLE.PLAYERID
		INNER JOIN SCHOOLS 
			ON SCHOOLS.SCHOOLID = COLLEGEPLAYING.SCHOOLID
	WHERE SCHOOLNAME = 'Vanderbilt University'
	GROUP BY PEOPLE.NAMEFIRST, 
		PEOPLE.NAMELAST, 
		SCHOOLS.SCHOOLNAME
	ORDER BY TOTAL_SALARY DESC;


/*
	2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
*/

;WITH cteOutfield AS
(
	SELECT 'Outfield' AS position_group, 
		SUM(po) AS putouts
	FROM fielding
	WHERE pos = 'OF'
		AND yearid = 2016
),
cteInfield AS
(
	SELECT 'Infield' AS position_group, 
		SUM(po) AS putouts
	FROM fielding
	WHERE pos IN
	('SS', '1B', '2B', '3B')
		AND yearid = 2016	
),
cteBattery AS 
(
	SELECT 'Battery' AS position_group, 
		SUM(po) AS putouts
	FROM fielding
	WHERE pos IN
	('P', 'C')
		AND yearid = 2016	
)
SELECT *
FROM cteOutfield
UNION
SELECT *
FROM cteInfield
UNION
SELECT *
FROM cteBattery
ORDER BY putouts DESC;


	-- JACOB PARKS HAD:
	SELECT 
		CASE WHEN pos = 'OF' THEN 'Outfield'
			WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		ELSE 'Battery' END AS position_group,
		SUM(po) AS putouts
	FROM fielding
	WHERE yearid = 2016
	GROUP BY position_group
	ORDER BY putouts DESC ;


/*
	3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)
*/

	-- TO DO - 
	WITH cteDecade AS
	(
		SELECT *
		FROM generate_series('1920-01-01'::date, '2020-01-01'::date, '1 decade'::interval)
	)
--	,cteYear AS
--	(
--		EXTRACT(YEAR FROM cteDecade)
--	)
	SELECT 
		(SELECT generate_series FROM cteDecade), 
		AVG(hr) AS homeruns, 
		AVG(so) AS strikeouts
	FROM batting b
	--	INNER JOIN cteDecade cd
	--		ON 
--	GROUP BY cd.generate_series



	-- JOSHUA HAD:
	WITH so_hr_decades AS 
	(
		SELECT 
			yearid,
			teamid,
			g,
			FLOOR(yearid/10)*10 AS decade,
			so,
			hr
		FROM teams
	)
	SELECT
		decade,
		ROUND(SUM(so)*2.0/(SUM(g)), 2) AS so_per_game,
		ROUND(SUM(hr)*2.0/(SUM(g)), 2) AS hr_per_game
	FROM so_hr_decades
	GROUP BY decade
	ORDER BY decade;
	
	
	
	-- HABEEB HAD:
	SELECT TRUNC(YEARID, -1) AS DECADE,		-- SNEAKY!
		ROUND(SUM(SO) * 2.0 / SUM(G), 2) AS STRIKEOUTS_PER_GAME,
		ROUND(SUM(HR) * 2.0 / SUM(G), 2) AS HOMERUNS_PER_GAME
	FROM TEAMS
	WHERE YEARID >= 1920
	GROUP BY DECADE
	ORDER BY DECADE;



	-- ALEX ZHANG HAD:
	WITH bins AS
	(
		SELECT generate_series(1920,2019, 10) AS lower,
			generate_series(1929, 2019, 10) AS upper
	),	   
	strikeouts AS
	(
		SELECT yearid,
			SUM(so)/SUM(g)::numeric AS strikeouts_per_game
		FROM teams
		WHERE yearid >= 1920
		GROUP BY 1
		ORDER BY 1 desc
	)
	SELECT 
		lower,
		upper, 
		ROUND(AVG(strikeouts_per_game), 2) AS strikeouts_per_game
	FROM bins 
	LEFT JOIN strikeouts
		ON strikeouts.yearid >= lower
		AND strikeouts.yearid <= upper
	GROUP BY lower, upper
	ORDER BY lower DESC;
	
	
	
	-- BRYAN HAD:
	select round(avg(so / g), 2) avg_so_per_g,
	       extract(decade from concat(yearid, '-01-01 00:00:00')::timestamp) * 10 as decade
	from teams
	where yearid >= 1920
	group by decade
	order by decade;



	-- JAKE RANDOLPH HAD:
	WITH s3 as
	(
		SELECT  so, 
			yearid, 
			g,
			CASE WHEN YEARID >= 1920 AND YEARID<= 1929 THEN '20s'
				WHEN YEARID >= 1930 AND YEARID<= 1939 THEN '30s'
				WHEN YEARID >=1940 AND YEARID<= 1949 THEN '40s'
				WHEN YEARID >=1950 AND YEARID<= 1959 THEN '50s'
				WHEN YEARID >=1960 AND YEARID<= 1969 THEN '60s'
				WHEN YEARID >=1970 AND YEARID<= 1979 THEN '70s'
				WHEN YEARID >=1980 AND YEARID<= 1989 THEN '80s'
				WHEN YEARID >=1990 AND YEARID<= 1999 THEN '90s'
				WHEN YEARID >=2000 AND YEARID<= 2009 THEN '00s'
				WHEN YEARID >=2010 AND YEARID<= 2019 THEN '10s'
				ELSE 'none of the above'
			END AS DECADES 
		FROM teams
		WHERE YEARID > 1919
	)
	Select SUM(SO)*1.0/ sum(g) as sum_so, 
		decades
	from s3
	GROUP BY decades
	ORDER BY DECADES DESC;


/*
	4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.
	
	A - Chris Owings has a success rate of 91%--impressive.
*/

SELECT DISTINCT p.namefirst || ' ' || p.namelast AS playername,
	SUM(b.sb) AS stolen,
	SUM(b.sb + b.cs) AS attempts,
	100 * SUM(b.sb) / SUM(b.sb + b.cs) AS SB_pct
FROM batting b
	INNER JOIN people p
		ON b.playerid = p.playerid
WHERE yearid = 2016
GROUP BY 1
HAVING SUM(b.sb) >= 20
ORDER BY 2 DESC;


	-- ALEX ZHANG HAD:
	SELECT 
		namefirst||' '||namelast AS name,
		sb, 
		sb+cs AS num_attempts,
		ROUND(sb*100.00/(sb+cs),2) AS sb_pct
	FROM Batting
	LEFT JOIN people
	USING (playerid)
	WHERE yearid = 2016
		AND (sb+cs)>=20
	ORDER BY sb_pct DESC
	LIMIT 1;


/*
	5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? 
	
	A - The largest number of wins for a team that did not win the World Series during those years was 116 (for the Seattle Mariners in 2001).  The smallest number of wins for a team that did win the World Series during those years was 83 (for the St Louis Cardinals in 2006).  This is an astonishing difference.
*/

-- Largest # wins with no WS win
SELECT t.name,
	t.yearid,
	t.W,
	t.WSWin
FROM teams t
WHERE t.WSWin = 'N'
	AND (t.yearid >= 1970
			AND t.yearid <= 2016)
ORDER BY t.W DESC
LIMIT 1;


-- Smallest # wins with WS win
SELECT t.name,
	t.yearid,
	t.W,
	t.WSWin
FROM teams t
WHERE t.WSWin = 'Y'
	AND (t.yearid >= 1970
			AND t.yearid <= 2016)
	AND t.yearid <> 1981	-- STRIKE YEAR
ORDER BY t.W
LIMIT 1;


/*
	Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. 
*/

TO DO 

/*
	How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
	
	A - It happened 11 times from 1970 to 2016, which is roughly 26% of the time.  If we allow for the strikes in 1994 and ____, then this changes the percentage.
*/

WITH cteYearWins AS
(
	SELECT DISTINCT yearid,
		MAX(W) AS maxwins,
		COUNT(*) OVER() AS maxwin_row_cnt
	FROM teams
	WHERE (yearid >= 1970
			AND yearid <= 2016)	
		AND yearid <> 1981	
	GROUP BY yearid
),
cteWSWins AS
(
	SELECT DISTINCT t.yearid,
		t.name,
		t.W,
		t.WSWin,
		cyw.maxwin_row_cnt AS maxwin_rows
	--	, cyw.maxwins
	FROM teams t
		INNER JOIN cteYearWins cyw
			ON t.yearid = cyw.yearid
			AND t.W = cyw.maxwins
	WHERE (t.yearid >= 1970
			AND t.yearid <= 2016)
		AND t.yearid <> 1981
		AND t.WSWin = 'Y'
--	GROUP BY 1, 2, 3, 4
	ORDER BY t.yearid
)
SELECT yearid,
	name,
	W,
	(100 * COUNT(*) OVER() / maxwin_rows) AS pct
FROM cteWSWins;



	-- ALEX ZHANG HAD:
	WITH 
		ws_champion AS 
		(
			SELECT *
			FROM seriespost
			WHERE yearid BETWEEN 1970 AND 2016
			 AND round = 'WS'
		),
		most_wins_per_year AS 
		(
			SELECT yearid, teamid, w
			FROM teams
			INNER JOIN (
				SELECT yearid, MAX(w) w
				FROM teams
				WHERE yearid BETWEEN 1970 AND 2016
				GROUP BY yearid
				ORDER BY 1) AS most_wins_per_year
			USING (yearid, w)
		)
	SELECT 
		COUNT(round) AS most_win_champion,
		ROUND(COUNT(round)*100.00/COUNT(*),2) AS most_win_champion_pct
	FROM most_wins_per_year AS m
	LEFT JOIN ws_champion AS w
	ON m.yearid = w.yearid
		AND m.teamid = w.teamidwinner
	;
	
	
SELECT *
FROM seriespost


SELECT name,
	WSWin
FROM teams	
	
	
/*
	6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
	
	A - Davey Johnson and Jim Leyland are the two managers who have achieved this.
	
	Regarding Davey Johnson, the American League team he was managing when he won the award in 1997 was the Baltimore Orioles.  When he won the award in 2012 in the National League, he was managing the Washington Senators (aka Nationals).
	
	Reagrding Jim Leyland, the American League team he was managing when he won the award in 2006 was the Detroit Tigers.  In the National League, he apparently won the award three different times with the Pittsburgh Pirates (aka Alleghenys), in 1988, 1990, and 1992.
*/

WITH cteAL AS
(
	SELECT -- am.playerid AS managerid,
		DISTINCT p.namefirst || ' ' || p.namelast AS managername,
--		t.teamid,
		t.name
		, am.yearid || ' ' || m.lgid AS award_year_AL
	--	, am.awardid
	--	, m.yearid
	FROM awardsmanagers am	
		INNER JOIN people p
			ON am.playerid = p.playerid
		INNER JOIN managers m	 	-- ALSO JOIN managershalf?
			ON am.playerid = m.playerid
			AND am.yearid = m.yearid
		INNER JOIN teams t
			ON m.teamid = t.teamid
	WHERE am.awardid ILIKE '%TSN%'
		AND am.lgid = 'AL'
),
cteNL AS
(
	SELECT -- am.playerid AS managerid,
		DISTINCT p.namefirst || ' ' || p.namelast AS managername,
--		t.teamid,
		t.name
		, am.yearid || ' ' || m.lgid AS award_year_NL
	--	, am.awardid
	--	, m.yearid
	FROM awardsmanagers am	
		INNER JOIN people p
			ON am.playerid = p.playerid
		INNER JOIN managers m	 	-- ALSO JOIN managershalf?
			ON am.playerid = m.playerid
			AND am.yearid = m.yearid
		INNER JOIN teams t
			ON m.teamid = t.teamid
	WHERE am.awardid ILIKE '%TSN%'
		AND am.lgid = 'NL'
)
SELECT *
FROM cteAL ca
	INNER JOIN cteNL cn
		ON ca.managername = cn.managername
ORDER BY 1;


/*
	7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.
	
	A - By the calculation below, James Shields is the least efficient, with 135 strike-outs for a cool $42,000,000.
*/

SELECT DISTINCT -- p.playerid,
	pl.namefirst || ' ' || pl.namelast AS playername,
--	pi.teamid,
	SUM(pi.GS) AS games_started,
--	pi.yearid,
--	s.yearid,
	SUM(pi.so) AS strikeouts,
	SUM(s.salary) AS total_salary,
	SUM(pi.so) / SUM(s.salary) AS efficiency	-- IS THIS RIGHT?
FROM people pl
	INNER JOIN pitching pi
		ON pl.playerid = pi.playerid
	INNER JOIN salaries s
		ON pl.playerid = s.playerid
WHERE pi.yearid = 2016
	AND s.yearid = 2016
	AND pi.GS >= 10
GROUP BY 1
ORDER BY efficiency;


/*
	8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.
*/

	TO DO

-- GETTING DUPLICATES, e.g. Honus Wagner - WHY?
SELECT DISTINCT -- pl.playerid,
	pl.namefirst || ' ' || pl.namelast AS playername,
	CASE WHEN hof.inducted = 'Y' THEN hof.yearid 			ELSE NULL END AS HOF_year,
	SUM(b.H) AS career_hits
FROM people pl
	INNER JOIN batting b
		ON pl.playerid = b.playerid
	INNER JOIN halloffame hof
		ON pl.playerid = hof.playerid
GROUP BY 1, 2
HAVING SUM(b.H) >= 3000
ORDER BY career_hits DESC;


/*
	9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.
*/

	TO DO - GETTING NO RESULTS -- WHY?

WITH cteMultiTeams AS
(
	SELECT DISTINCT playerid AS id,
		teamid
	--	COUNT(teamid) AS teamcount
	FROM people
		INNER JOIN batting
			USING(playerid)
--	GROUP BY playerid
	ORDER BY id
)
SELECT -- pl.playerid,
	pl.namefirst || ' ' || pl.namelast AS playername,
	t.teamid,
	b.H AS hits
FROM people pl
	INNER JOIN batting b
		ON pl.playerid = b.playerid
	INNER JOIN teams t
		ON b.teamid = t.teamid
-- WHERE b.H >= 1000
--	AND pl.playerid IN
--	(
--		SELECT id
--		FROM cteMultiTeams
--		GROUP BY id
--		HAVING COUNT(*) > 1
--	)
ORDER BY hits DESC;


/*
	10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
*/

	TO DO

-- HIGH RUN YEAR QUERY
SELECT DISTINCT pl.playerid,
	b.yearid,
	MAX(b.HR) AS homeruns
FROM people pl
	INNER JOIN batting b
		ON pl.playerid = b.playerid
GROUP BY 1, 2
ORDER BY 1, 3 DESC;


-- FINAL QUERY
SELECT DISTINCT -- pl.playerid,
	pl.namefirst || ' ' || pl.namelast AS playername,
	b.HR AS homeruns
FROM people pl
	INNER JOIN batting b
		ON pl.playerid = b.playerid
	INNER JOIN teams t
		ON b.teamid = t.teamid
WHERE b.yearid = 2016
--	AND pl.playerid IN
--	(
--		SELECT id
--		FROM cteMultiTeams
--		GROUP BY id
--		HAVING COUNT(*) > 1
--	)
GROUP BY 1, 2
ORDER BY b.HR DESC;


/*
After finishing the above questions, here are some open-ended questions to consider.

**Open-ended questions**

	11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
*/

-- PSQL HAS corr() FN

-- GET SALARY INFO BY YEAR BY TEAM 1st? >= 2000

SELECT DISTINCT t.name AS teamname,
	t.yearid AS teamyear,
	SUM(s.salary) AS total_salary
FROM teams t
	INNER JOIN managers m
		ON t.teamid = m.teamid
		AND t.yearid = m.yearid
	INNER JOIN salaries s
		ON m.teamid = s.teamid
		AND m.yearid = s.yearid
WHERE t.yearid >= 2000
GROUP BY 1
ORDER BY 2 DESC;



/*
	12. In this question, you will explore the connection between number of wins and attendance.

    a. Does there appear to be any correlation between attendance at home games and number of wins?
	
	A - There does.  If we simply correlate the sums of the attendance and W columns in the teams table, we get a correlation of ~ 90.69% if we remove null values and ~ 89.62 if we do not, which seems very high.  
	If we join the teams table to the homegames table, we get ~ 64.68%, which is still a fairly high correlation value.  I am not sure what the difference is between using the two tables without doing a deeper dive.
*/
   
   -- USING team TABLE AND "IS NOT NULL"
   SELECT CORR(team_attendance, team_wins)
   FROM 
   (
	   SELECT DISTINCT name,
			SUM(attendance) AS team_attendance,
			SUM(W) AS team_wins
	   FROM teams
	 --  WHERE attendance IS NOT NULL
	   GROUP BY 1
 --  ORDER BY 1
	) sq;
   
   
   -- WITH homegames AND teams TABLES
   WITH cteHome AS
   (
    SELECT DISTINCT team,
	   SUM(attendance) AS team_attendance
	FROM homegames 
	GROUP BY team
   )
   SELECT CORR(team_attendance, team_wins)
   FROM 
   (
	   SELECT DISTINCT t.name,
			ch.team_attendance,
			SUM(t.W) AS team_wins
	   FROM teams t
			INNER JOIN cteHome ch
			ON t.teamid = ch.team
	   GROUP BY 1, 2
 --  ORDER BY 1
	) sq;
   
   
/* 
	b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
*/



/*
	13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
*/
	
	TO DO - SHOWING ZERO RECORDS

WITH cteLefties AS
(
	SELECT COUNT(DISTINCT playerid) AS lefty_cnt
	FROM people
	WHERE throws = 'L'
),
cteRighties AS
(
	SELECT COUNT(DISTINCT playerid) AS righty_cnt
	FROM people
	WHERE throws = 'R'
),
cteTotalPlayers AS
(
	SELECT COUNT(DISTINCT playerid) AS total_cnt
	FROM people
)
SELECT
	(SELECT lefty_cnt FROM cteLefties) / (SELECT total_cnt FROM cteTotalPlayers) AS Lefty_pct,
	(SELECT righty_cnt FROM cteRighties) / (SELECT total_cnt FROM cteTotalPlayers) AS Righty_pct
	
	
	