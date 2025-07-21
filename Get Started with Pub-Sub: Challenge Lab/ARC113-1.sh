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

echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${CYAN_TEXT}Creating a subscription to our topic.${RESET_FORMAT}"
echo

gcloud pubsub subscriptions create pubsub-subscription-message --topic gcloud-pubsub-topic

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${YELLOW_TEXT}Publishing a simple message to our topic.${RESET_FORMAT}"
echo "${YELLOW_TEXT}The message '${BOLD_TEXT}Hello World${RESET_FORMAT}${YELLOW_TEXT}' will be sent to all subscriptions.${RESET_FORMAT}"
echo

gcloud pubsub topics publish gcloud-pubsub-topic --message="Hello World"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Waiting:${RESET_FORMAT} ${MAGENTA_TEXT}Allowing time for message to be processed...${RESET_FORMAT}"
echo

sleep 10

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${GREEN_TEXT}Pulling messages from our subscription.${RESET_FORMAT}"
echo "${GREEN_TEXT}This retrieves up to ${BOLD_TEXT}5${RESET_FORMAT}${GREEN_TEXT} messages that were sent to our topic.${RESET_FORMAT}"
echo

gcloud pubsub subscriptions pull pubsub-subscription-message --limit 5

echo
echo "${RED_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${RED_TEXT}Creating a snapshot of our subscription.${RESET_FORMAT}"
echo

gcloud pubsub snapshots create pubsub-snapshot --subscription=gcloud-pubsub-subscription

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
