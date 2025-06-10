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

# Function to set and export zone
set_zone() {
    echo "${BLUE}${BOLD}🌍 Zone Configuration${RESET}"
    
    # Try to get default zone
    export ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
    
    if [ -z "$ZONE" ]; then
        echo "${YELLOW}No default zone configured.${RESET}"
        echo "${CYAN}Available zones in your project:${RESET}"
        gcloud compute zones list --format="value(name)" | sort | pr -3 -t
        
        while true; do
            read -p "${BOLD}Enter your preferred zone (e.g., us-central1-a): ${RESET}" ZONE
            if gcloud compute zones describe $ZONE &>/dev/null; then
                break
            else
                echo "${RED}Invalid zone. Please try again.${RESET}"
            fi
        done
        
        # Set zone in gcloud config
        gcloud config set compute/zone $ZONE
    fi
    
    echo "${GREEN}Using zone: ${BOLD}$ZONE${RESET}"
    export ZONE
}

# Set and export zone
set_zone

# Main execution
echo
echo "${MAGENTA}${BOLD}${BOX_TOP}"
echo "  Starting Jenkins CD Deployment  "
echo "${BOX_BOT}${RESET}"

echo "${CYAN}${BOLD}🔧 Step 1: Cloning CD on Kubernetes repository...${RESET}"
git clone https://github.com/GoogleCloudPlatform/continuous-deployment-on-kubernetes.git
cd continuous-deployment-on-kubernetes || exit

echo "${CYAN}${BOLD}⚙️ Step 2: Creating GKE cluster for Jenkins...${RESET}"
gcloud container clusters create jenkins-cd \
--num-nodes 2 \
--scopes "https://www.googleapis.com/auth/projecthosting,cloud-platform" \
--zone $ZONE

echo "${CYAN}${BOLD}🔗 Step 3: Configuring kubectl credentials...${RESET}"
gcloud container clusters get-credentials jenkins-cd --zone $ZONE

echo "${CYAN}${BOLD}📦 Step 4: Setting up Helm charts...${RESET}"
helm repo add jenkins https://charts.jenkins.io
helm repo update

echo "${CYAN}${BOLD}🚀 Step 5: Deploying Jenkins...${RESET}"
helm upgrade --install -f jenkins/values.yaml myjenkins jenkins/jenkins

# Completion message
echo
echo "${GREEN}${BOLD}${BOX_TOP}"
echo "  🎉 Jenkins Deployment Completed Successfully!  "
echo "${BOX_BOT}${RESET}"
echo

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
