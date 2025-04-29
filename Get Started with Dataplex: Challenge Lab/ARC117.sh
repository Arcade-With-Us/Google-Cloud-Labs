#!/bin/bash

# Bright Foreground Colors
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

# Displaying start message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Set the Location ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT} ${BOLD_TEXT} Enter LOCATION: ${RESET_FORMAT}"
read -r LOCATION
echo
echo "${YELLOW_TEXT} ${BOLD_TEXT} You entered: ${LOCATION} ${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Verify Project ID ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}   Ensure that the DEVSHELL_PROJECT_ID environment variable   ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}        is correctly set to your project ID.                  ${RESET_FORMAT}"
echo

export ID=$DEVSHELL_PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Enable Services ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Enabling required services (datacatalog.googleapis.com and dataplex.googleapis.com)... ${RESET_FORMAT}"
echo
gcloud services enable datacatalog.googleapis.com
gcloud services enable dataplex.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Create Dataplex Lake ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}   Creating Dataplex Lake 'customer-engagements' in location ${LOCATION}  ${RESET_FORMAT}"
echo

gcloud dataplex lakes create customer-engagements \
   --location=$LOCATION \
   --display-name="Customer Engagements"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Create Dataplex Zone ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}  Creating Dataplex Zone 'raw-event-data' in location ${LOCATION}  ${RESET_FORMAT}"
echo
gcloud dataplex zones create raw-event-data \
    --location=$LOCATION \
    --lake=customer-engagements \
    --display-name="Raw Event Data" \
    --type=RAW \
    --resource-location-type=SINGLE_REGION \
    --discovery-enabled

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Create Storage Bucket ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating storage bucket 'gs://$ID' in location ${LOCATION} for the project '${ID}'  ${RESET_FORMAT}"
echo
gsutil mb -p $ID -c REGIONAL -l $LOCATION gs://$ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Create Dataplex Asset ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating Dataplex Asset 'raw-event-files' in location ${LOCATION}   ${RESET_FORMAT}"
echo

gcloud dataplex assets create raw-event-files \
--location=$LOCATION \
--lake=customer-engagements \
--zone=raw-event-data \
--display-name="Raw Event Files" \
--resource-type=STORAGE_BUCKET \
--resource-name=projects/my-project/buckets/${ID}

PROJECT_ID=$(gcloud config get-value project)  # Fetch the current project ID
URL="https://console.cloud.google.com/dataplex/templates/create?project=${PROJECT_ID}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Open Dataplex Templates URL ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Open the following URL:${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT} $URL ${RESET_FORMAT}"
echo

# echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
# echo""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
