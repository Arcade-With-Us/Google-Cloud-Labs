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

read -p "$(echo -e ${MAGENTA_TEXT}${BOLD_TEXT}Enter the zone:${RESET_FORMAT} ) " ZONE
export ZONE

# Informing the user about the next steps
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a storage bucket in your project...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This bucket will store the startup script.${RESET_FORMAT}"
echo

gsutil mb gs://$DEVSHELL_PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Copying the startup script to the storage bucket...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}The script will be used to configure the VM instance.${RESET_FORMAT}"
echo

gsutil cp gs://sureskills-ql/challenge-labs/ch01-startup-script/install-web.sh gs://$DEVSHELL_PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a Compute Engine instance...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This instance will run the startup script to set up a web server.${RESET_FORMAT}"
echo

gcloud compute instances create quickgcplab --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=n1-standard-1 --tags=http-server --metadata startup-script-url=gs://$DEVSHELL_PROJECT_ID/install-web.sh

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Setting up a firewall rule to allow HTTP traffic...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This will enable access to the web server on port 80.${RESET_FORMAT}"
echo

gcloud compute firewall-rules create allow-http \
    --allow=tcp:80 \
    --description="awesome lab" \
    --direction=INGRESS \
    --target-tags=http-server

# Completion message
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
