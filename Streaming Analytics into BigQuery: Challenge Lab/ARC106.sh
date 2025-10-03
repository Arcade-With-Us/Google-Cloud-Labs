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

#!/bin/bash

# ==============================================================================
# Multi-Stage Dataflow Deployment Script
# This script creates all necessary resources (GCS, BQ, Pub/Sub) and runs two
# Dataflow jobs: one Flex Template and one Classic Template.
# ==============================================================================

# --- Color Definitions ---
# These are included from your original input for better terminal output
YELLOW_TEXT='\033[1;33m'
GREEN_TEXT='\033[1;32m'
BOLD_TEXT='\033[1m'
RESET_FORMAT='\033[0m'

echo "${GREEN_TEXT}${BOLD_TEXT}--- Dataflow Job Setup ---${RESET_FORMAT}"

# --- 1. User Input for Variables ---

read -r -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION (e.g., us-central1): ${RESET_FORMAT}" REGION
export REGION=$REGION

echo
read -r -p "${YELLOW_TEXT}${BOLD_TEXT}Enter DATASET name (e.g., iot_data): ${RESET_FORMAT}" DATASET
export DATASET=$DATASET

echo
read -r -p "${YELLOW_TEXT}${BOLD_TEXT}Enter TABLE name (e.g., temperature_logs): ${RESET_FORMAT}" TABLE
export TABLE=$TABLE

echo
read -r -p "${YELLOW_TEXT}${BOLD_TEXT}Enter TOPIC name (e.g., sensor_topic): ${RESET_FORMAT}" TOPIC
export TOPIC=$TOPIC

echo
read -r -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the primary JOB name (e.g., dfjob-1): ${RESET_FORMAT}" JOB
export JOB=$JOB

# --- 2. Automated Variable Setup ---

# Get the active project ID
export PROJECT_ID=$(gcloud config get-value project)

# Define the *hardcoded* GCS path for the Classic Template as required by the task
# Note: This is specifically for the second job in the script.
CLASSIC_TEMPLATE_PATH="gs://dataflow-templates-us-east4/latest/PubSub_to_BigQuery"

# --- 3. Resource Creation ---

echo
echo "${GREEN_TEXT}${BOLD_TEXT}--- Creating Resources: BQ, Pub/Sub, GCS ---${RESET_FORMAT}"

# Create GCS Bucket for Staging (Dataflow requires a bucket in the same project)
# Note: Using the PROJECT_ID as the bucket name prefix for uniqueness.
gsutil mb -l $REGION gs://$PROJECT_ID

# Create BigQuery Dataset
bq mk --dataset $DATASET

# Create BigQuery Table with a simple 'data' schema
bq mk --table \
$PROJECT_ID:$DATASET.$TABLE \
data:string

# Create Pub/Sub Topic and Subscription
gcloud pubsub topics create $TOPIC
gcloud pubsub subscriptions create $TOPIC-sub --topic=$TOPIC

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Starting Dataflow FLEX Template Job ========================== ${RESET_FORMAT}"
echo

# --- 4. Running First Job (FLEX Template) ---
# Note: Flex templates use '--template-file-gcs-location' and can use '--temp-location'
gcloud dataflow flex-template run $JOB --region $REGION \
--template-file-gcs-location gs://dataflow-templates-$REGION/latest/flex/PubSub_to_BigQuery_Flex \
--temp-location gs://$PROJECT_ID/temp/ \
--parameters outputTableSpec=$PROJECT_ID:$DATASET.$TABLE,\
inputTopic=projects/$PROJECT_ID/topics/$TOPIC,\
outputDeadletterTable=$PROJECT_ID:$DATASET.$TABLE,\
javascriptTextTransformReloadIntervalMinutes=0,\
useStorageWriteApi=false,\
useStorageWriteApiAtLeastOnce=false,\
numStorageWriteApiStreams=0

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Monitoring and Interacting with FLEX Dataflow Job ========================== ${RESET_FORMAT}"
echo

# --- 5. Monitoring First Job ---
while true; do
    # Filter for the specific job name and Running state
    STATUS=$(gcloud dataflow jobs list --region="$REGION" --filter="name:$JOB AND state:Running" --format='value(STATE)')
    
    if [ "$STATUS" == "RUNNING" ]; then
        echo "The FLEX Dataflow job ($JOB) is running successfully. Publishing test message..."

        sleep 20
        gcloud pubsub topics publish $TOPIC --message='{"data": "73.4 F"}'

        echo "Waiting 10 seconds for data to land in BigQuery..."
        sleep 10
        # Query BigQuery table to confirm data ingestion
        bq query --nouse_legacy_sql "SELECT * FROM \`$PROJECT_ID.$DATASET.$TABLE\` LIMIT 1"

        break
    else
        sleep 30
        echo "The FLEX Dataflow job ($JOB) is not running yet, waiting 30 seconds..."
    fi
done

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Starting Second Dataflow Job (CLASSIC TEMPLATE) ========================== ${RESET_FORMAT}"
echo

# --- 6. Running Second Job (CLASSIC Template) ---
# This uses the hardcoded path (CLASSIC_TEMPLATE_PATH) as specified in your initial task
# Note: Classic templates use '--gcs-location' and only require '--staging-location'
gcloud dataflow jobs run $JOB-arcadewithus \
    --gcs-location $CLASSIC_TEMPLATE_PATH \
    --region $REGION \
    --staging-location gs://$PROJECT_ID/temp \
    --parameters inputTopic=projects/$PROJECT_ID/topics/$TOPIC,outputTableSpec=$PROJECT_ID:$DATASET.$TABLE

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Monitoring and Interacting with CLASSIC Dataflow Job ========================== ${RESET_FORMAT}"
echo

# --- 7. Monitoring Second Job ---
while true; do
    # Filter for the specific job name and Running state
    STATUS=$(gcloud dataflow jobs list --region=$REGION --filter="name:$JOB-arcadewithus AND state:Running" --format="value(state)")
    
    if [ "$STATUS" == "RUNNING" ]; then
        echo "The CLASSIC Dataflow job ($JOB-arcadewithus) is running successfully. Publishing test message..."

        sleep 20
        gcloud pubsub topics publish $TOPIC --message='{"data": "74.0 F"}'

        echo "Waiting 10 seconds for data to land in BigQuery..."
        sleep 10
        # Query BigQuery table to confirm data ingestion
        bq query --nouse_legacy_sql "SELECT * FROM \`$PROJECT_ID.$DATASET.$TABLE\` LIMIT 3"
        
        break
    else
        sleep 30
        echo "The CLASSIC Dataflow job ($JOB-arcadewithus) is not running yet, waiting 30 seconds..."
    fi
done

echo
echo "${GREEN_TEXT}${BOLD_TEXT}--- Script Finished. All Dataflow jobs are running and tested. ---${RESET_FORMAT}"

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
