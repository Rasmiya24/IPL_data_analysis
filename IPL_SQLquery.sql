CREATE TABLE matches(
   id              INTEGER  NOT NULL PRIMARY KEY,
	season          INTEGER  NOT NULL,
	city            VARCHAR(14) NOT NULL,
	date            DATE  NOT NULL,
	team1           VARCHAR(27) NOT NULL,
	team2           VARCHAR(27) NOT NULL,
	toss_winner     VARCHAR(27) NOT NULL,
	toss_decision   VARCHAR(5) NOT NULL,
	result          VARCHAR(6) NOT NULL,
	dl_applied      BIT  NOT NULL,
	winner          VARCHAR(27) NOT NULL,
	win_by_runs     INTEGER  NOT NULL,
	win_by_wickets  INTEGER  NOT NULL,
	player_of_match VARCHAR(17) NOT NULL,
	venue           VARCHAR(52) NOT NULL,
	umpire1         VARCHAR(21),
	umpire2         VARCHAR(14),
	umpire3         VARCHAR(30)
);

CREATE TABLE deliveries(
   match_id         INTEGER  NOT NULL,
	inning          INTEGER  NOT NULL, 
	batting_team    VARCHAR(27) NOT NULL, 
	bowling_team    VARCHAR(27) NOT NULL, 
	over_no         INTEGER  NOT NULL, 
	ball            INTEGER  NOT NULL, 
	batsman          VARCHAR(17) NOT NULL,
	non_striker      VARCHAR(17) NOT NULL,
	bowler           VARCHAR(17) NOT NULL,
	is_super_over_no    BIT  NOT NULL,
	wide_runs        INTEGER  NOT NULL,
	bye_runs         INTEGER  NOT NULL,
	legbye_runs      INTEGER  NOT NULL,
	noball_runs      INTEGER  NOT NULL,
	penalty_runs     INTEGER  NOT NULL,
	batsman_runs     INTEGER  NOT NULL,
	extra_runs       INTEGER  NOT NULL,
	total_runs       INTEGER  NOT NULL,
	player_dismissed VARCHAR(17),
	dismissal_kind   VARCHAR(17),
	fielder          VARCHAR(20)
);

-- WHAT ARE THE TOP 5 PLAYERS WITH THE MOST PLAYER OF THE MATCH AWARDS?
	SELECT player_of_match, COUNT(*) AS awards_count
	FROM matches 
	GROUP BY player_of_match
	ORDER BY awards_count DESC
	LIMIT 5;

-- HOW MANY MATCHES WERE WON BY EACH TEAM IN EACH SEASON?
	SELECT season, winner AS team, COUNT (*) AS matches_won
	FROM matches
	GROUP BY season, winner;

-- WHAT IS THE AVERAGE STRIKE RATE OF BATSMEN IN THE IPL DATASET?
	SELECT AVG(strike_rate) AS average_strike_rate
	FROM (
		SELECT batsman, (SUM(total_runs)/COUNT(ball))*100 AS strike_rate
		FROM deliveries
		GROUP BY batsman
)

-- WHAT IS THE NUMBER OF MATCHES WON BY EACH TEAM BATTING FIRST VERSUS BATTING SECOND?
	 SELECT batting_first, COUNT(*) AS matches_won
	 FROM(
		SELECT CASE WHEN win_by_runs > 0 THEN team1 ELSE team2 END AS batting_first
		FROM matches
		WHERE winner <> 'Tie') 
		AS batting_first_teams
		GROUP BY batting_first;

-- WHICH BATSMAN HAS THE HIGHEST STRIKE RATE (MINIMUM 200 RUNS SCORED)?
	SELECT batsman, (SUM(batsman_runs) * 100/COUNT(*)) AS strike_rate
	FROM deliveries
	GROUP BY batsman
	HAVING SUM(batsman_runs) >= 200
	ORDER BY strike_rate DESC
	LIMIT 1;

-- HOW MANY TIMES HAS EACH BATSMAN BEEN DISMISSED BY THE BOWLER 'MALINGA'?
	SELECT batsman, COUNT(*) AS total_dismissals
	FROM deliveries 
	WHERE player_dismissed is NOT NULL AND bowler='SL Malinga'
	GROUP BY batsman;

-- WHAT IS THE AVERAGE PERCENTAGE OF BOUNDARIES (FOURS AND SIXES COMBINED) HIT BY EACH BATSMAN?
	SELECT batsman, AVG(CASE WHEN batsman_runs = 4 OR batsman_runs = 6 THEN 1 ELSE 0 END) * 100 AS average_boundaries
	FROM deliveries
	GROUP BY batsman;

-- WHAT IS THE AVERAGE NUMBER OF BOUNDARIES HIT BY EACH TEAM IN EACH SEASON?
	SELECT season, batting_team, AVG(fours + sixes) AS average_boundaries
	FROM (
  	SELECT season, match_id, batting_team,
    SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) AS fours,
    SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) AS sixes
  	FROM deliveries, matches 
  	WHERE deliveries.match_id = matches.id
  	GROUP BY season, match_id, batting_team) AS team_boundaries
	GROUP BY season, batting_team;

-- WHAT IS THE HIGHEST PARTNERSHIP (RUNS) FOR EACH TEAM IN EACH SEASON?
	SELECT season, batting_team, MAX(total_runs) AS highest_partnership
	FROM(
		SELECT season,batting_team,partnership,sum(total_runs) AS total_runs
	FROM( SELECT season,match_id,batting_team,over_no,
	SUM (batsman_runs) AS partnership, SUM(batsman_runs)+ SUM (extra_runs) AS total_runs
	FROM deliveries,matches 
	WHERE deliveries.match_id=matches.id
	GROUP BY season,match_id,batting_team,over_no) AS team_scores
	GROUP BY season,batting_team,partnership) AS highest_partnership
	GROUP BY season,batting_team; 

-- HOW MANY EXTRAS (WIDES & NO-BALLS) WERE BOWLED BY EACH TEAM IN EACH MATCH?
	SELECT m.id AS match_no,d.bowling_team,
	SUM (d.extra_runs) AS extras
	FROM matches AS m
	JOIN deliveries AS d ON d.match_id=m.id
	WHERE extra_runs>0
	GROUP BY m.id,d.bowling_team;

-- WHICH BOWLER HAS THE BEST BOWLING FIGURES (MOST WICKETS TAKEN) IN A SINGLE MATCH?
	SELECT m.id AS match_no, d.bowler, COUNT(*) AS wickets_taken
	FROM matches AS m
	JOIN deliveries AS d ON d.match_id=m.id
	WHERE d.player_dismissed is NOT NULL
	GROUP BY m.id,d.bowler
	ORDER BY wickets_taken DESC
	LIMIT 1;

-- HOW MANY MATCHES RESULTED IN A WIN FOR EACH TEAM IN EACH CITY?
	SELECT m.city, CASE WHEN m.team1=m.winner THEN m.team1
	WHEN m.team2=m.winner THEN m.team2
	ELSE 'draw'
	END AS winning_team,
	COUNT(*) AS wins
	FROM matches AS m
	JOIN deliveries AS d ON d.match_id=m.id
	WHERE m.result!='Tie'
	GROUP BY m.city,winning_team;

-- HOW MANY TIMES DID EACH TEAM WIN THE TOSS IN EACH SEASON?
	SELECT season,toss_winner, COUNT(*) AS toss_wins
	FROM matches 
	GROUP BY season,toss_winner;

-- HOW MANY MATCHES DID EACH PLAYER WIN THE "PLAYER OF THE MATCH" AWARD?
	SELECT player_of_match, COUNT(*) AS total_wins
	FROM matches 
	WHERE player_of_match is NOT NULL
	GROUP BY player_of_match
	ORDER BY total_wins DESC;

-- WHAT IS THE AVERAGE NUMBER OF RUNS SCORED IN EACH OVER OF THE INNINGS IN EACH MATCH?
	SELECT m.id, d.inning, d.over_no,
	AVG(d.total_runs) AS average_runs_per_over
	FROM matches AS m
	JOIN deliveries AS d ON d.match_id=m.id
	GROUP BY m.id,d.inning,d.over_no;

-- WHICH TEAM HAS THE HIGHEST TOTAL SCORE IN A SINGLE MATCH?
	SELECT m.season, m.id AS match_no, d.batting_team,
	SUM(d.total_runs) AS total_score
	FROM matches AS m
	JOIN deliveries AS d ON d.match_id=m.id
	GROUP BY m.season, m.id, d.batting_team
	ORDER BY total_score DESC
	LIMIT 1;

-- WHICH BATSMAN HAS SCORED THE MOST RUNS IN A SINGLE MATCH?
	SELECT m.season, m.id AS match_no,d.batsman,
	SUM(d.batsman_runs) AS total_runs
	FROM matches AS m
	JOIN deliveries AS d ON d.match_id=m.id
	GROUP BY m.season, m.id, d.batsman
	ORDER BY total_runs DESC
	LIMIT 1;