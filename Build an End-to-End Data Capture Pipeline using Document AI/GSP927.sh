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

echo "${GREEN_TEXT}${BOLD_TEXT}🔧 Setting up essential environment variables...${RESET_FORMAT}"
export PROCESSOR_NAME=form-processor
echo "${GREEN_TEXT}${BOLD_TEXT}🔍 Fetching your Google Cloud Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value core/project)
echo "${GREEN_TEXT}${BOLD_TEXT}🔢 Retrieving your Project Number...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Determining the default Google Cloud region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export GEO_CODE_REQUEST_PUBSUB_TOPIC=geocode_request
export BUCKET_LOCATION=$REGION
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Environment variables set successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Creating Google Cloud Storage buckets for invoices...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}📥 Creating bucket for input invoices...${RESET_FORMAT}"
gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
  gs://${PROJECT_ID}-input-invoices
echo "${YELLOW_TEXT}${BOLD_TEXT}📤 Creating bucket for output invoices...${RESET_FORMAT}"
gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
  gs://${PROJECT_ID}-output-invoices
echo "${YELLOW_TEXT}${BOLD_TEXT}🗄️ Creating bucket for archived invoices...${RESET_FORMAT}"
gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
  gs://${PROJECT_ID}-archived-invoices
echo "${YELLOW_TEXT}${BOLD_TEXT}✅ Buckets created!${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Enabling necessary Google Cloud services...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}📄 Enabling Document AI API...${RESET_FORMAT}"
gcloud services enable documentai.googleapis.com
echo "${BLUE_TEXT}${BOLD_TEXT}☁️ Enabling Cloud Functions API...${RESET_FORMAT}"
gcloud services enable cloudfunctions.googleapis.com
echo "${BLUE_TEXT}${BOLD_TEXT}🏗️ Enabling Cloud Build API...${RESET_FORMAT}"
gcloud services enable cloudbuild.googleapis.com
echo "${BLUE_TEXT}${BOLD_TEXT}🗺️ Enabling Geocoding API...${RESET_FORMAT}"
gcloud services enable geocoding-backend.googleapis.com
echo "${BLUE_TEXT}${BOLD_TEXT}✅ Services enabled!${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🔑 Generating a new API key named 'arcadecrew'...${RESET_FORMAT}"
gcloud alpha services api-keys create --display-name="arcadecrew"
echo "${MAGENTA_TEXT}${BOLD_TEXT}✅ API key created!${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🏷️ Retrieving the name of the newly created API key...${RESET_FORMAT}"
export KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=arcadecrew")
echo "${CYAN_TEXT}${BOLD_TEXT}🗝️ Fetching the actual API key string...${RESET_FORMAT}"
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
echo "${CYAN_TEXT}${BOLD_TEXT}✅ API key details retrieved!${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}🔒 Restricting the API key usage to only the Geocoding API...${RESET_FORMAT}"
curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "restrictions": {
      "apiTargets": [
        {
          "service": "geocoding-backend.googleapis.com"
        }
      ]
    }
  }' \
  "https://apikeys.googleapis.com/v2/$KEY_NAME?updateMask=restrictions"
echo
echo "${RED_TEXT}${BOLD_TEXT}✅ API key restrictions applied!${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📁 Creating a local directory for demo assets...${RESET_FORMAT}"
mkdir ./documentai-pipeline-demo
echo "${GREEN_TEXT}${BOLD_TEXT}📥 Copying demo assets from Cloud Storage to the local directory...${RESET_FORMAT}"
gcloud storage cp -r \
  gs://spls/gsp927/documentai-pipeline-demo/* \
  ~/documentai-pipeline-demo/
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Demo assets copied!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🤖 Creating a new Document AI Form Parser Processor...${RESET_FORMAT}"
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"$PROCESSOR_NAME"'",
    "type": "FORM_PARSER_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}✅ Document AI Processor created!${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📊 Creating BigQuery dataset and tables for storing results...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}💾 Creating the 'invoice_parser_results' dataset...${RESET_FORMAT}"
bq --location="US" mk  -d \
    --description "Form Parser Results" \
    ${PROJECT_ID}:invoice_parser_results
echo "${BLUE_TEXT}${BOLD_TEXT}🧭 Changing directory to access table schemas...${RESET_FORMAT}"
cd ~/documentai-pipeline-demo/scripts/table-schema/
echo "${BLUE_TEXT}${BOLD_TEXT}📄 Creating the 'doc_ai_extracted_entities' table...${RESET_FORMAT}"
bq mk --table \
  invoice_parser_results.doc_ai_extracted_entities \
  doc_ai_extracted_entities.json
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Creating the 'geocode_details' table...${RESET_FORMAT}"
bq mk --table \
  invoice_parser_results.geocode_details \
  geocode_details.json
echo "${BLUE_TEXT}${BOLD_TEXT}✅ BigQuery resources created!${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}📬 Creating a Pub/Sub topic for geocode requests...${RESET_FORMAT}"
gcloud pubsub topics \
  create ${GEO_CODE_REQUEST_PUBSUB_TOPIC}
echo "${MAGENTA_TEXT}${BOLD_TEXT}✅ Pub/Sub topic created!${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}👤 Creating a dedicated service account for interactions...${RESET_FORMAT}"
gcloud iam service-accounts create "service-$PROJECT_NUMBER" \
  --display-name "Cloud Storage Service Account" || true
echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Granting Pub/Sub Publisher role to the service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"
echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Granting Service Account Token Creator role...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"
echo "${CYAN_TEXT}${BOLD_TEXT}✅ Service account created and roles assigned!${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}📁 Navigating to the scripts directory for Cloud Function deployment...${RESET_FORMAT}"
  cd ~/documentai-pipeline-demo/scripts
  export CLOUD_FUNCTION_LOCATION=$REGION
echo "${RED_TEXT}${BOLD_TEXT}✅ Changed directory successfully!${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Deploying the 'process-invoices' Cloud Function (will retry if needed)...${RESET_FORMAT}"
deploy_function_until_success() {
while true; do
    echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Attempting to deploy 'process-invoices'... Please wait.${RESET_FORMAT}"
    gcloud functions deploy process-invoices \
      --no-gen2 \
      --region="${CLOUD_FUNCTION_LOCATION}" \
      --entry-point=process_invoice \
      --runtime=python39 \
      --source=cloud-functions/process-invoices \
      --timeout=400 \
      --env-vars-file=cloud-functions/process-invoices/.env.yaml \
      --trigger-resource="gs://${PROJECT_ID}-input-invoices" \
      --trigger-event=google.storage.object.finalize

    if [ $? -eq 0 ]; then
      echo "${BLUE_TEXT}${BOLD_TEXT}✅ Cloud Function 'process-invoices' deployed successfully!${RESET_FORMAT}"
      break
    else
      echo "${RED_TEXT}${BOLD_TEXT}❌ Deployment failed. Retrying...${RESET_FORMAT}"
      # Countdown timer
      for i in {30..1}; do
        printf "${YELLOW_TEXT}   Retrying in %2d seconds... \r${RESET_FORMAT}" "$i"
        sleep 1
      done
      printf "                           \r"
    fi
  done
}

deploy_function_until_success
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🚀 Deploying the 'geocode-addresses' Cloud Function (will retry if needed)...${RESET_FORMAT}"
deploy_geocode_addresses_until_success() {
  while true; do
    echo "${CYAN_TEXT}${BOLD_TEXT}⏳ Attempting to deploy 'geocode-addresses'... Please wait.${RESET_FORMAT}"

    gcloud functions deploy geocode-addresses \
      --no-gen2 \
      --region="${CLOUD_FUNCTION_LOCATION}" \
      --entry-point=process_address \
      --runtime=python39 \
      --source=cloud-functions/geocode-addresses \
      --timeout=60 \
      --env-vars-file=cloud-functions/geocode-addresses/.env.yaml \
      --trigger-topic="${GEO_CODE_REQUEST_PUBSUB_TOPIC}"

    if [ $? -eq 0 ]; then
      echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud Function 'geocode-addresses' deployed successfully!${RESET_FORMAT}"
      break
    else
      echo "${RED_TEXT}${BOLD_TEXT}❌ Deployment failed. Retrying...${RESET_FORMAT}"
      # Countdown timer
      for i in {30..1}; do
      printf "${YELLOW_TEXT}   Retrying in %2d seconds... \r${RESET_FORMAT}" "$i"
      sleep 1
      done
      printf "                           \r"
    fi
  done
}

deploy_geocode_addresses_until_success
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🆔 Fetching the ID of the created Document AI Processor...${RESET_FORMAT}"
PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')

export PROCESSOR_ID
echo "${YELLOW_TEXT}${BOLD_TEXT}✅ Processor ID retrieved: ${PROCESSOR_ID}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Re-deploying 'process-invoices' Cloud Function with updated environment variables (Processor ID)...${RESET_FORMAT}"
gcloud functions deploy process-invoices \
      --no-gen2 \
      --region="${CLOUD_FUNCTION_LOCATION}" \
      --entry-point=process_invoice \
      --runtime=python39 \
      --source=cloud-functions/process-invoices \
      --timeout=400 \
      --update-env-vars=PROCESSOR_ID=${PROCESSOR_ID},PARSER_LOCATION=us,GCP_PROJECT=${PROJECT_ID} \
      --trigger-resource=gs://${PROJECT_ID}-input-invoices \
      --trigger-event=google.storage.object.finalize
echo "${BLUE_TEXT}${BOLD_TEXT}✅ 'process-invoices' re-deployed successfully!${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🔄 Re-deploying 'geocode-addresses' Cloud Function with updated environment variables (API Key)...${RESET_FORMAT}"
gcloud functions deploy geocode-addresses \
      --no-gen2 \
      --region="${CLOUD_FUNCTION_LOCATION}" \
      --entry-point=process_address \
      --runtime=python39 \
      --source=cloud-functions/geocode-addresses \
      --timeout=60 \
      --update-env-vars=API_key=${API_KEY} \
      --trigger-topic=${GEO_CODE_REQUEST_PUBSUB_TOPIC}
echo "${MAGENTA_TEXT}${BOLD_TEXT}✅ 'geocode-addresses' re-deployed successfully!${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}📤 Uploading sample invoice files to the input bucket to trigger the pipeline...${RESET_FORMAT}"
gsutil cp gs://spls/gsp927/documentai-pipeline-demo/sample-files/* gs://${PROJECT_ID}-input-invoices/
echo "${CYAN_TEXT}${BOLD_TEXT}✅ Sample files uploaded! The pipeline should start processing now.${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 If you found this helpful, please subscribe to Arcade With Us! 👇${RESET_FORMAT}" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
