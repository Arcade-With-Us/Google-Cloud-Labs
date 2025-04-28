#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo ""
echo ""

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo

gcloud auth list

export BUCKET_NAME=$DEVSHELL_PROJECT_ID-bucket

export PROJECT_ID=$DEVSHELL_PROJECT_ID

git clone https://github.com/quiccklabs/Redacting-Sensitive-Data-with-Cloud-Data-Loss-Prevention.git

cd Redacting-Sensitive-Data-with-Cloud-Data-Loss-Prevention/quicklabgsp864/samples && npm install

gcloud config set project $PROJECT_ID

gcloud services enable dlp.googleapis.com cloudkms.googleapis.com \
--project $PROJECT_ID

node inspectString.js $PROJECT_ID "My email address is jenny@somedomain.com and you can call me at 555-867-5309" > inspected-string.txt

node inspectFile.js $PROJECT_ID resources/accounts.txt > inspected-file.txt

gsutil cp inspected-string.txt gs://$BUCKET_NAME
gsutil cp inspected-file.txt gs://$BUCKET_NAME

node deidentifyWithMask.js $PROJECT_ID "My order number is F12312399. Email me at anthony@somedomain.com" > de-identify-output.txt

gsutil cp de-identify-output.txt gs://$BUCKET_NAME


node redactText.js $PROJECT_ID  "Please refund the purchase to my credit card 4012888888881881" CREDIT_CARD_NUMBER > redacted-string.txt

node redactImage.js $PROJECT_ID resources/test.png "" PHONE_NUMBER ./redacted-phone.png

node redactImage.js $PROJECT_ID resources/test.png "" EMAIL_ADDRESS ./redacted-email.png

gsutil cp redacted-string.txt gs://$BUCKET_NAME
gsutil cp redacted-phone.png gs://$BUCKET_NAME
gsutil cp redacted-email.png gs://$BUCKET_NAME

echo
echo -e "\e[1;31mDeleting the script (GSP864.sh) for safety purposes...\e[0m"
rm -- "$0"
echo
echo
# Completion message
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
