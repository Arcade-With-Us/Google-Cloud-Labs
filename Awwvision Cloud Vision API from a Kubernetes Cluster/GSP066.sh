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

# Get Zone Input
echo "${YELLOW}${BOLD}Please enter your preferred zone (e.g., us-central1-a):${RESET}"
read ZONE
export ZONE

# Set compute zone
echo "${BLUE}${BOLD}Setting compute zone to ${ZONE}...${RESET}"
gcloud config set compute/zone $ZONE

# Create GKE cluster
echo
echo "${BLUE}${BOLD}Creating GKE cluster 'awwvision'...${RESET}"
gcloud container clusters create awwvision \
    --num-nodes 2 \
    --scopes cloud-platform

# Get cluster credentials
echo
echo "${BLUE}${BOLD}Getting cluster credentials...${RESET}"
gcloud container clusters get-credentials awwvision

# Display cluster info
echo
echo "${BLUE}${BOLD}Cluster information:${RESET}"
kubectl cluster-info

# Install virtualenv
echo
echo "${BLUE}${BOLD}Installing virtualenv...${RESET}"
sudo apt-get install -y virtualenv

# Create Python virtual environment
echo
echo "${BLUE}${BOLD}Creating Python virtual environment...${RESET}"
python3 -m venv venv

# Activate virtual environment
echo
echo "${BLUE}${BOLD}Activating virtual environment...${RESET}"
source venv/bin/activate

# Copy cloud vision files
echo
echo "${BLUE}${BOLD}Copying Cloud Vision files...${RESET}"
gsutil -m cp -r gs://spls/gsp066/cloud-vision .

# Change directory and run make
echo
echo "${BLUE}${BOLD}Setting up awwvision application...${RESET}"
cd cloud-vision/python/awwvision
make all

# Check pod status
echo
echo "${BLUE}${BOLD}Checking pod status:${RESET}"
kubectl get pods

echo
echo "${BLUE}${BOLD}Waiting for pods to initialize...${RESET}"
sleep 5 

echo
echo "${BLUE}${BOLD}Checking pod status again:${RESET}"
kubectl get pods

# Display deployment info
echo
echo "${BLUE}${BOLD}Deployment information:${RESET}"
kubectl get deployments -o wide

# Display service info
echo
echo "${BLUE}${BOLD}Service information:${RESET}"
kubectl get svc awwvision-webapp

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo
