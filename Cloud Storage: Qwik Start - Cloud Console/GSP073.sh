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

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}"
read REGION
echo "${BLUE_TEXT}${BOLD_TEXT}You entered: $REGION${RESET_FORMAT}"

gcloud config set compute/region $REGION

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Creating a Cloud Storage Bucket  ========================== ${RESET_FORMAT}"
echo
gsutil mb gs://$DEVSHELL_PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Downloading an image (ada.jpg)  ========================== ${RESET_FORMAT}"
echo
curl https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Ada_Lovelace_portrait.jpg/800px-Ada_Lovelace_portrait.jpg --output ada.jpg

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Renaming the image to kitten.png ========================== ${RESET_FORMAT}"
echo
mv ada.jpg kitten.png

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Copying kitten.png to the Bucket ========================== ${RESET_FORMAT}"
echo
gsutil cp kitten.png gs://$DEVSHELL_PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Copying kitten.png from Bucket to Current Directory  ========================== ${RESET_FORMAT}"
echo
gsutil cp -r gs://$DEVSHELL_PROJECT_ID/kitten.png .

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Copying kitten.png to image-folder inside the bucket  ========================== ${RESET_FORMAT}"
echo
gsutil cp gs://$DEVSHELL_PROJECT_ID/kitten.png gs://$DEVSHELL_PROJECT_ID/image-folder/

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Setting IAM Permissions ========================== ${RESET_FORMAT}"
echo
gsutil iam ch allUsers:objectViewer gs://$DEVSHELL_PROJECT_ID
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT}"
echo -e "${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
