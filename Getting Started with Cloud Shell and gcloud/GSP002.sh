#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}             INITIATING EXECUTION          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

echo -n "${BLUE_TEXT}${BOLD_TEXT}ENTER the ZONE:- ${RESET_FORMAT}"
read ZONE

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating an instance with the name gcelab2 in zone $ZONE...${RESET_FORMAT}"
echo
gcloud compute instances create gcelab2 --machine-type e2-medium --zone $ZONE

echo "${YELLOW_TEXT}${BOLD_TEXT}Adding tags to the instance gcelab2 in zone $ZONE...${RESET_FORMAT}"
echo
gcloud compute instances add-tags gcelab2 --zone $ZONE --tags http-server,https-server

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a firewall rule to allow HTTP traffic...${RESET_FORMAT}"
echo
gcloud compute firewall-rules create default-allow-http --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
