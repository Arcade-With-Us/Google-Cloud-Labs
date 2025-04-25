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

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Prompt user for input
read -p "$(echo -e ${WHITE_TEXT}${BOLD_TEXT}Enter your GCP Zone: ${RESET_FORMAT})" ZONE

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling required services...${RESET_FORMAT}"
gcloud services enable notebooks.googleapis.com

gcloud services enable aiplatform.googleapis.com

sleep 15

# Instructions for notebook creation
echo "${CYAN_TEXT}${BOLD_TEXT}Creating a new AI Notebook instance...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This may take a few minutes. Please wait.${RESET_FORMAT}"
echo

export NOTEBOOK_NAME="lab-workbench"
export MACHINE_TYPE="e2-standard-2"

gcloud notebooks instances create $NOTEBOOK_NAME \
  --location=$ZONE \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-latest-cpu


echo "${GREEN_TEXT}${BOLD_TEXT}Notebook instance created successfully!${RESET_FORMAT}"
# Get the current project ID
PROJECT_ID=$(gcloud config get-value project)
echo "${YELLOW_TEXT}${BOLD_TEXT}You can access your notebook at the following URL:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/vertex-ai/workbench/user-managed?project=$DEVSHELL_PROJECT_ID ${RESET_FORMAT}"

# Completion message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              NOW FOLLOW VIDEO STEPS...              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
