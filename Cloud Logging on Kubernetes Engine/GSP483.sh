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

gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)
gcloud config set project $DEVSHELL_PROJECT_ID

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

git clone https://github.com/GoogleCloudPlatform/gke-logging-sinks-demo

sleep 10

cd gke-logging-sinks-demo

sleep 10

sed -i 's/  version = "~> 2.11.0"/  version = "~> 2.19.0"/g' terraform/provider.tf

sed -i 's/  filter      = "resource.type = container"/  filter      = "resource.type = k8s_container"/g' terraform/main.tf

make create
make validate

gcloud logging read "resource.type=k8s_container AND resource.labels.cluster_name=stackdriver-logging" --project=$PROJECT_ID

# run the specific query
gcloud logging read "resource.type=k8s_container AND resource.labels.cluster_name=stackdriver-logging" --project=$PROJECT_ID --format=json



gcloud logging sinks create techcps \
    bigquery.googleapis.com/projects/$PROJECT_ID/datasets/bq_logs \
    --log-filter='resource.type="k8s_container" 
resource.labels.cluster_name="stackdriver-logging"' \
    --include-children \
    --format='json'


sleep 20



bq query --use_legacy_sql=false \
"
SELECT * FROM \`$DEVSHELL_PROJECT_ID.gke_logs_dataset.diagnostic_log_*\`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', CURRENT_DATE() - INTERVAL 1 DAY) AND FORMAT_DATE('%Y%m%d', CURRENT_DATE()) 
"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT}" 
echo -e "${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
