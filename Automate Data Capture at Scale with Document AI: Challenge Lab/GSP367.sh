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

echo -n "${MAGENTA_TEXT}${BOLD_TEXT}Enter the processor name: ${RESET_FORMAT}"
read -r PROCESSOR
export PROCESSOR
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Gathering your Google Cloud project details...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value core/project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export ZONE=$(gcloud compute instances list lab-vm --format 'csv[no-heading](zone)')
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
export BUCKET_LOCATION=$REGION
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Project details fetched successfully!${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Enabling necessary Google Cloud APIs... This might take a moment.${RESET_FORMAT}"
gcloud services enable documentai.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable geocoding-backend.googleapis.com
gcloud services enable eventarc.googleapis.com
gcloud services enable run.googleapis.com
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Required services enabled.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📁 Creating a local directory and copying required files...${RESET_FORMAT}"
  mkdir ./document-ai-challenge
  gsutil -m cp -r gs://spls/gsp367/* \
    ~/document-ai-challenge/
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Local environment setup complete.${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🤖 Creating the Document AI processor named '$PROCESSOR'...${RESET_FORMAT}"
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"$PROCESSOR"'",
    "type": "FORM_PARSER_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Processor creation initiated.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🪣 Creating Cloud Storage buckets for invoices...${RESET_FORMAT}"
gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
 gs://${PROJECT_ID}-input-invoices
gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
 gs://${PROJECT_ID}-output-invoices
gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
 gs://${PROJECT_ID}-archived-invoices
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud Storage buckets created.${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}📊 Setting up BigQuery dataset and table for results...${RESET_FORMAT}"
bq --location="US" mk  -d \
    --description "Form Parser Results" \
    ${PROJECT_ID}:invoice_parser_results

cd ~/document-ai-challenge/scripts/table-schema/

bq mk --table \
invoice_parser_results.doc_ai_extracted_entities \
doc_ai_extracted_entities.json

cd ~/document-ai-challenge/scripts
echo "${GREEN_TEXT}${BOLD_TEXT}✅ BigQuery resources configured.${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🔑 Granting necessary IAM permissions for interactions...${RESET_FORMAT}"
SERVICE_ACCOUNT=$(gcloud storage service-agent --project=$PROJECT_ID)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher
echo "${GREEN_TEXT}${BOLD_TEXT}✅ IAM permissions granted.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Deploying the Cloud Function to process invoices... Please wait.${RESET_FORMAT}"
export CLOUD_FUNCTION_LOCATION=$REGION

total_seconds=20
bar_width=40 

echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Preparing for deployment (${total_seconds}s wait):${RESET_FORMAT}"

for i in $(seq $total_seconds); do
  elapsed_seconds=$i
  percentage=$(( (i * 100) / total_seconds ))

  completed_width=$(( (i * bar_width) / total_seconds ))
  remaining_width=$(( bar_width - completed_width ))

  bar=$(printf "%${completed_width}s" "" | tr ' ' '#')
  empty=$(printf "%${remaining_width}s" "")

  echo -ne "${YELLOW_TEXT}[${bar}${empty}] ${percentage}%% | ${elapsed_seconds}s / ${total_seconds}s ${RESET_FORMAT}\r"

  sleep 1
done

echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Preparation complete. Starting deployment...${RESET_FORMAT}"

deploy_function() {
gcloud functions deploy process-invoices \
  --gen2 \
  --region=${CLOUD_FUNCTION_LOCATION} \
  --entry-point=process_invoice \
  --runtime=python39 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --env-vars-file=cloud-functions/process-invoices/.env.yaml \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize\
  --service-account $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --allow-unauthenticated
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Attempting Cloud Function deployment...${RESET_FORMAT}"
  if deploy_function; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud Function deployed successfully!${RESET_FORMAT}"
    deploy_success=true
  else
    echo "${RED_TEXT}${BOLD_TEXT}❌ Deployment failed. Retrying...${RESET_FORMAT}"
    retry_seconds=30
    retry_bar_width=40
    echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Retrying in ${retry_seconds} seconds:${RESET_FORMAT}"
    for i in $(seq $retry_seconds); do
      elapsed_seconds=$i
      remaining_seconds=$(( retry_seconds - i ))
      percentage=$(( (i * 100) / retry_seconds ))

      completed_width=$(( (i * retry_bar_width) / retry_seconds ))
      remaining_width=$(( retry_bar_width - completed_width ))

      bar=$(printf "%${completed_width}s" "" | tr ' ' '#')
      empty=$(printf "%${remaining_width}s" "")

      echo -ne "${YELLOW_TEXT}[${bar}${empty}] ${percentage}%% | ${remaining_seconds}s remaining ${RESET_FORMAT}\r"

      sleep 1
    done
    echo 
  fi
done
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🆔 Fetching the ID of the created processor...${RESET_FORMAT}"
PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')

export PROCESSOR_ID
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Processor ID retrieved: ${PROCESSOR_ID}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Updating the Cloud Function with the Processor ID and other variables...${RESET_FORMAT}"
gcloud functions deploy process-invoices \
  --gen2 \
  --region=${CLOUD_FUNCTION_LOCATION} \
  --entry-point=process_invoice \
  --runtime=python39 \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize \
  --update-env-vars=PROCESSOR_ID=${PROCESSOR_ID},PARSER_LOCATION=us,PROJECT_ID=${PROJECT_ID} \
  --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud Function updated successfully.${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}📄 Uploading sample invoices to the input bucket to trigger processing...${RESET_FORMAT}"
gsutil -m cp -r gs://cloud-training/gsp367/* \
~/document-ai-challenge/invoices gs://${PROJECT_ID}-input-invoices/
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Sample invoices uploaded.${RESET_FORMAT}"
echo

remove_files
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
