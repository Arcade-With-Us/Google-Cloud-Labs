#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=$'\033[0;34m'

echo "${BOLD_TEXT}${CYAN_TEXT}Starting the process...${RESET_FORMAT}"

# Prompt user for region input
echo "${BOLD_TEXT}${GREEN_TEXT}Enter REGION:${RESET_FORMAT}"
read -p "${BOLD_TEXT}${BLUE_TEXT}Region: ${RESET_FORMAT}" REGION
export REGION

# Enable Dataplex API
echo "${BOLD_TEXT}${CYAN_TEXT}Enabling Dataplex API...${RESET_FORMAT}"
gcloud services enable dataplex.googleapis.com

# Create Dataplex Lake
echo "${BOLD_TEXT}${CYAN_TEXT}Creating Dataplex Lake 'sensors'...${RESET_FORMAT}"
gcloud alpha dataplex lakes create sensors \
 --location=$REGION \
 --labels=k1=v1,k2=v2,k3=v3 

# Create Dataplex Zone
echo "${BOLD_TEXT}${CYAN_TEXT}Creating Dataplex Zone 'temperature-raw-data'...${RESET_FORMAT}"
gcloud alpha dataplex zones create temperature-raw-data \
            --location=$REGION --lake=sensors \
            --resource-location-type=SINGLE_REGION --type=RAW

# Create Storage Bucket
echo "${BOLD_TEXT}${CYAN_TEXT}Creating a Storage Bucket...${RESET_FORMAT}"
gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID

# Create Dataplex Asset
echo "${BOLD_TEXT}${CYAN_TEXT}Creating Dataplex Asset 'measurements'...${RESET_FORMAT}"
gcloud dataplex assets create measurements --location=$REGION \
            --lake=sensors --zone=temperature-raw-data \
            --resource-type=STORAGE_BUCKET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID

# Cleanup: Delete Dataplex Asset
echo "${BOLD_TEXT}${RED_TEXT}Deleting Dataplex Asset 'measurements'...${RESET_FORMAT}"
gcloud dataplex assets delete measurements --zone=temperature-raw-data --lake=sensors --location=$REGION --quiet

# Cleanup: Delete Dataplex Zone
echo "${BOLD_TEXT}${RED_TEXT}Deleting Dataplex Zone 'temperature-raw-data'...${RESET_FORMAT}"
gcloud dataplex zones delete temperature-raw-data --lake=sensors --location=$REGION --quiet

# Cleanup: Delete Dataplex Lake
echo "${BOLD_TEXT}${RED_TEXT}Deleting Dataplex Lake 'sensors'...${RESET_FORMAT}"
gcloud dataplex lakes delete sensors --location=$REGION --quiet


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
