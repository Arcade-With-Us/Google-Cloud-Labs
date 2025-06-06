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

echo "${GREEN_TEXT}${BOLD_TEXT}📍 Step 1: Retrieving default region configuration...${RESET_FORMAT}"
echo

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  No default region found!${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}💡 Please specify your preferred region for App Engine deployment:${RESET_FORMAT}"
  echo -n "${CYAN_TEXT}${BOLD_TEXT}Please enter your region: ${RESET_FORMAT}"
  read REGION
fi

echo "REGION=${REGION}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔐 Step 2: Checking authentication status...${RESET_FORMAT}"
echo

gcloud auth list

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🆔 Step 3: Setting up project configuration...${RESET_FORMAT}"
echo

export PROJECT_ID=$(gcloud config get-value project)

echo
echo "${GREEN_TEXT}${BOLD_TEXT}⚙️  Step 4: Enabling App Engine API service...${RESET_FORMAT}"
echo

gcloud services enable appengine.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📥 Step 5: Downloading sample application code...${RESET_FORMAT}"
echo

git clone https://github.com/GoogleCloudPlatform/python-docs-samples

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📂 Step 6: Navigating to Hello World application...${RESET_FORMAT}"
echo

cd ~/python-docs-samples/appengine/standard_python3/hello_world

export "PROJECT_ID=${PROJECT_ID}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🏗️  Step 7: Initializing App Engine application...${RESET_FORMAT}"
echo

gcloud app create --project $PROJECT_ID --region=$REGION

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Step 8: Deploying application to App Engine...${RESET_FORMAT}"
echo

echo "Y" | gcloud app deploy app.yaml --project $PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📍 Step 9: Finalizing deployment location...${RESET_FORMAT}"
echo

cd ~/python-docs-samples/appengine/standard_python3/hello_world

echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Step 10: Creating application version...${RESET_FORMAT}"
echo

echo "Y" | gcloud app deploy -v v1

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
