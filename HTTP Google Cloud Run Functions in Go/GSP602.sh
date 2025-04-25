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

# Clear the screen
clear

# Print the welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Instruction for authentication
echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${WHITE_TEXT}Authenticating with Google Cloud...${RESET_FORMAT}"
gcloud auth list

# Instruction for enabling services
echo "${CYAN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${WHITE_TEXT}Enabling required Google Cloud services...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This will enable Cloud Run and Cloud Functions APIs.${RESET_FORMAT}"
gcloud services enable run.googleapis.com

gcloud services enable cloudfunctions.googleapis.com

# Instruction for setting zone
echo "${CYAN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${WHITE_TEXT}Setting the default compute zone...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching and configuring the default zone for your project.${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud config set compute/zone "$ZONE"

# Instruction for setting region
echo "${CYAN_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${WHITE_TEXT}Setting the default compute region...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching and configuring the default region for your project.${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
gcloud config set compute/region "$REGION"

# Instruction for downloading sample code
echo "${CYAN_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${WHITE_TEXT}Downloading sample code from GitHub...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This will download and unzip the Go sample functions.${RESET_FORMAT}"
curl -LO https://github.com/GoogleCloudPlatform/golang-samples/archive/main.zip

unzip main.zip

cd golang-samples-main/functions/codelabs/gopher

# Instruction for deploying the first function
echo "${CYAN_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${WHITE_TEXT}Deploying the HelloWorld function...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This will deploy the HelloWorld function using Cloud Functions Gen2.${RESET_FORMAT}"
deploy_function() {
 gcloud functions deploy HelloWorld --gen2 --runtime go121 --trigger-http --region $REGION --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo ""
    deploy_success=true
  else
    echo "${RED_TEXT}${BOLD_TEXT}Deployment failed. Retrying in 10 seconds...${RESET_FORMAT}"
    echo "${YELLOW_TEXT}${BOLD_TEXT}Meanwhile subscribe Arcade Crew! ${RESET_FORMAT}"
    sleep 10
  fi
done

# Instruction for deploying the second function
echo "${CYAN_TEXT}${BOLD_TEXT}Step 7:${RESET_FORMAT} ${WHITE_TEXT}Deploying the Gopher function...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This will deploy the Gopher function using Cloud Functions Gen2.${RESET_FORMAT}"
deploy_function() {
 gcloud functions deploy Gopher --gen2 --runtime go121 --trigger-http --region $REGION --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo ""
    deploy_success=true
  else
    echo "${RED_TEXT}${BOLD_TEXT}Deployment failed. Retrying in 10 seconds...${RESET_FORMAT}"
    echo "${YELLOW_TEXT}${BOLD_TEXT}Meanwhile subscribe Arcade Crew! ${RESET_FORMAT}"
    sleep 10
  fi
done

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
