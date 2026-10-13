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
echo "${CYAN_TEXT}${BOLD_TEXT}  🚀       INITIATING EXECUTION     🚀  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

# Set text styles
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)

 export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Task 2. Create a Service Account using the gcloud CLI
#Open Cloud Shell and create the devops service account:

gcloud iam service-accounts create devops \
  --display-name="devops"

#Task 3. Grant IAM Permissions to a Service Account using the gcloud CLI
#Set environment variables for your Project ID and Service Account Email:

export PROJECT_ID=$(gcloud config get-value project)

export SA=devops@${PROJECT_ID}.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding ${PROJECT_ID} \

  --member="serviceAccount:${SA}" \

  --role="roles/iam.serviceAccountUser" \

  --condition=None

gcloud projects add-iam-policy-binding ${PROJECT_ID} \

  --member="serviceAccount:${SA}" \

  --role="roles/compute.instanceAdmin" \

  --condition=None

#Task 4. Create a Compute Instance with a Service Account Attached
#Create the vm-2 instance in region us-east1 and zone us-east1-c attached to the devops service account:

gcloud compute instances create vm-2 \

  --zone=us-east1-c \    (Change the zone)

  --machine-type=e2-micro \

  --service-account=${SA} \

  --scopes=https://www.googleapis.com/auth/cloud-platform

#Task 5. Create a Custom Role Using a YAML File
#Create the role-definition.yaml file:

cat << 'EOF' > role-definition.yaml

title: "Custom Role"

description: "Custom role for Cloud SQL access"

stage: "GA"

includedPermissions:

- cloudsql.instances.connect

- cloudsql.instances.get

EOF

# 2.   Create the custom role at the project level using gcloud:


export PROJECT_ID=$(gcloud config get-value project)

gcloud iam roles create customRole \

  --project=${PROJECT_ID} \

  --file=role-definition.yaml

#Task 6. Use the Client Libraries to Access BigQuery from a Service Account
#Create the bigquery-qwiklab service account and attach the BigQuery Data Viewer (roles/bigquery.dataViewer) and BigQuery User (roles/bigquery.user) roles:
#1.Bash

gcloud compute ssh bigquery-instance --zone=us-east1-c

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
