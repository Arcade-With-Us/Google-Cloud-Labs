#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}           INITIATING EXECUTION...          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter value for EVENT: ${RESET_FORMAT}" EVENT
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter value for TABLE: ${RESET_FORMAT}" TABLE
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter value for VALUE_X1: ${RESET_FORMAT}" VALUE_X1
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter value for VALUE_Y1: ${RESET_FORMAT}" VALUE_Y1
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter value for VALUE_X2: ${RESET_FORMAT}" VALUE_X2
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter value for VALUE_Y2: ${RESET_FORMAT}" VALUE_Y2
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter value for FUNC_1: ${RESET_FORMAT}" FUNC_1
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter value for FUNC_2: ${RESET_FORMAT}" FUNC_2
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter value for MODEL: ${RESET_FORMAT}" MODEL

echo
export EVENT
export TABLE
export VALUE_X1
export VALUE_Y1
export VALUE_X2
export VALUE_Y2
export FUNC_1
export FUNC_2
export MODEL

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Variables set successfully:${RESET_FORMAT}"
echo "${GREEN_TEXT}EVENT=${EVENT}${RESET_FORMAT}"
echo "${GREEN_TEXT}TABLE=${TABLE}${RESET_FORMAT}"
echo "${GREEN_TEXT}VALUE_X1=${VALUE_X1}${RESET_FORMAT}"
echo "${GREEN_TEXT}VALUE_Y1=${VALUE_Y1}${RESET_FORMAT}"
echo "${GREEN_TEXT}VALUE_X2=${VALUE_X2}${RESET_FORMAT}"
echo "${GREEN_TEXT}VALUE_Y2=${VALUE_Y2}${RESET_FORMAT}"
echo "${GREEN_TEXT}FUNC_1=${FUNC_1}${RESET_FORMAT}"
echo "${GREEN_TEXT}FUNC_2=${FUNC_2}${RESET_FORMAT}"
echo "${GREEN_TEXT}MODEL=${MODEL}${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Loading data into BigQuery tables...${RESET_FORMAT}"
bq load --source_format=NEWLINE_DELIMITED_JSON --autodetect $DEVSHELL_PROJECT_ID:soccer.$EVENT gs://spls/bq-soccer-analytics/events.json
bq load --source_format=CSV --autodetect $DEVSHELL_PROJECT_ID:soccer.$TABLE gs://spls/bq-soccer-analytics/tags2name.csv
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.competitions gs://spls/bq-soccer-analytics/competitions.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.matches gs://spls/bq-soccer-analytics/matches.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.teams gs://spls/bq-soccer-analytics/teams.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.players gs://spls/bq-soccer-analytics/players.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.events gs://spls/bq-soccer-analytics/events.json

echo "${MAGENTA_TEXT}${BOLD_TEXT}Running the first query to analyze penalty success rates...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
playerId,
(Players.firstName || ' ' || Players.lastName) AS playerName,
COUNT(id) AS numPKAtt,
SUM(IF(101 IN UNNEST(tags.id), 1, 0)) AS numPKGoals,
SAFE_DIVIDE(
SUM(IF(101 IN UNNEST(tags.id), 1, 0)),
COUNT(id)
) AS PKSuccessRate
FROM
\`soccer.$EVENT\` Events
LEFT JOIN
\`soccer.players\` Players ON
Events.playerId = Players.wyId
WHERE
eventName = 'Free Kick' AND
subEventName = 'Penalty'
GROUP BY
playerId, playerName
HAVING
numPkAtt >= 5
ORDER BY
PKSuccessRate DESC, numPKAtt DESC
"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Running the second query to analyze shot distances and goal percentages...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
WITH
Shots AS
(
SELECT
*,
/* 101 is known Tag for 'goals' from goals table */
(101 IN UNNEST(tags.id)) AS isGoal,
/* Translate 0-100 (x,y) coordinate-based distances to absolute positions
using "average" field dimensions of 105x68 before combining in 2D dist calc */
SQRT(
POW(
    (100 - positions[ORDINAL(1)].x) * $VALUE_X1/$VALUE_Y1,
    2) +
POW(
    (60 - positions[ORDINAL(1)].y) * $VALUE_X2/$VALUE_Y2,
    2)
 ) AS shotDistance
FROM
\`soccer.$EVENT\`
WHERE
/* Includes both "open play" & free kick shots (including penalties) */
eventName = 'Shot' OR
(eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty'))
)
SELECT
ROUND(shotDistance, 0) AS ShotDistRound0,
COUNT(*) AS numShots,
SUM(IF(isGoal, 1, 0)) AS numGoals,
AVG(IF(isGoal, 1, 0)) AS goalPct
FROM
Shots
WHERE
shotDistance <= 50
GROUP BY
ShotDistRound0
ORDER BY
ShotDistRound0
"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a machine learning model in BigQuery...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE MODEL \`$MODEL\`
OPTIONS(
model_type = 'LOGISTIC_REG',
input_label_cols = ['isGoal']
) AS
SELECT
Events.subEventName AS shotType,
/* 101 is known Tag for 'goals' from goals table */
(101 IN UNNEST(Events.tags.id)) AS isGoal,
\`$FUNC_1\`(Events.positions[ORDINAL(1)].x,
Events.positions[ORDINAL(1)].y) AS shotDistance,
\`$FUNC_2\`(Events.positions[ORDINAL(1)].x,
Events.positions[ORDINAL(1)].y) AS shotAngle
FROM
\`soccer.$EVENT\` Events
LEFT JOIN
\`soccer.matches\` Matches ON
Events.matchId = Matches.wyId
LEFT JOIN
\`soccer.competitions\` Competitions ON
Matches.competitionId = Competitions.wyId
WHERE
/* Filter out World Cup matches for model fitting purposes */
Competitions.name != 'World Cup' AND
/* Includes both "open play" & free kick shots (including penalties) */
(
eventName = 'Shot' OR
(eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty'))
) AND
\`$FUNC_2\`(Events.positions[ORDINAL(1)].x,
Events.positions[ORDINAL(1)].y) IS NOT NULL
;
"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Running predictions using the created model...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
predicted_isGoal_probs[ORDINAL(1)].prob AS predictedGoalProb,
* EXCEPT (predicted_isGoal, predicted_isGoal_probs),
FROM
ML.PREDICT(
MODEL \`$MODEL\`, 
(
 SELECT
     Events.playerId,
     (Players.firstName || ' ' || Players.lastName) AS playerName,
     Teams.name AS teamName,
     CAST(Matches.dateutc AS DATE) AS matchDate,
     Matches.label AS match,
 /* Convert match period and event seconds to minute of match */
     CAST((CASE
         WHEN Events.matchPeriod = '1H' THEN 0
         WHEN Events.matchPeriod = '2H' THEN 45
         WHEN Events.matchPeriod = 'E1' THEN 90
         WHEN Events.matchPeriod = 'E2' THEN 105
         ELSE 120
         END) +
         CEILING(Events.eventSec / 60) AS INT64)
         AS matchMinute,
     Events.subEventName AS shotType,
     /* 101 is known Tag for 'goals' from goals table */
     (101 IN UNNEST(Events.tags.id)) AS isGoal,
 
     \`soccer.$FUNC_1\`(Events.positions[ORDINAL(1)].x,
             Events.positions[ORDINAL(1)].y) AS shotDistance,
     \`soccer.$FUNC_2\`(Events.positions[ORDINAL(1)].x,
             Events.positions[ORDINAL(1)].y) AS shotAngle
 FROM
     \`soccer.$EVENT\` Events
 LEFT JOIN
     \`soccer.matches\` Matches ON
             Events.matchId = Matches.wyId
 LEFT JOIN
     \`soccer.competitions\` Competitions ON
             Matches.competitionId = Competitions.wyId
 LEFT JOIN
     \`soccer.players\` Players ON
             Events.playerId = Players.wyId
 LEFT JOIN
     \`soccer.teams\` Teams ON
             Events.teamId = Teams.wyId
 WHERE
     /* Look only at World Cup matches to apply model */
     Competitions.name = 'World Cup' AND
     /* Includes both "open play" & free kick shots (but not penalties) */
     (
         eventName = 'Shot' OR
         (eventName = 'Free Kick' AND subEventName IN ('Free kick shot'))
     ) AND
     /* Filter only to goals scored */
     (101 IN UNNEST(Events.tags.id))
)
)
ORDER BY
predictedgoalProb
"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}********************************************${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}           NOW FOLLOW VIDEO STEPS          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}********************************************${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT} Open BigQuery Console:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT} https://console.cloud.google.com/bigquery? ${RESET_FORMAT}" 
echo 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
