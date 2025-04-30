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

# Get the project ID
echo "${YELLOW_TEXT} ${BOLD_TEXT}Fetching your project ID...${RESET_FORMAT}"
export BUCKET="$(gcloud config get-value project)"

echo "${GREEN_TEXT} ${BOLD_TEXT}Your project ID is: ${BUCKET}${RESET_FORMAT}"

# Create the bucket
echo "${YELLOW_TEXT} ${BOLD_TEXT}Creating a bucket with the name: ${BUCKET}-bucket${RESET_FORMAT}"
gsutil mb -p $BUCKET gs://$BUCKET-bucket

# Download the demo image
echo "${YELLOW_TEXT} ${BOLD_TEXT}Downloading the demo image...${RESET_FORMAT}"
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/APIs%20Explorer%3A%20Qwik%20Start/demo-image.jpg

# Upload the demo image to the bucket
echo "${YELLOW_TEXT} ${BOLD_TEXT}Uploading the demo image to the bucket...${RESET_FORMAT}"
gsutil cp demo-image.jpg gs://$BUCKET-bucket/demo-image.jpg

# Make the image publicly accessible
echo "${YELLOW_TEXT} ${BOLD_TEXT}Making the image publicly accessible...${RESET_FORMAT}"
gsutil acl ch -u allUsers:R gs://$BUCKET-bucket/demo-image.jpg

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
