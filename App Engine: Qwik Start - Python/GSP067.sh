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

# Prompt the user for the region
echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the region: ${NO_COLOR}${RESET_FORMAT}"
read REGION

# Set the compute region
gcloud config set compute/region $REGION

# Enable the App Engine API
gcloud services enable appengine.googleapis.com

# Clone the repository
git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

# Navigate to the hello_world directory
cd python-docs-samples/appengine/standard_python3/hello_world

# Modify the main.py file
sed -i 's/Hello World!/Hello, Cruel World!/g' main.py

# Create the App Engine app
gcloud app create --region=$REGION

# Deploy the app
yes | gcloud app deploy

# Completion message
echo -e "${RED_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
