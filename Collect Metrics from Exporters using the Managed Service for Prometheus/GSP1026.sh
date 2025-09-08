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

echo
echo "${BLUE}${BOLD}⚡ Initializing GMP Cluster Setup...${RESET}"
echo

# User Input for Zone
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ZONE CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"
read -p "${YELLOW}${BOLD}Enter the ZONE (e.g., us-central1-a): ${RESET}" ZONE
export ZONE
echo "${GREEN}✅ Zone set to: ${WHITE}${BOLD}$ZONE${RESET}"
echo

# Cluster Creation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ CLUSTER CREATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating GMP cluster...${RESET}"
gcloud beta container clusters create gmp-cluster \
  --num-nodes=1 \
  --zone $ZONE \
  --enable-managed-prometheus
echo "${GREEN}✅ GMP cluster created successfully!${RESET}"
echo

# Cluster Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ CLUSTER CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Getting cluster credentials...${RESET}"
gcloud container clusters get-credentials gmp-cluster --zone=$ZONE
echo "${GREEN}✅ Cluster credentials configured!${RESET}"
echo

# Namespace and Application Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ APPLICATION DEPLOYMENT ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating gmp-test namespace...${RESET}"
kubectl create ns gmp-test
echo "${GREEN}✅ Namespace created!${RESET}"

echo "${YELLOW}Deploying example application...${RESET}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/examples/example-app.yaml
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/examples/pod-monitoring.yaml
echo "${GREEN}✅ Application deployed successfully!${RESET}"
echo

# Prometheus Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ PROMETHEUS CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Setting up Prometheus...${RESET}"
git clone https://github.com/GoogleCloudPlatform/prometheus && cd prometheus
git checkout v2.28.1-gmp.4
wget https://storage.googleapis.com/kochasoft/gsp1026/prometheus

export PROJECT_ID=$(gcloud config get-value project)
echo "${YELLOW}Project ID: ${WHITE}${BOLD}$PROJECT_ID${RESET}"

echo "${YELLOW}Starting Prometheus with zone export...${RESET}"
./prometheus \
  --config.file=documentation/examples/prometheus.yml \
  --export.label.project-id=$PROJECT_ID \
  --export.label.location=$ZONE
echo "${GREEN}✅ Prometheus configured with zone export!${RESET}"
echo

# Node Exporter Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ NODE EXPORTER SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Installing node exporter...${RESET}"
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz
cd node_exporter-1.3.1.linux-amd64

echo "${YELLOW}Creating node exporter config...${RESET}"
cat > config.yaml <<EOF_END
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: node
    static_configs:
      - targets: ['localhost:9100']
EOF_END

echo "${YELLOW}Uploading config to Cloud Storage...${RESET}"
export PROJECT=$(gcloud config get-value project)
gsutil mb -p $PROJECT gs://$PROJECT
gsutil cp config.yaml gs://$PROJECT
gsutil -m acl set -R -a public-read gs://$PROJECT
echo "${GREEN}✅ Node exporter setup complete!${RESET}"
echo

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
