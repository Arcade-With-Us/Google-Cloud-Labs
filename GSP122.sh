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

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the Zone: ${RESET_FORMAT}" ZONE
export ZONE

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a VM instance named 'lol' in the specified zone...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This may take a few moments. Please wait.${RESET_FORMAT}"
echo

gcloud compute instances create lol --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=lol,image=projects/centos-cloud/global/images/centos-7-v20231010,mode=rw,size=20,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Waiting for the VM instance to be ready...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This will take approximately 30 seconds.${RESET_FORMAT}"
echo

sleep 30

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Connecting to the VM instance via SSH to configure Google Cloud SDK...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Please wait while the necessary packages are installed.${RESET_FORMAT}"
echo

gcloud compute ssh lol --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="\
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

sudo yum install google-cloud-sdk -y

gcloud init --console-only
"

echo
echo "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
