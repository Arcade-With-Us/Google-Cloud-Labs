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

ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

PROJECT_ID=$(gcloud config get-value project)

export PROJECT_NUMBER="$(gcloud projects list \
  --filter=$(gcloud config get-value project) \
  --format='value(PROJECT_NUMBER)')"


echo ""
echo ""
echo "Please export the values."


# ───────────────────────────────────────────────────────────────
# User Input
# ───────────────────────────────────────────────────────────────

# Prompt user to input three regions
read -p "Enter PROCESSOR_NAME: " PROCESSOR_NAME
# read -p "Enter REGION: " REGION



# ═══════════════════════════════════════════════════════════════
#                            TASK 1
# ═══════════════════════════════════════════════════════════════

export BUCKET_LOCATION=$REGION
export PROJECT_ID=$(gcloud config get-value core/project)

gcloud services enable documentai.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable geocoding-backend.googleapis.com
gcloud services enable eventarc.googleapis.com
gcloud services enable run.googleapis.com

mkdir ./document-ai-challenge

gsutil -m cp -r gs://spls/gsp367/* \
~/document-ai-challenge/



# ═══════════════════════════════════════════════════════════════
#                            TASK 2
# ═══════════════════════════════════════════════════════════════

ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"$PROCESSOR_NAME"'",
    "type": "FORM_PARSER_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors"


gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
 gs://${PROJECT_ID}-input-invoices

gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
 gs://${PROJECT_ID}-output-invoices

gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
 gs://${PROJECT_ID}-archived-invoices



# ═══════════════════════════════════════════════════════════════
#                            TASK 3
# ═══════════════════════════════════════════════════════════════

# Set Project ID (safe to run even if already set)
export PROJECT_ID=$(gcloud config get-value project)


# ───────────────────────────────────────────────────────────────
# Create Cloud Storage Buckets
# ───────────────────────────────────────────────────────────────

gcloud storage buckets create gs://${PROJECT_ID}-input-invoices \
    --location=us-east1 \
    --default-storage-class=STANDARD \
    --uniform-bucket-level-access

gcloud storage buckets create gs://${PROJECT_ID}-output-invoices \
    --location=us-east1 \
    --default-storage-class=STANDARD \
    --uniform-bucket-level-access

gcloud storage buckets create gs://${PROJECT_ID}-archived-invoices \
    --location=us-east1 \
    --default-storage-class=STANDARD \
    --uniform-bucket-level-access


# ───────────────────────────────────────────────────────────────
# Create BigQuery Dataset
# ───────────────────────────────────────────────────────────────

bq --location="US" mk -d \
    --description "Form Parser Results" \
    ${PROJECT_ID}:invoice_parser_results


# ───────────────────────────────────────────────────────────────
# Move to Schema Directory
# ───────────────────────────────────────────────────────────────

cd ~/documentai-pipeline-demo/scripts/table-schema/


# ───────────────────────────────────────────────────────────────
# Create BigQuery Tables
# ───────────────────────────────────────────────────────────────

bq mk --table \
invoice_parser_results.doc_ai_extracted_entities \
doc_ai_extracted_entities.json

bq mk --table \
invoice_parser_results.geocode_details \
geocode_details.json


# ───────────────────────────────────────────────────────────────
# Verify Resources
# ───────────────────────────────────────────────────────────────

echo "=== Buckets ==="
gcloud storage buckets list

echo "=== BigQuery Dataset ==="
bq ls

echo "=== Tables ==="
bq ls invoice_parser_results



# ═══════════════════════════════════════════════════════════════
#                            TASK 4
# ═══════════════════════════════════════════════════════════════

cd ~/document-ai-challenge/scripts

export PROJECT_ID=$(gcloud config get-value core/project)

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')


# ───────────────────────────────────────────────────────────────
# Grant Artifact Registry Reader Role
# ───────────────────────────────────────────────────────────────

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"


# ───────────────────────────────────────────────────────────────
# Configure Service Accounts
# ───────────────────────────────────────────────────────────────

SERVICE_ACCOUNT=$(gcloud storage service-agent --project=$PROJECT_ID)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"


export CLOUD_FUNCTION_LOCATION=$REGION

sleep 20


# ───────────────────────────────────────────────────────────────
# Deploy Cloud Function
# ───────────────────────────────────────────────────────────────

deploy_function() {

  gcloud functions deploy process-invoices \
    --gen2 \
    --region=${CLOUD_FUNCTION_LOCATION} \
    --entry-point=process_invoice \
    --runtime=python313 \
    --source=cloud-functions/process-invoices \
    --timeout=400 \
    --env-vars-file=cloud-functions/process-invoices/.env.yaml \
    --trigger-resource=gs://${PROJECT_ID}-input-invoices \
    --trigger-event=google.storage.object.finalize \
    --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --allow-unauthenticated
}


deploy_success=false


# ───────────────────────────────────────────────────────────────
# Retry Deployment Until Successful
# ───────────────────────────────────────────────────────────────

while [ "$deploy_success" = false ]; do

  if deploy_function; then

    deploy_success=true

  else

    sleep 10

  fi

done



# ───────────────────────────────────────────────────────────────
# Retrieve Processor ID
# ───────────────────────────────────────────────────────────────

# Run the curl command and use grep and sed to extract the processor ID
PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')


# Export the variable
PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')


# ───────────────────────────────────────────────────────────────
# Redeploy Cloud Function with Processor Configuration
# ───────────────────────────────────────────────────────────────

gcloud functions deploy process-invoices \
  --gen2 \
  --region=${CLOUD_FUNCTION_LOCATION} \
  --entry-point=process_invoice \
  --runtime=python313 \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize \
  --update-env-vars=PROCESSOR_ID=${PROCESSOR_ID},PARSER_LOCATION=us,PROJECT_ID=${PROJECT_ID} \
  --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com



# ═══════════════════════════════════════════════════════════════
#                   TASK 5 — TEST & VALIDATE
# ═══════════════════════════════════════════════════════════════

# Test and validate the end-to-end solution

export PROJECT_ID=$(gcloud config get-value core/project)

gsutil -m cp -r gs://cloud-training/gsp367/* \
~/document-ai-challenge/invoices gs://${PROJECT_ID}-input-invoices/

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
