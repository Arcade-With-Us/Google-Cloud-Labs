#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
BG_RED=$'\033[41m'
BG_GREEN=$'\033[42m'
BG_YELLOW=$'\033[43m'
BG_BLUE=$'\033[44m'
BG_MAGENTA=$'\033[45m'
BG_CYAN=$'\033[46m'
BG_WHITE=$'\033[47m'
DIM_TEXT=$'\033[2m'
BLINK_TEXT=$'\033[5m'
REVERSE_TEXT=$'\033[7m'
STRIKETHROUGH_TEXT=$'\033[9m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}${BLINK_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

read -p "${CYAN_TEXT}${BOLD_TEXT}Enter Custom Security Role: ${RESET_FORMAT}" CUSTOM_ROLE
export CUSTOM_ROLE

read -p "${CYAN_TEXT}${BOLD_TEXT}Enter Service Account: ${RESET_FORMAT}" S_A
export S_A

read -p "${CYAN_TEXT}${BOLD_TEXT}Enter Cluster Name: ${RESET_FORMAT}" CLUSTER
export CLUSTER

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}⚙️ Detecting compute zone automatically...${RESET_FORMAT}"

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

if [ -z "$ZONE" ]; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}Zone not found automatically. Please enter your zone:${RESET_FORMAT}"
    echo
    read -p "${CYAN_TEXT}${BOLD_TEXT}Enter zone: ${RESET_FORMAT}" ZONE
    export ZONE
fi

echo "${GREEN_TEXT}${BOLD_TEXT}📍 Setting up compute zone configuration...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo "${BLUE_TEXT}${BOLD_TEXT}📝 Creating custom role definition file...${RESET_FORMAT}"
cat > role-definition.yaml <<EOF_END
title: "$CUSTOM_ROLE"
description: "Permissions"
stage: "ALPHA"
includedPermissions:
- storage.buckets.get
- storage.objects.get
- storage.objects.list
- storage.objects.update
- storage.objects.create
EOF_END

echo "${MAGENTA_TEXT}${BOLD_TEXT}👤 Creating Orca private cluster service account...${RESET_FORMAT}"
gcloud iam service-accounts create orca-private-cluster-sa --display-name "Orca Private Cluster Service Account"

echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Creating custom IAM role with specified permissions...${RESET_FORMAT}"
gcloud iam roles create $CUSTOM_ROLE --project $DEVSHELL_PROJECT_ID --file role-definition.yaml

echo "${GREEN_TEXT}${BOLD_TEXT}👥 Setting up user-defined service account...${RESET_FORMAT}"
gcloud iam service-accounts create $S_A --display-name "Orca Private Cluster Service Account"

echo "${YELLOW_TEXT}${BOLD_TEXT}🔐 Binding monitoring viewer role to service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$S_A@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/monitoring.viewer

echo "${YELLOW_TEXT}${BOLD_TEXT}📊 Binding monitoring metric writer role to service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$S_A@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/monitoring.metricWriter

echo "${YELLOW_TEXT}${BOLD_TEXT}📝 Binding logging writer role to service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$S_A@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/logging.logWriter

echo "${YELLOW_TEXT}${BOLD_TEXT}🎯 Binding custom role to service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$S_A@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role projects/$DEVSHELL_PROJECT_ID/roles/$CUSTOM_ROLE

echo "${RED_TEXT}${BOLD_TEXT}🏗️ Creating private GKE cluster with security configurations...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}This process may take several minutes. Please wait...${RESET_FORMAT}"
gcloud container clusters create $CLUSTER --num-nodes 1 --master-ipv4-cidr=172.16.0.64/28 --network orca-build-vpc --subnetwork orca-build-subnet --enable-master-authorized-networks  --master-authorized-networks 192.168.10.2/32 --enable-ip-alias --enable-private-nodes --enable-private-endpoint --service-account $S_A@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --zone $ZONE

echo "${BLUE_TEXT}${BOLD_TEXT}🔗 Connecting to jumphost and deploying application...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Configuring kubectl and creating hello-server deployment...${RESET_FORMAT}"
gcloud compute ssh --zone "$ZONE" "orca-jumphost" --project "$DEVSHELL_PROJECT_ID" --quiet --command "gcloud config set compute/zone $ZONE && gcloud container clusters get-credentials $CLUSTER --internal-ip && sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y && kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0 && kubectl expose deployment hello-server --name orca-hello-service --type LoadBalancer --port 80 --target-port 8080"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Security lab setup completed successfully! 🎉${RESET_FORMAT}"
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
