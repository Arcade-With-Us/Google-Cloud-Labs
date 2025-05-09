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

# Start of the script
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE:${RESET_FORMAT}"
read -r ZONE
echo
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter API KEY:${RESET_FORMAT}"
read -r API_KEY
echo
gcloud compute ssh lab-vm --zone=$ZONE --quiet --command "https://raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Analyze%20Sentiment%20with%20Natural%20Language%20API%3A%20Challenge%20Lab/ARC130.sh"

# # Safely delete the script if it exists
# SCRIPT_NAME="arcadecrew.sh"
# if [ -f "$SCRIPT_NAME" ]; then
#     echo -e "${RED_TEXT}${BOLD_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
#     rm -- "$SCRIPT_NAME"
# fi

echo
# Completion message
echo -e "${GREEN_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
