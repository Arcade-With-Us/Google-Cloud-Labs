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
echo "${CYAN_TEXT}${BOLD_TEXT}             INITIATING EXECUTION          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${WHITE_TEXT}Creating a storage bucket in your GCP project.${RESET_FORMAT}"
echo

gsutil mb -p $DEVSHELL_PROJECT_ID \
  -c standard    \
  -l us \
  gs://$DEVSHELL_PROJECT_ID-vcm/

export BUCKET=$DEVSHELL_PROJECT_ID-vcm

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${WHITE_TEXT}Copying images from the public GCP bucket to your bucket.${RESET_FORMAT}"
echo

gsutil -m cp -r gs://spls/gsp223/images/* gs://${BUCKET}

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${WHITE_TEXT}Downloading the data.csv file to your local environment.${RESET_FORMAT}"
echo

gsutil cp gs://spls/gsp223/data.csv .

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${WHITE_TEXT}Updating the data.csv file with your bucket name.${RESET_FORMAT}"
echo

sed -i -e "s/placeholder/${BUCKET}/g" ./data.csv

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${WHITE_TEXT}Uploading the updated data.csv file back to your bucket.${RESET_FORMAT}"
echo

gsutil cp ./data.csv gs://${BUCKET}

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${WHITE_TEXT}Access the Vertex AI console to create a dataset.${RESET_FORMAT}"
echo

echo "${CYAN}${BOLD}OPEN THIS LINK: "${RESET}""${BLUE}${BOLD}""https://console.cloud.google.com/vertex-ai/datasets/create?project=$DEVSHELL_PROJECT_ID"""${RESET}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}***********************************************${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}             NOW FOLLOW VIDEO STEPS          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}***********************************************${RESET_FORMAT}"
echo

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
