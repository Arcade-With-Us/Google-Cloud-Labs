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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛠️  Attempting to automatically determine your Google Cloud default zone...${RESET_FORMAT}"
ZONE_VALUE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE_VALUE" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Warning: Could not automatically determine the default Google Cloud zone.${RESET_FORMAT}"
  read -p "${BLUE_TEXT}${BOLD_TEXT}Enter the ZONE: ${RESET_FORMAT}" ZONE_VALUE
  
  if [ -z "$ZONE_VALUE" ]; then
    echo "${RED_TEXT}${BOLD_TEXT}❌ Error: No zone provided. Exiting script.${RESET_FORMAT}"
  fi
fi

echo "${GREEN_TEXT}${BOLD_TEXT}🔧 Setting the ZONE environment variable...${RESET_FORMAT}"
export ZONE="$ZONE_VALUE"

echo "${GREEN_TEXT}✅ Using zone: ${BOLD_TEXT}${ZONE}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️  Configuring gcloud to use the selected zone: ${WHITE_TEXT}${BOLD_TEXT}${ZONE}${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🏗️  Creating the GKE cluster 'lab-cluster'. This might take a few minutes...${RESET_FORMAT}"
gcloud container clusters create --machine-type=e2-medium --zone=$ZONE lab-cluster

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔑 Fetching credentials for 'lab-cluster' to interact with it using kubectl...${RESET_FORMAT}"
gcloud container clusters get-credentials lab-cluster

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🚀 Deploying the 'hello-server' application to your cluster...${RESET_FORMAT}"
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🌐 Exposing the 'hello-server' deployment as a LoadBalancer service on port 8080...${RESET_FORMAT}"
kubectl expose deployment hello-server --type=LoadBalancer --port 8080

echo
echo "${RED_TEXT}${BOLD_TEXT}🗑️  Initiating deletion of the 'lab-cluster'. This will also take a few moments...${RESET_FORMAT}"
echo "Y" | gcloud container clusters delete lab-cluster
