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


echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the location:${RESET_FORMAT} \c"
read LOCATION
export LOCATION

# Enable required services on Google Cloud
gcloud services enable run.googleapis.com
gcloud services enable eventarc.googleapis.com

# Set up Pub/Sub topic and subscription
gcloud pubsub topics create "$DEVSHELL_PROJECT_ID-topic"
gcloud pubsub subscriptions create --topic "$DEVSHELL_PROJECT_ID-topic" "$DEVSHELL_PROJECT_ID-topic-sub"

# Deploy the Cloud Run service
gcloud run deploy pubsub-events \
  --image=gcr.io/cloudrun/hello \
  --platform=managed \
  --region="$LOCATION" \
  --allow-unauthenticated

# Create Eventarc trigger to listen to Pub/Sub messages
gcloud eventarc triggers create pubsub-events-trigger \
  --location="$LOCATION" \
  --destination-run-service=pubsub-events \
  --destination-run-region="$LOCATION" \
  --transport-topic="$DEVSHELL_PROJECT_ID-topic" \
  --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished"

# Send a test message to the Pub/Sub topic
gcloud pubsub topics publish "$DEVSHELL_PROJECT_ID-topic" \
  --message="Test message"


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
