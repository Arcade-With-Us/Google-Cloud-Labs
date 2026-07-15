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

echo "${CYAN_TEXT}${BOLD_TEXT}Creating mute rules for Security Command Center findings...${RESET_FORMAT}"

gcloud scc muteconfigs create muting-flow-log-findings \
  --project=$DEVSHELL_PROJECT_ID \
  --location=global \
  --description="Rule for muting VPC Flow Logs" \
  --filter="category=\"FLOW_LOGS_DISABLED\"" \
  --type=STATIC

gcloud scc muteconfigs create muting-audit-logging-findings \
  --project=$DEVSHELL_PROJECT_ID \
  --location=global \
  --description="Rule for muting audit logs" \
  --filter="category=\"AUDIT_LOGGING_DISABLED\"" \
  --type=STATIC

gcloud scc muteconfigs create muting-admin-sa-findings \
  --project=$DEVSHELL_PROJECT_ID \
  --location=global \
  --description="Rule for muting admin service account findings" \
  --filter="category=\"ADMIN_SERVICE_ACCOUNT\"" \
  --type=STATIC

echo
echo "${GREEN_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              CHECK SCORE FOR TASK 2              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"
echo

gcloud compute firewall-rules delete default-allow-rdp

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating updated RDP firewall rule...${RESET_FORMAT}"
gcloud compute firewall-rules create default-allow-rdp \
  --source-ranges=35.235.240.0/20 \
  --allow=tcp:3389 \
  --description="Allow HTTP traffic from 35.235.240.0/20" \
  --priority=65534

echo "${YELLOW_TEXT}${BOLD_TEXT}Deleting default SSH firewall rule...${RESET_FORMAT}"
gcloud compute firewall-rules delete default-allow-ssh --quiet

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating updated SSH firewall rule...${RESET_FORMAT}"
gcloud compute firewall-rules create default-allow-ssh \
  --source-ranges=35.235.240.0/20 \
  --allow=tcp:22 \
  --description="Allow HTTP traffic from 35.235.240.0/20" \
  --priority=65534

echo "${CYAN_TEXT}${BOLD_TEXT}Fetching your VM's zone info...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo "${CYAN_TEXT}${BOLD_TEXT}OPEN THIS LINK: ${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/compute/instancesEdit/zones/$ZONE/instances/cls-vm?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}              NOW FOLLOW VIDEO ..              ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"
echo

read -p "${RED_TEXT}${BOLD_TEXT}Have you followed the video steps (Y/N)? ${RESET_FORMAT}" response
if [[ "$response" =~ ^[Yy]$ ]]; then
  echo "${GREEN_TEXT}${BOLD_TEXT}Great! Let's proceed.${RESET_FORMAT}"
else
  echo "${RED_TEXT}${BOLD_TEXT}Please follow the video steps before continuing.${RESET_FORMAT}"
fi

echo

echo "${CYAN_TEXT}${BOLD_TEXT}Setting up environment variables for REGION and VM External IP...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

export VM_EXT_IP=$(gcloud compute instances describe cls-vm --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a Cloud Storage bucket for findings export...${RESET_FORMAT}"
gsutil mb -p $DEVSHELL_PROJECT_ID -c STANDARD -l $REGION -b on gs://scc-export-bucket-$DEVSHELL_PROJECT_ID

echo "${MAGENTA_TEXT}${BOLD_TEXT}Disabling uniform bucket-level access...${RESET_FORMAT}"
gsutil uniformbucketlevelaccess set off gs://scc-export-bucket-$DEVSHELL_PROJECT_ID

echo "${CYAN_TEXT}${BOLD_TEXT}Downloading findings.jsonl file...${RESET_FORMAT}"
curl -LO https://raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Mitigate%20Threats%20and%20Vulnerabilities%20with%20Security%20Command%20Center%3A%20Challenge%20Lab/findings.jsonl
echo "${CYAN_TEXT}${BOLD_TEXT}Uploading findings.jsonl to the bucket...${RESET_FORMAT}"
gsutil cp findings.jsonl gs://scc-export-bucket-$DEVSHELL_PROJECT_ID

echo "${CYAN_TEXT}${BOLD_TEXT}OPEN THIS LINK: ${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/security/web-scanner/scanConfigs/edit?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}COPY THIS: ${RESET}${GREEN_TEXT}${BOLD_TEXT}http://$VM_EXT_IP:8080${RESET_FORMAT}"

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
