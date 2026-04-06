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

# Enable required APIs with color output
echo -e "${YELLOW_TEXT}Enabling Database Migration API...${RESET_FORMAT}"
gcloud services enable datamigration.googleapis.com --quiet
echo -e "${YELLOW_TEXT}Enabling Service Networking API...${RESET_FORMAT}"
gcloud services enable servicenetworking.googleapis.com --quiet

# User prompts with bold formatting
echo -e "${BOLD_TEXT}${YELLOW_TEXT}Please enter the connection profile details:${RESET_FORMAT}"

read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the connection profile ID (unique identifier): ${RESET_FORMAT}")" CONNECTION_PROFILE_ID
read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the connection profile display name: ${RESET_FORMAT}")" CONNECTION_PROFILE_NAME
read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the host or IP address: ${RESET_FORMAT}")" HOST_OR_IP
read -p "$(echo -e "${BOLD_TEXT}${WHITE_TEXT}Enter the region: ${RESET_FORMAT}")" REGION

# Variables
DATABASE_ENGINE="MYSQL"
USERNAME="admin"
PASSWORD="changeme"
PORT=3306

# Check if profile exists with color output
EXISTS=$(gcloud database-migration connection-profiles describe "$CONNECTION_PROFILE_ID" --location="$REGION" --quiet --format="value(name)" 2>/dev/null)

if [ "$EXISTS" == "" ]; then
  # Create the connection profile with success message
  gcloud database-migration connection-profiles create mysql "$CONNECTION_PROFILE_ID" \
    --display-name="$CONNECTION_PROFILE_NAME" \
    --region="$REGION" \
    --host="$HOST_OR_IP" \
    --port=$PORT \
    --username="$USERNAME" \
    --password="$PASSWORD"

  echo -e "${GREEN_TEXT}${BOLD_TEXT}Connection profile '${CONNECTION_PROFILE_NAME}' (ID: ${CONNECTION_PROFILE_ID}) created successfully in region '${REGION}' with database engine '${DATABASE_ENGINE}'.${NO_COLOR}"
else
  # Profile already exists warning
  echo -e "${YELLOW_TEXT}${BOLD_TEXT}Connection profile with ID '${CONNECTION_PROFILE_ID}' already exists in region '${REGION}'. No new profile was created.${NO_COLOR}"
fi


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
