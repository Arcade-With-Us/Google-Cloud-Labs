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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Prompt for region if not set
if [ -z "$region" ]; then
  read -p "${MAGENTA_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" region
  export region
  echo "${GREEN_TEXT}${BOLD_TEXT}Region set to: $region${RESET_FORMAT}"
fi

export BUCKET=$(gcloud config get-value project)

# Instructions before creating bucket
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}INSTRUCTIONS:${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Creating a bucket named 'gs://$BUCKET'.${RESET_FORMAT}"
echo
gsutil mb -l $region "gs://$BUCKET"
sleep 10

echo "${MAGENTA_TEXT}${BOLD_TEXT}Setting retention policy...${RESET_FORMAT}"
gsutil retention set 10s "gs://$BUCKET"
gsutil retention get "gs://$BUCKET"


echo "${MAGENTA_TEXT}${BOLD_TEXT}Copying dummy_transactions...${RESET_FORMAT}"
gsutil cp gs://spls/gsp297/dummy_transactions "gs://$BUCKET/"
gsutil ls -L "gs://$BUCKET/dummy_transactions"
sleep 10

echo "${MAGENTA_TEXT}${BOLD_TEXT}Locking retention policy...${RESET_FORMAT}"
gsutil retention lock "gs://$BUCKET/"


echo "${MAGENTA_TEXT}${BOLD_TEXT}Setting temporary hold...${RESET_FORMAT}"
gsutil retention temp set "gs://$BUCKET/dummy_transactions"


echo "${MAGENTA_TEXT}${BOLD_TEXT}Removing dummy_transactions...${RESET_FORMAT}"
gsutil rm "gs://$BUCKET/dummy_transactions"


echo "${MAGENTA_TEXT}${BOLD_TEXT}Releasing temporary hold...${RESET_FORMAT}"
gsutil retention temp release "gs://$BUCKET/dummy_transactions"


echo "${MAGENTA_TEXT}${BOLD_TEXT}Setting event-based hold as default...${RESET_FORMAT}"
gsutil retention event-default set "gs://$BUCKET/"


echo "${MAGENTA_TEXT}${BOLD_TEXT}Copying dummy_loan...${RESET_FORMAT}"
gsutil cp gs://spls/gsp297/dummy_loan "gs://$BUCKET/"
gsutil ls -L "gs://$BUCKET/dummy_loan"


echo "${MAGENTA_TEXT}${BOLD_TEXT}Releasing event-based hold...${RESET_FORMAT}"
gsutil retention event release "gs://$BUCKET/dummy_loan"
gsutil ls -L "gs://$BUCKET/dummy_loan"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
