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

#Extracting region
echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Enter REGION: ${RESET_FORMAT}"
read -r REGION
export REGION=$REGION
echo "${BLUE_TEXT}${BOLD_TEXT} User selected region : $REGION ${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Disabling Dataflow API ========================== ${RESET_FORMAT}"
echo

gcloud services disable dataflow.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Enabling Dataflow API ========================== ${RESET_FORMAT}"
echo
gcloud services enable dataflow.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating BigQuery Dataset ========================== ${RESET_FORMAT}"
echo

bq mk taxirides

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating BigQuery Table ========================== ${RESET_FORMAT}"
echo

bq mk \
--time_partitioning_field timestamp \
--schema ride_id:string,point_idx:integer,latitude:float,longitude:float,\
timestamp:timestamp,meter_reading:float,meter_increment:float,ride_status:string,\
passenger_count:integer -t taxirides.realtime

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating GCS Bucket ========================== ${RESET_FORMAT}"
echo

gsutil mb gs://$DEVSHELL_PROJECT_ID/

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Waiting for 45 seconds to finish GCS creation ========================== ${RESET_FORMAT}"
echo

sleep 45

check_job_status() {
    while true; do
        JOB_STATUS=$(gcloud dataflow jobs list --region "$REGION" --filter="name=iotflow" --format="value(state)")
        
        if [[ "$JOB_STATUS" == "Running" ]]; then
            echo "${GREEN_TEXT}${BOLD_TEXT} Dataflow job is running successfully! ${RESET_FORMAT}"
            return 0
        elif [[ "$JOB_STATUS" == "Failed" || "$JOB_STATUS" == "Cancelled" ]]; then
            echo "${RED_TEXT}${BOLD_TEXT} Dataflow job failed! Retrying... ${RESET_FORMAT}"
            return 1
        fi
        
        echo "Waiting for job to complete..."
        sleep 20
    done
}

# Function to run Dataflow job
run_dataflow_job() {
    echo
    echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Running Dataflow Job ========================== ${RESET_FORMAT}"
    echo

    JOB_ID=$(gcloud dataflow jobs run iotflow \
    --gcs-location gs://dataflow-templates/latest/PubSub_to_BigQuery \
    --region "$REGION" \
    --staging-location gs://$DEVSHELL_PROJECT_ID/temp \
    --parameters inputTopic=projects/pubsub-public-data/topics/taxirides-realtime,outputTableSpec=$DEVSHELL_PROJECT_ID:taxirides.realtime \
    --format="value(id)")

    echo "Dataflow Job ID: $JOB_ID"
    sleep 30  # Give it some time to start
}

# Run job and check status in a loop
while true; do
    run_dataflow_job
    check_job_status

    if [[ $? -eq 0 ]]; then
        break
    else
        echo "${YELLOW_TEXT}${BOLD_TEXT} Deleting failed Dataflow job... ${RESET_FORMAT}"
        gcloud dataflow jobs cancel iotflow --region "$REGION"
        echo "${YELLOW_TEXT}${BOLD_TEXT} Retrying Dataflow job... ${RESET_FORMAT}"
        sleep 10
    fi
done
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
