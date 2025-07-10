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

# Set text styles
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)

echo "Please set the below values correctly"
read -p "${YELLOW}${BOLD}Enter the CLUSTER_NAME: ${RESET}" CLUSTER_NAME

# Export variables after collecting input
export CLUSTER_NAME 

gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")


PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/storage.admin"

sleep 60

#!/bin/bash

echo "$CLUSTER_NAME"
echo "$ZONE"
echo "$REGION"

cluster_function() {
  gcloud dataproc clusters create "$CLUSTER_NAME" \
    --region "$REGION" \
    --zone "$ZONE" \
    --master-machine-type n1-standard-2 \
    --worker-machine-type n1-standard-2 \
    --num-workers 2 \
    --worker-boot-disk-size 100 \
    --worker-boot-disk-type pd-standard \
    --no-address
}

cp_success=false

while [ "$cp_success" = false ]; do
  cluster_function
  exit_status=$?

  if [ "$exit_status" -eq 0 ]; then
    echo "Function deployed successfully"
    cp_success=true
  else
    echo "Cluster creation failed. Checking if cluster already exists..."

    if gcloud dataproc clusters describe "$CLUSTER_NAME" --region "$REGION" &>/dev/null; then
      echo "Cluster already exists. Deleting.."
      gcloud dataproc clusters delete "$CLUSTER_NAME" --region "$REGION" --quiet
      echo "Cluster deleted. Retrying in 10 seconds..."
    else
      echo "Unknown errors. Retrying in 10 seconds"
    fi
    echo "Please subscribe to techcps [https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l]"
    sleep 10
  fi
done


gcloud dataproc jobs submit spark \
    --project $DEVSHELL_PROJECT_ID \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --class org.apache.spark.examples.SparkPi \
    --jars file:///usr/lib/spark/examples/jars/spark-examples.jar \
    -- 1000


echo "Click this link to open" "${YELLOW}${BOLD}https://console.cloud.google.com/dataproc/jobs?project=$DEVSHELL_PROJECT_ID${RESET}"

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
