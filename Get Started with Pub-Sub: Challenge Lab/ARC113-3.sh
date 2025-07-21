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

read -p "${CYAN_TEXT}${BOLD_TEXT}Enter your GCP region: ${RESET_FORMAT}" LOCATION
export LOCATION

export MSG_BODY='Hello World!'

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${BLUE_TEXT}Creating a Pub/Sub topic to publish messages.${RESET_FORMAT}"
echo
gcloud pubsub topics create cloud-pubsub-topic

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${CYAN_TEXT}Creating a subscription to receive messages from our topic.${RESET_FORMAT}"
echo
gcloud pubsub subscriptions create cloud-pubsub-subscription --topic=cloud-pubsub-topic

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${MAGENTA_TEXT}Enabling the Cloud Scheduler service.${RESET_FORMAT}"
echo
gcloud services enable cloudscheduler.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${GREEN_TEXT}Creating a scheduler job that publishes messages every minute.${RESET_FORMAT}"
echo
gcloud scheduler jobs create pubsub cron-scheduler-job \
  --location=$LOCATION \
  --schedule="* * * * *" \
  --topic=cloud-pubsub-topic \
  --message-body="Hello World!"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${YELLOW_TEXT}Pulling messages from our subscription to verify delivery.${RESET_FORMAT}"
echo
gcloud pubsub subscriptions pull cloud-pubsub-subscription --limit 5

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
