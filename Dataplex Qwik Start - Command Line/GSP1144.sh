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

# Instruction 1: Setting the Region
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}========================== Setting the Region ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}Enter REGION: ${RESET_FORMAT}"
read -r REGION

export REGION=$REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}Region set to: $REGION${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}========================== Enabling Dataplex API ========================== ${RESET_FORMAT}"

gcloud services enable dataplex.googleapis.com

export PROJECT_ID=$(gcloud config get-value project)
echo
echo "${GREEN_TEXT}${BOLD_TEXT}========================== Project ID fetched : ${PROJECT_ID} ========================== ${RESET_FORMAT}"

gcloud config set compute/region $REGION
echo
echo "${BLUE_TEXT}${BOLD_TEXT}========================== Creating Lake ========================== ${RESET_FORMAT}"
gcloud dataplex lakes create ecommerce \
   --location=$REGION \
   --display-name="Ecommerce" \
   --description="Ecommerce Domain"
echo "${GREEN_TEXT}${BOLD_TEXT}Lake ecommerce has been created successfully.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}========================== Creating Zone ========================== ${RESET_FORMAT}"
gcloud dataplex zones create orders-curated-zone \
    --location=$REGION \
    --lake=ecommerce \
    --display-name="Orders Curated Zone" \
    --resource-location-type=SINGLE_REGION \
    --type=CURATED \
    --discovery-enabled \
    --discovery-schedule="0 * * * *"
echo "${GREEN_TEXT}${BOLD_TEXT}Zone orders-curated-zone has been created successfully.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}========================== Creating BigQuery Dataset ========================== ${RESET_FORMAT}"
bq mk --location=$REGION --dataset orders 
echo "${GREEN_TEXT}${BOLD_TEXT}BigQuery Dataset orders has been created successfully.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}========================== Creating Asset ========================== ${RESET_FORMAT}"
gcloud dataplex assets create orders-curated-dataset \
--location=$REGION \
--lake=ecommerce \
--zone=orders-curated-zone \
--display-name="Orders Curated Dataset" \
--resource-type=BIGQUERY_DATASET \
--resource-name=projects/$PROJECT_ID/datasets/orders \
--discovery-enabled 
echo "${GREEN_TEXT}${BOLD_TEXT}Asset orders-curated-dataset has been created successfully.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}========================== Deleting Asset ========================== ${RESET_FORMAT}"
gcloud dataplex assets delete orders-curated-dataset --location=$REGION --zone=orders-curated-zone --lake=ecommerce --quiet
echo "${GREEN_TEXT}${BOLD_TEXT}Asset orders-curated-dataset has been deleted successfully.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}========================== Deleting Zone ========================== ${RESET_FORMAT}"
gcloud dataplex zones delete orders-curated-zone --location=$REGION --lake=ecommerce --quiet
echo "${GREEN_TEXT}${BOLD_TEXT}Zone orders-curated-zone has been deleted successfully.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}========================== Deleting Lake ========================== ${RESET_FORMAT}"
gcloud dataplex lakes delete ecommerce --location=$REGION --quiet
echo "${GREEN_TEXT}${BOLD_TEXT}Lake ecommerce has been deleted successfully.${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
