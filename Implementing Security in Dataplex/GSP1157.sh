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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Detecting GCP region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Could not automatically detect GCP region.${RESET_FORMAT}"
    read -p "${CYAN_TEXT}${BOLD_TEXT}Please enter the GCP region: ${RESET_FORMAT}" REGION
    export REGION
fi

echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Region set to: $REGION${RESET_FORMAT}"


echo
echo "${GREEN_TEXT}${BOLD_TEXT}⚙️  Enabling the Dataplex API. This is a necessary step for using Dataplex services.${RESET_FORMAT}"
gcloud services enable dataplex.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📚 Enabling the Data Catalog API. This service helps in discovering and managing data assets.${RESET_FORMAT}"
gcloud services enable datacatalog.googleapis.com

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🏞️  The following command will create a new Dataplex lake named 'customer-info-lake' in the region: ${REGION}.${RESET_FORMAT}"
gcloud dataplex lakes create customer-info-lake \
    --location=$REGION \
    --display-name="Customer Info Lake"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🧱 Creating a RAW zone named 'customer-raw-zone' within the 'customer-info-lake'. This zone is for unprocessed data.${RESET_FORMAT}"
gcloud alpha dataplex zones create customer-raw-zone \
                        --location=$REGION --lake=customer-info-lake \
                        --resource-location-type=SINGLE_REGION --type=RAW \
                        --display-name="Customer Raw Zone"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🧺 This step involves creating a Dataplex asset named 'customer-online-sessions'. It links a storage bucket to the 'customer-raw-zone'.${RESET_FORMAT}"
gcloud dataplex assets create customer-online-sessions --location=$REGION \
                        --lake=customer-info-lake --zone=customer-raw-zone \
                        --resource-type=STORAGE_BUCKET \
                        --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-bucket \
                        --display-name="Customer Online Sessions"


echo
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}OPEN THIS LINK: ${RESET_FORMAT}""${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/dataplex/secure?resourceName=projects%2F$DEVSHELL_PROJECT_ID%2Flocations%2F$REGION%2Flakes%2Fcustomer-info-lake&project=$DEVSHELL_PROJECT_ID""${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
