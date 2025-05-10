#!/bin/bash

# Define text colors and formatting
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
clear # Clear the terminal screen

# --- Script Header ---
echo
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         STARTING EXECUTION...       ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Instruction for setting up the zone
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${CYAN_TEXT}Fetching the default compute zone from your project metadata.${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Please ensure that you have set up your project and authenticated with gcloud.${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Instruction for extracting the region
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${CYAN_TEXT}Extracting the region from the zone information.${RESET_FORMAT}"
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

# Enabling required services
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${CYAN_TEXT}Enabling the API Keys service in your project.${RESET_FORMAT}"
gcloud services enable apikeys.googleapis.com

# Downloading and extracting the quickstart files
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${CYAN_TEXT}Downloading and unzipping the Endpoints Quickstart files.${RESET_FORMAT}"
gsutil cp gs://spls/gsp164/endpoints-quickstart.zip .
unzip endpoints-quickstart.zip

# Navigating to the required directories
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${CYAN_TEXT}Navigating to the scripts directory for deployment.${RESET_FORMAT}"
cd endpoints-quickstart
cd scripts

# Deploying the API
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${CYAN_TEXT}Deploying the API using the provided deployment script.${RESET_FORMAT}"
./deploy_api.sh
echo "${MAGENTA_TEXT}Pausing for 60 seconds to avoid quota issues...${RESET_FORMAT}"
sleep 60

# Deploying the application
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 7:${RESET_FORMAT} ${CYAN_TEXT}Deploying the application template to the region: ${REGION}.${RESET_FORMAT}"
./deploy_app.sh ../app/app_template.yaml $REGION
echo "${MAGENTA_TEXT}Pausing for 60 seconds...${RESET_FORMAT}"
sleep 60

# Querying the API
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 8:${RESET_FORMAT} ${CYAN_TEXT}Querying the API to verify its functionality.${RESET_FORMAT}"
./query_api.sh

# Querying the API with a parameter
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 9:${RESET_FORMAT} ${CYAN_TEXT}Querying the API with a parameter (e.g., JFK).${RESET_FORMAT}"
./query_api.sh JFK

# Deploying the API with rate limiting
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 10:${RESET_FORMAT} ${CYAN_TEXT}Deploying the API with rate limiting configuration.${RESET_FORMAT}"
./deploy_api.sh ../openapi_with_ratelimit.yaml
echo "${MAGENTA_TEXT}Pausing for 60 seconds to avoid quota issues...${RESET_FORMAT}"
sleep 60

# Redeploying the application
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 11:${RESET_FORMAT} ${CYAN_TEXT}Redeploying the application template to the region: ${REGION}.${RESET_FORMAT}"
./deploy_app.sh ../app/app_template.yaml $REGION
echo "${MAGENTA_TEXT}Pausing for 60 seconds...${RESET_FORMAT}" 
sleep 60

# Creating an API key
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 12:${RESET_FORMAT} ${CYAN_TEXT}Creating an API key with the display name 'awesome'.${RESET_FORMAT}"
gcloud alpha services api-keys create --display-name="awesome" 

# Fetching the API key name
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 13:${RESET_FORMAT} ${CYAN_TEXT}Fetching the name of the created API key.${RESET_FORMAT}"
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

# Fetching the API key string
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 14:${RESET_FORMAT} ${CYAN_TEXT}Retrieving the API key string for usage.${RESET_FORMAT}"
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

# Querying the API with the API key
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 15:${RESET_FORMAT} ${CYAN_TEXT}Querying the API using the generated API key.${RESET_FORMAT}"
./query_api_with_key.sh $API_KEY

# Generating traffic with the API key
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 16:${RESET_FORMAT} ${CYAN_TEXT}Generating traffic to the API using the API key.${RESET_FORMAT}"
./generate_traffic_with_key.sh $API_KEY

# Querying the API again with the API key
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 17:${RESET_FORMAT} ${CYAN_TEXT}Querying the API again to verify the traffic generation.${RESET_FORMAT}"
./query_api_with_key.sh $API_KEY

echo
# Final message
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
