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
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 1: Detecting your project region configuration...${RESET_FORMAT}"
echo
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Region not found in project metadata${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}Please enter your desired region:${RESET_FORMAT}"
  read -p "${WHITE_TEXT}${BOLD_TEXT}Region: ${RESET_FORMAT}" REGION
  export REGION
fi

echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Region detected: ${REGION}${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 2: Enabling SQL Admin API service...${RESET_FORMAT}"
echo

gcloud services enable sqladmin.googleapis.com

echo "${GREEN_TEXT}${BOLD_TEXT}✅ SQL Admin API successfully enabled!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 3: Creating Cloud SQL instance...${RESET_FORMAT}"
echo

gcloud sql instances create my-instance --project=$DEVSHELL_PROJECT_ID --region=$REGION --database-version=MYSQL_5_7 --tier=db-n1-standard-1

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud SQL instance 'my-instance' created successfully!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 4: Creating MySQL database...${RESET_FORMAT}"
echo

gcloud sql databases create mysql-db --instance=my-instance --project=$DEVSHELL_PROJECT_ID

echo "${GREEN_TEXT}${BOLD_TEXT}✅ MySQL database created successfully!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 5: Setting up BigQuery dataset...${RESET_FORMAT}"
echo

bq mk --dataset $DEVSHELL_PROJECT_ID:mysql_db

echo "${GREEN_TEXT}${BOLD_TEXT}✅ BigQuery dataset established!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 6: Creating BigQuery table structure...${RESET_FORMAT}"
echo

bq query --use_legacy_sql=false \
"CREATE TABLE \`${DEVSHELL_PROJECT_ID}.mysql_db.info\` (
  name STRING,
  age INT64,
  occupation STRING
);"

echo "${GREEN_TEXT}${BOLD_TEXT}✅ BigQuery table schema created!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 7: Generating sample data file...${RESET_FORMAT}"
echo

cat > employee_info.csv <<EOF_CP
"Sean", 23, "Content Creator"
"Emily", 34, "Cloud Engineer"
"Rocky", 40, "Event coordinator"
"Kate", 28, "Data Analyst"
"Juan", 51, "Program Manager"
"Jennifer", 32, "Web Developer"
EOF_CP

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Sample data file generated!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 8: Creating Cloud Storage bucket...${RESET_FORMAT}"
echo

gsutil mb gs://$DEVSHELL_PROJECT_ID

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Storage bucket created successfully!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 9: Uploading data to Cloud Storage...${RESET_FORMAT}"
echo

gsutil cp employee_info.csv gs://$DEVSHELL_PROJECT_ID/

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Data file uploaded to storage!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 10: Configuring service account permissions...${RESET_FORMAT}"
echo

SERVICE_EMAIL=$(gcloud sql instances describe my-instance --format="value(serviceAccountEmailAddress)")

gsutil iam ch serviceAccount:$SERVICE_EMAIL:roles/storage.admin gs://$DEVSHELL_PROJECT_ID/

echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud SQL and BigQuery setup completed successfully!${RESET_FORMAT}"
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
