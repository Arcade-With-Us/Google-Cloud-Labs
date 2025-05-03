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
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📋 Step 1: Fetching your GCP Project ID and GCP Project Number...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
  --format="value(projectNumber)")

echo "${BLUE_TEXT}${BOLD_TEXT}🌍 Step 2: Determining the default compute zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Step 3: Enabling the Identity-Aware Proxy (IAP) API...${RESET_FORMAT}"
gcloud services enable iap.googleapis.com

echo "${GREEN_TEXT}${BOLD_TEXT}🖥️ Step 4: Creating the 'linux-iap' VM instance...${RESET_FORMAT}"
gcloud compute instances create linux-iap \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=stack-type=IPV4_ONLY,subnet=default,no-address

echo "${GREEN_TEXT}${BOLD_TEXT}🪟 Step 5: Creating the 'windows-iap' VM instance...${RESET_FORMAT}"
gcloud compute instances create windows-iap \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=stack-type=IPV4_ONLY,subnet=default,no-address \
  --create-disk=auto-delete=yes,boot=yes,device-name=windows-iap,image=projects/windows-cloud/global/images/windows-server-2016-dc-v20240313,mode=rw,size=50,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-standard \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

echo "${GREEN_TEXT}${BOLD_TEXT}🔗 Step 6: Creating the 'windows-connectivity' VM instance...${RESET_FORMAT}"
gcloud compute instances create windows-connectivity \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --create-disk=auto-delete=yes,boot=yes,device-name=windows-connectivity,image=projects/qwiklabs-resources/global/images/iap-desktop-v001,mode=rw,size=50,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-standard \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

echo "${BLUE_TEXT}${BOLD_TEXT}🛡️ Step 7: Creating a firewall rule to allow IAP traffic (SSH & RDP)...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-ingress-from-iap \
  --network default \
  --allow tcp:22,tcp:3389 \
  --source-ranges 35.235.240.0/20

echo

echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"

echo
echo -e "${BLUE_TEXT}${BOLD_TEXT}🔗 Firewall Rule Link: ${UNDERLINE_TEXT}https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/details/allow-ingress-from-iap?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo
echo -e "${BLUE_TEXT}${BOLD_TEXT}🔗 IAP Settings Link: ${UNDERLINE_TEXT}https://console.cloud.google.com/security/iap?tab=ssh-tcp-resources&project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo
echo
echo -e "${CYAN_TEXT}${BOLD_TEXT}👤 Service Account Email: $PROJECT_NUMBER-compute@developer.gserviceaccount.com${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 If you found this helpful, please subscribe to Arcade With Us! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
