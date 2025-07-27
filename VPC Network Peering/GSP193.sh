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

export PROJECT_ID=$DEVSHELL_PROJECT_ID

export REGION_1="${ZONE%-*}"

export REGION_2="${ZONE_2%-*}"

gcloud config set project $PROJECT_ID

gcloud compute networks create network-a --subnet-mode custom

gcloud compute networks subnets create network-a-subnet --network network-a \
    --range 10.0.0.0/16 --region $REGION_1

gcloud compute instances create vm-a --zone $ZONE --network network-a --subnet network-a-subnet --machine-type e2-small

gcloud compute firewall-rules create network-a-fw --network network-a --allow tcp:22,icmp

# Switch to the second project
gcloud config set project $PROJECT_ID_2

# Create the custom network
gcloud compute networks create network-b --subnet-mode custom

# Create the subnet within this VPC
gcloud compute networks subnets create network-b-subnet --network network-b \
    --range 10.8.0.0/16 --region $REGION_2

# Create the VM instance
gcloud compute instances create vm-b --zone $ZONE_2 --network network-b --subnet network-b-subnet --machine-type e2-small

# Enable SSH and ICMP firewall rules
gcloud compute firewall-rules create network-b-fw --network network-b --allow tcp:22,icmp

gcloud config set project $PROJECT_ID

gcloud compute networks peerings create peer-ab \
    --network=network-a \
    --peer-project=$PROJECT_ID_2 \
    --peer-network=network-b 

gcloud config set project $PROJECT_ID_2

gcloud compute networks peerings create peer-ba \
    --network=network-b \
    --peer-project=$PROJECT_ID \
    --peer-network=network-a

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
