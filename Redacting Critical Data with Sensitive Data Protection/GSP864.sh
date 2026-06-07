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

# Spinner function
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

# Display current authenticated accounts
echo -n "${CYAN}${BOLD}Checking authenticated accounts...${RESET}"
(gcloud auth list > /dev/null 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"
gcloud auth list

# Set up environment variables
export BUCKET_NAME=$DEVSHELL_PROJECT_ID-bucket
export PROJECT_ID=$DEVSHELL_PROJECT_ID

# Clone repository
echo -n "${YELLOW}${BOLD}Cloning repository...${RESET}"
(git clone https://github.com/quiccklabs/Redacting-Sensitive-Data-with-Cloud-Data-Loss-Prevention.git > /dev/null 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

# Install npm dependencies
echo -n "${MAGENTA}${BOLD}Installing npm dependencies...${RESET}"
(cd Redacting-Sensitive-Data-with-Cloud-Data-Loss-Prevention/quicklabgsp864/samples && npm install > /dev/null 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

# Set project
echo -n "${BLUE}${BOLD}Setting project...${RESET}"
(gcloud config set project $PROJECT_ID > /dev/null 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

# Enable services
echo -n "${GREEN}${BOLD}Enabling required services...${RESET}"
(gcloud services enable dlp.googleapis.com cloudkms.googleapis.com --project $PROJECT_ID > /dev/null 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

# Run DLP operations
echo "${CYAN}${BOLD}Running DLP inspection and redaction tasks...${RESET}"

echo -n "  - Inspecting string..."
(node inspectString.js $PROJECT_ID "My email address is jenny@somedomain.com and you can call me at 555-867-5309" > inspected-string.txt 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

echo -n "  - Inspecting file..."
(node inspectFile.js $PROJECT_ID resources/accounts.txt > inspected-file.txt 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

echo -n "  - Uploading results to bucket..."
(gsutil cp inspected-string.txt gs://$BUCKET_NAME > /dev/null 2>&1 && 
 gsutil cp inspected-file.txt gs://$BUCKET_NAME > /dev/null 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

echo -n "  - De-identifying data..."
(node deidentifyWithMask.js $PROJECT_ID "My order number is F12312399. Email me at anthony@somedomain.com" > de-identify-output.txt 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

echo -n "  - Uploading de-identified data..."
(gsutil cp de-identify-output.txt gs://$BUCKET_NAME > /dev/null 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

echo -n "  - Redacting text..."
(node redactText.js $PROJECT_ID "Please refund the purchase to my credit card 4012888888881881" CREDIT_CARD_NUMBER > redacted-string.txt 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

echo -n "  - Redacting images..."
(node redactImage.js $PROJECT_ID resources/test.png "" PHONE_NUMBER ./redacted-phone.png > /dev/null 2>&1 &&
 node redactImage.js $PROJECT_ID resources/test.png "" EMAIL_ADDRESS ./redacted-email.png > /dev/null 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

echo -n "  - Uploading redacted content..."
(gsutil cp redacted-string.txt gs://$BUCKET_NAME > /dev/null 2>&1 &&
 gsutil cp redacted-phone.png gs://$BUCKET_NAME > /dev/null 2>&1 &&
 gsutil cp redacted-email.png gs://$BUCKET_NAME > /dev/null 2>&1) &
spinner
echo " ${GREEN}✓ Done!${RESET}"

# Completion message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
