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
echo "${CYAN_TEXT}${BOLD_TEXT}  🚀   INITIATING EXECUTION   🚀  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

# Step 1: Set up the environment
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 1: Detecting your project region configuration...${RESET_FORMAT}"
# Get user input for regions
echo -e "${GREEN}${BOLD}🌍 Region Configuration${RESET}"
echo -e "${YELLOW}Please enter the regions for your backend groups:${RESET}"
read -p "Enter Group 1 Region (e.g. us-central1): " group1_region
read -p "Enter Group 2 Region (e.g. us-east1): " group2_region
read -p "Enter Group 3 Region (e.g. europe-west1): " group3_region
echo

# Clone Terraform module
echo -e "${GREEN}${BOLD}📥 Cloning Terraform HTTP Load Balancer module...${RESET}"
git clone https://github.com/terraform-google-modules/terraform-google-lb-http.git
cd ~/terraform-google-lb-http/examples/multi-backend-multi-mig-bucket-https-lb || {
    echo -e "${RED}❌ Failed to change directory${RESET}"
    exit 1
}

# Download configuration
echo -e "${GREEN}${BOLD}⚙️ Downloading Load Balancer configuration...${RESET}"
rm -rf main.tf
wget -q https://github.com/Arcade-With-Us/Google-Cloud-Labs/raw/refs/heads/main/HTTPS%20Content-Based%20Load%20Balancer%20with%20Terraform/main.tf

# Create variables file
echo -e "${GREEN}${BOLD}📝 Generating Terraform variables file...${RESET}"
cat > variables.tf <<EOF
variable "group1_region" {
  default = "$group1_region"
}

variable "group2_region" {
  default = "$group2_region"
}

variable "group3_region" {
  default = "$group3_region"
}

variable "network_name" {
  default = "ml-bk-ml-mig-bkt-s-lb"
}

variable "project" {
  type = string
}
EOF

# Terraform execution
echo -e "${GREEN}${BOLD}🛠️ Initializing Terraform...${RESET}"
terraform init

echo -e "${GREEN}${BOLD}🔎 Planning infrastructure...${RESET}"
echo $DEVSHELL_PROJECT_ID | terraform plan

echo -e "${GREEN}${BOLD}🚀 Applying configuration (may take 10-15 minutes)...${RESET}"
echo $DEVSHELL_PROJECT_ID | terraform apply -auto-approve

# Get Load Balancer IP
EXTERNAL_IP=$(terraform output | grep load-balancer-ip | cut -d = -f2 | xargs echo -n)

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
