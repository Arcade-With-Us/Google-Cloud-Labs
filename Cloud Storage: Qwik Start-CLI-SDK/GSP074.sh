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

read -p "${MAGENTA_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
export REGION

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}No region specified. Proceeding without setting a region.${RESET_FORMAT}"
else
  echo "${GREEN_TEXT}${BOLD_TEXT}Setting compute/region to: $REGION${RESET_FORMAT}"
fi

gcloud config set compute/region $REGION

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating a Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Downloading the Ada Lovelace image...${RESET_FORMAT}"
curl https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Ada_Lovelace_portrait.jpg/800px-Ada_Lovelace_portrait.jpg --output ada.jpg

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Copying the image to the Cloud Storage bucket...${RESET_FORMAT}"
gsutil cp ada.jpg gs://$DEVSHELL_PROJECT_ID

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Copying the image from the Cloud Storage bucket to the local directory...${RESET_FORMAT}"
gsutil cp -r gs://$DEVSHELL_PROJECT_ID/ada.jpg .

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating 'image-folder' in the bucket and copying image inside it...${RESET_FORMAT}"
gsutil cp gs://$DEVSHELL_PROJECT_ID/ada.jpg gs://$DEVSHELL_PROJECT_ID/image-folder/

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Setting access control for the image in Cloud Storage...${RESET_FORMAT}"
gsutil acl ch -u AllUsers:R gs://$DEVSHELL_PROJECT_ID/ada.jpg

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
