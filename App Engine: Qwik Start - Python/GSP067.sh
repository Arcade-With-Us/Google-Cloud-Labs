# Define color codes for output formatting
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`

BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`

echo "${BACKGROUND_RED}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

#!/bin/bash

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
