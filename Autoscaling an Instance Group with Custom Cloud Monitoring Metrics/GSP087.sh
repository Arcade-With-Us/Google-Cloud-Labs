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

gcloud config set compute/zone $ZONE 

export PROJECT_ID=$(gcloud config get-value project)

export REGION=${ZONE%-*}
gcloud config set compute/region $REGION

echo "PROJECT_ID=${PROJECT_ID}"

gsutil mb gs://$PROJECT_ID

gsutil cp -r gs://spls/gsp087/* gs://$PROJECT_ID


gcloud compute instance-templates create autoscaling-instance01 --metadata=startup-script-url=gs://$PROJECT_ID/startup.sh,gcs-bucket=gs://$PROJECT_ID


gcloud beta compute instance-groups managed create autoscaling-instance-group-1 --project=$PROJECT_ID --zone=$ZONE --base-instance-name=autoscaling-instance-group-1 --size=1 --template=projects/$PROJECT_ID/global/instanceTemplates/autoscaling-instance01 --list-managed-instances-results=PAGELESS --no-force-update-on-repair --default-action-on-vm-failure=repair


gcloud beta compute instance-groups managed set-autoscaling autoscaling-instance-group-1 --project=$PROJECT_ID --zone=$ZONE --cool-down-period=60  --max-num-replicas=3 --min-num-replicas=1 --mode=on --target-cpu-utilization=0.6 --stackdriver-metric-filter=resource.type\ =\ \"gce_instance\" --update-stackdriver-metric=custom.googleapis.com/appdemo_queue_depth_01 --stackdriver-metric-utilization-target=150.0 --stackdriver-metric-utilization-target-type=gauge

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
