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

# Instructions for the user
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the region:: ${RESET_FORMAT}" REGION
export REGION=$REGION
echo "${YELLOW_TEXT}${BOLD_TEXT}You have selected the region: $REGION.${RESET_FORMAT}"
echo

# Instructions before creating the first Spanner instance
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the first Spanner instance: banking-instance.${RESET_FORMAT}"
echo

gcloud spanner instances create banking-instance \
--config=regional-$REGION  \
--description="arcadecrew" \
--nodes=1

# Instructions before creating the first database
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the first database: banking-db in banking-instance.${RESET_FORMAT}"
echo

gcloud spanner databases create banking-db --instance=banking-instance

# Instructions before creating the second Spanner instance
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the second Spanner instance: banking-instance-2.${RESET_FORMAT}"
echo

gcloud spanner instances create banking-instance-2 \
--config=regional-$REGION  \
--description="arcadecrew" \
--nodes=2

# Instructions before creating the second database
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the second database: banking-db-2 in banking-instance-2.${RESET_FORMAT}"
echo

gcloud spanner databases create banking-db-2 --instance=banking-instance-2

# Instructions before updating the database schema
echo "${MAGENTA_TEXT}${BOLD_TEXT}Updating the schema of banking-db to create the Customer table.${RESET_FORMAT}"
echo

gcloud spanner databases ddl update banking-db --instance=banking-instance --ddl="CREATE TABLE Customer (
  CustomerId STRING(36) NOT NULL,
  Name STRING(MAX) NOT NULL,
  Location STRING(MAX) NOT NULL,
) PRIMARY KEY (CustomerId);"

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
