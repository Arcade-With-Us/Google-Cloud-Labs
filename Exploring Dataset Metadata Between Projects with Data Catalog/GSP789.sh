#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
DIM_TEXT=$'\033[2m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

read -p "$(echo -e "${CYAN_TEXT}${BOLD_TEXT}🔑 Enter NYC Bike Share PROJECT ID: ${RESET_FORMAT}")" PROJECT_ID_1
read -p "$(echo -e "${CYAN_TEXT}${BOLD_TEXT}🔑 Enter NYC Motor Vehicle Collisions PROJECT ID: ${RESET_FORMAT}")" PROJECT_ID_2
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Region not found in your project metadata!${RESET_FORMAT}"
  read -p "$(echo -e "${CYAN_TEXT}${BOLD_TEXT}🌎 Please enter your preferred REGION: ${RESET_FORMAT}")" REGION
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔍 Fetching top collision factors from NYC Motor Vehicle Collisions dataset...${RESET_FORMAT}"
echo "${DIM_TEXT}This may take a few moments.${RESET_FORMAT}"
echo

bq query --use_legacy_sql=false --project_id=$PROJECT_ID_2 \
"
SELECT
  contributing_factor_vehicle_1 AS collision_factor,
  COUNT(*) AS num_collisions
FROM
  \`new_york_mv_collisions.nypd_mv_collisions\`
WHERE
  contributing_factor_vehicle_1 != 'Unspecified'
  AND contributing_factor_vehicle_1 != ''
GROUP BY
  collision_factor
ORDER BY
  num_collisions DESC
LIMIT 10;
"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚴‍♂️ Analyzing top bike trip routes by gender from NYC Bike Share dataset...${RESET_FORMAT}"
echo "${DIM_TEXT}Running BigQuery analysis for unknown, female, and male riders.${RESET_FORMAT}"
echo

bq query --use_legacy_sql=false --project_id=$PROJECT_ID_1 \
"
WITH unknown AS (
  SELECT
    gender,
    CONCAT(start_station_name, ' to ', end_station_name) AS route,
    COUNT(*) AS num_trips
  FROM
    \`new_york_citibike.citibike_trips\`
  WHERE gender = 'unknown'
  GROUP BY
    gender,
    start_station_name,
    end_station_name
  ORDER BY
    num_trips DESC
  LIMIT 5
)

, female AS (
  SELECT
    gender,
    CONCAT(start_station_name, ' to ', end_station_name) AS route,
    COUNT(*) AS num_trips
  FROM
    \`new_york_citibike.citibike_trips\`
  WHERE gender = 'female'
  GROUP BY
    gender,
    start_station_name,
    end_station_name
  ORDER BY
    num_trips DESC
  LIMIT 5
)

, male AS (
  SELECT
    gender,
    CONCAT(start_station_name, ' to ', end_station_name) AS route,
    COUNT(*) AS num_trips
  FROM
    \`bigquery-public-data.new_york_citibike.citibike_trips\`
  WHERE gender = 'male'
  GROUP BY
    gender,
    start_station_name,
    end_station_name
  ORDER BY
    num_trips DESC
  LIMIT 5
)

SELECT * FROM unknown
UNION ALL
SELECT * FROM female
UNION ALL
SELECT * FROM male;
"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🏷️  Creating a Data Catalog Tag Template for New York Datasets...${RESET_FORMAT}"
echo "${DIM_TEXT}This will help you organize and annotate your datasets with useful metadata.${RESET_FORMAT}"
echo

gcloud data-catalog tag-templates create new_york_datasets --display-name="New York Datasets" --project=$PROJECT_ID_1 --location=$REGION --field=id=contains_pii,display-name="Contains PII",type='enum(None|Birth date|Gender|Geo location)' --field=id=data_owner_team,display-name="Data Owner Team",type='enum(Marketing|Data Science|Sales|Engineering)',required=TRUE

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
