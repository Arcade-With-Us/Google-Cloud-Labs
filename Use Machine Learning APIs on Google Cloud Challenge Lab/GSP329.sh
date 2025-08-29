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

echo -e "${BOLD_MAGENTA}Please enter the following configuration details:${RESET}"
read -p "$(echo -e "${BOLD_YELLOW}ENTER LANGUAGE (e.g., en, fr, es): ${RESET}")" LANGUAGE
read -p "$(echo -e "${BOLD_YELLOW}ENTER LOCAL (e.g., en_US, fr_FR): ${RESET}")" LOCAL
read -p "$(echo -e "${BOLD_YELLOW}ENTER BIGQUERY_ROLE (e.g., roles/bigquery.admin): ${RESET}")" BIGQUERY_ROLE
read -p "$(echo -e "${BOLD_YELLOW}ENTER CLOUD_STORAGE_ROLE (e.g., roles/storage.admin): ${RESET}")" CLOUD_STORAGE_ROLE
echo ""

echo -e "${BOLD_BLUE}→ Creating service account 'sample-sa'...${RESET}"
gcloud iam service-accounts create sample-sa
echo ""

echo -e "${BOLD_BLUE}→ Assigning IAM roles to service account...${RESET}"
echo -e "${CYAN}  - BigQuery Role: ${BOLD_WHITE}$BIGQUERY_ROLE${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=$BIGQUERY_ROLE

echo -e "${CYAN}  - Cloud Storage Role: ${BOLD_WHITE}$CLOUD_STORAGE_ROLE${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=$CLOUD_STORAGE_ROLE

echo -e "${CYAN}  - Service Usage Consumer Role${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=roles/serviceusage.serviceUsageConsumer
echo ""

echo -e "${BOLD_BLUE}→ Waiting 2 minutes for IAM changes to propagate...${RESET}"
for i in {1..120}; do
    echo -ne "${YELLOW}${i}/120 seconds elapsed...\r${RESET}"
    sleep 1
done
echo -e "\n"

echo -e "${BOLD_BLUE}→ Creating service account key...${RESET}"
gcloud iam service-accounts keys create sample-sa-key.json --iam-account sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS=${PWD}/sample-sa-key.json
echo -e "${GREEN}✓ Key created and exported to environment${RESET}"
echo ""

echo -e "${BOLD_BLUE}→ Downloading image analysis script...${RESET}"
wget https://raw.githubusercontent.com/guys-in-the-cloud/cloud-skill-boosts/main/Challenge-labs/Integrate%20with%20Machine%20Learning%20APIs%3A%20Challenge%20Lab/analyze-images-v2.py
echo -e "${GREEN}✓ Script downloaded successfully${RESET}"
echo ""

echo -e "${BOLD_BLUE}→ Updating script locale to ${BOLD_WHITE}${LOCAL}${BOLD_BLUE}...${RESET}"
sed -i "s/'en'/'${LOCAL}'/g" analyze-images-v2.py
echo -e "${GREEN}✓ Locale updated successfully${RESET}"
echo ""

echo -e "${BOLD_BLUE}→ Running image analysis...${RESET}"
python3 analyze-images-v2.py
python3 analyze-images-v2.py $DEVSHELL_PROJECT_ID $DEVSHELL_PROJECT_ID
echo -e "${GREEN}✓ Image analysis completed${RESET}"
echo ""

echo -e "${BOLD_CYAN}→ Querying locale distribution from BigQuery...${RESET}"
bq query --use_legacy_sql=false "SELECT locale,COUNT(locale) as lcount FROM image_classification_dataset.image_text_detail GROUP BY locale ORDER BY lcount DESC"
echo ""

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
