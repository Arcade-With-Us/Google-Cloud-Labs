#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
MAGENTA_COLOR="\e[35m"
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo
echo

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo

# Instruction: Creating Cloud Storage Buckets
echo "${BLUE_TEXT}${BOLD_TEXT}Step 1: Creating Cloud Storage Buckets...${RESET_FORMAT}"

gsutil mb gs://$DEVSHELL_PROJECT_ID
gsutil mb gs://$DEVSHELL_PROJECT_ID-2

echo

# Instruction: Downloading Demo Images
echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Downloading Demo Images...${RESET_FORMAT}"

curl -LO https://raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/APIs%20Explorer%3A%20Cloud%20Storage/demo-image1.png

curl -LO https://raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/APIs%20Explorer%3A%20Cloud%20Storage/demo-image2.png

curl -LO https://raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/APIs%20Explorer%3A%20Cloud%20Storage/demo-image1-copy.png
echo

# Instruction: Uploading Images to Cloud Storage
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Uploading Images to Cloud Storage...${RESET_FORMAT}"

gsutil cp demo-image1.png gs://$DEVSHELL_PROJECT_ID/demo-image1.png
gsutil cp demo-image2.png gs://$DEVSHELL_PROJECT_ID/demo-image2.png
gsutil cp demo-image1-copy.png gs://$DEVSHELL_PROJECT_ID-2/demo-image1-copy.png

echo
# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo
# Completion message
echo -e "${MAGENTA_COLOR}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
