#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Prompt user for REGION input
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
read -r REGION
echo "${GREEN_TEXT}${BOLD_TEXT}Region set to:${RESET_FORMAT} ${REGION}"

gcloud spanner instances create test-instance \
  --config=regional-$REGION \
  --description="Test Instance" \
  --nodes=1

echo "${BLUE_TEXT}${BOLD_TEXT}Spanner instance 'test-instance' created successfully!${RESET_FORMAT}"

gcloud spanner databases create example-db --instance=test-instance
echo "${MAGENTA_TEXT}${BOLD_TEXT}Database 'example-db' created successfully!${RESET_FORMAT}"

gcloud spanner databases ddl update example-db --instance=test-instance \
  --ddl="CREATE TABLE Singers (
    SingerId INT64 NOT NULL,
    FirstName STRING(1024),
    LastName STRING(1024),
    SingerInfo BYTES(MAX),
    BirthDate DATE,
    ) PRIMARY KEY(SingerId);"

echo "${GREEN_TEXT}${BOLD_TEXT}Table 'Singers' created successfully in 'example-db'!${RESET_FORMAT}"
echo 


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo
# Completion message
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
