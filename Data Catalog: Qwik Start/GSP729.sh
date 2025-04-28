#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear
# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}"
read REGION

export REGION=$REGION

echo "${CYAN_TEXT}${BOLD_TEXT}Enabling Data Catalog API...${RESET_FORMAT}"
gcloud services enable datacatalog.googleapis.com

echo "${CYAN_TEXT}${BOLD_TEXT}Creating BigQuery dataset 'demo_dataset'...${RESET_FORMAT}"
bq mk demo_dataset

echo "${CYAN_TEXT}${BOLD_TEXT}Copying data from public dataset to your dataset...${RESET_FORMAT}"
bq cp bigquery-public-data:new_york_taxi_trips.tlc_yellow_trips_2018 $DEVSHELL_PROJECT_ID:demo_dataset.trips

echo "${CYAN_TEXT}${BOLD_TEXT}Creating Data Catalog tag template 'demo_tag_template'...${RESET_FORMAT}"
gcloud data-catalog tag-templates create demo_tag_template \
    --location=$REGION \
    --display-name="Demo Tag Template" \
    --field=id=source_of_data_asset,display-name="Source of data asset",type=string,required=TRUE \
    --field=id=number_of_rows_in_data_asset,display-name="Number of rows in data asset",type=double \
    --field=id=has_pii,display-name="Has PII",type=bool \
    --field=id=pii_type,display-name="PII type",type='enum(Email|Social Security Number|None)'

echo "${CYAN_TEXT}${BOLD_TEXT}Looking up the Data Catalog entry for the 'trips' table...${RESET_FORMAT}"
ENTRY_NAME=$(gcloud data-catalog entries lookup '//bigquery.googleapis.com/projects/'$DEVSHELL_PROJECT_ID'/datasets/demo_dataset/tables/trips' --format="value(name)")

echo "${CYAN_TEXT}${BOLD_TEXT}Creating tag.json file...${RESET_FORMAT}"
cat > tag.json << EOF
  {
    "source_of_data_asset": "tlc_yellow_trips_2018",
    "pii_type": "None"
  }
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}Creating Data Catalog tag for the 'trips' table...${RESET_FORMAT}"
gcloud data-catalog tags create --entry=${ENTRY_NAME} \
    --tag-template=demo_tag_template --tag-template-location=$REGION --tag-file=tag.json

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
