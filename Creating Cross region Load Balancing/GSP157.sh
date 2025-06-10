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

echo "Please set the below values correctly"

# Export the Zone names correctly
read -p "Enter the ZONE1: " ZONE1
read -p "Enter the ZONE2: " ZONE2

gcloud auth list

PROJECT=$(gcloud config get-value project)

REGION1="${ZONE1%-*}"

REGION2="${ZONE2%-*}"

gcloud compute instances create www-1 \
    --image-family debian-11 \
    --image-project debian-cloud \
    --zone $ZONE1 \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      Code
      EOF"


gcloud compute instances create www-2 \
    --image-family debian-11 \
    --image-project debian-cloud \
    --zone $ZONE1 \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      Code
      EOF"


gcloud compute instances create www-3 \
    --image-family debian-11 \
    --image-project debian-cloud \
    --zone $ZONE2 \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      Code
      EOF"


gcloud compute instances create www-4 \
    --image-family debian-11 \
    --image-project debian-cloud \
    --zone $ZONE2 \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      Code
      EOF"


gcloud compute firewall-rules create www-firewall \
    --target-tags http-tag --allow tcp:80

gcloud compute instances list

gcloud compute addresses create lb-ip-cr \
    --ip-version=IPV4 \
    --global


gcloud compute instance-groups unmanaged create $REGION1-resources-w --zone $ZONE1

gcloud compute instance-groups unmanaged create $REGION2-resources-w --zone $ZONE2


gcloud compute instance-groups unmanaged add-instances $REGION1-resources-w \
    --instances www-1,www-2 \
    --zone $ZONE1

gcloud compute instance-groups unmanaged add-instances $REGION2-resources-w \
    --instances www-3,www-4 \
    --zone $ZONE2

gcloud compute health-checks create http http-basic-check


gcloud compute instance-groups unmanaged set-named-ports $REGION1-resources-w \
    --named-ports http:80 \
    --zone $ZONE1

gcloud compute instance-groups unmanaged set-named-ports $REGION2-resources-w \
    --named-ports http:80 \
    --zone $ZONE2


gcloud compute backend-services create web-map-backend-service \
    --protocol HTTP \
    --health-checks http-basic-check \
    --global


gcloud compute backend-services add-backend web-map-backend-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group $REGION1-resources-w \
    --instance-group-zone $ZONE1 \
    --global

gcloud compute backend-services add-backend web-map-backend-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group $REGION2-resources-w \
    --instance-group-zone $ZONE2 \
    --global

gcloud compute url-maps create web-map \
    --default-service web-map-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map

gcloud compute addresses list


EXTERNAL_IP=$(gcloud compute addresses list --format="get(ADDRESS)")

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT}" 
echo -e "${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
    gcloud compute forwarding-rules create http-cr-rule \
    --address $EXTERNAL_IP \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80
