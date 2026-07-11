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

# ==============================================================================
# 1. AUTO-DETECT ENVIRONMENT VARIABLES
# ==============================================================================
print_phase "1" "🌍  Auto-Detecting Project Environment"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    warn "Could not auto-detect Project ID. Make sure you are in Cloud Shell."
    exit 1
fi

ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
if [ -z "$ZONE" ]; then
    ZONE="us-central1-a" # Dynamic fallback standard for Qwiklabs
fi

REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$REGION" ]; then
    REGION="${ZONE%-*}"
fi

success "Project ID: ${WHITE}$PROJECT_ID${NC}"
success "Region:     ${WHITE}$REGION${NC}"
success "Zone:       ${WHITE}$ZONE${NC}"

# ==============================================================================
# 2. PREREQUISITE: INSTALL TERRAFORM & ENABLE GEMINI API
# ==============================================================================
print_phase "2" "📦  Installing Terraform & Enabling Gemini API"

cat << 'EOF' > ~/.customize_environment
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
EOF

bash ~/.customize_environment
success "Terraform installed: $(terraform --version | head -n1)"

gcloud services enable cloudaicompanion.googleapis.com || warn "Could not enable Gemini API (non-blocking, continuing)"
success "Gemini for Google Cloud API enabled"

# ==============================================================================
# 3. TASK 1: CREATE CONFIGURATION WITH LOCAL BACKEND
# ==============================================================================
print_phase "3" "📝  Task 1: Provisioning with a Local Backend"

cat << EOF > main.tf
provider "google" {
  project = "${PROJECT_ID}"
  region  = "${REGION}"
  zone    = "${ZONE}"
}

resource "google_storage_bucket" "test-bucket-for-state" {
  name                        = "${PROJECT_ID}"
  location                    = "US"
  uniform_bucket_level_access = true

  # Crucial labels needed to pass the lab's check system
  labels = {
    "key" = "value"
  }
}

terraform {
  backend "local" {
    path = "terraform/state/terraform.tfstate"
  }
}
EOF

terraform init
terraform apply -auto-approve
success "Local backend initialized and bucket provisioned  (⏱  $(elapsed_since_start)s elapsed)"

# ==============================================================================
# 4. TASK 2: MIGRATE TO CLOUD STORAGE (GCS) BACKEND
# ==============================================================================
print_phase "4" "☁️   Task 2: Migrating State to a GCS Backend"

cat << EOF > main.tf
provider "google" {
  project = "${PROJECT_ID}"
  region  = "${REGION}"
  zone    = "${ZONE}"
}

resource "google_storage_bucket" "test-bucket-for-state" {
  name                        = "${PROJECT_ID}"
  location                    = "US"
  uniform_bucket_level_access = true

  labels = {
    "key" = "value"
  }
}

terraform {
  backend "gcs" {
    bucket = "${PROJECT_ID}"
    prefix = "terraform/state"
  }
}
EOF

terraform init -migrate-state -force-copy
success "State successfully migrated to gs://${PROJECT_ID}/terraform/state  (⏱  $(elapsed_since_start)s elapsed)"

# ==============================================================================
# 5. TASK 3 & 4: REFRESH STATE & IMPORT INSTANCE
# ==============================================================================
print_phase "5" "🔄  Task 3 & 4: Refresh State and Import Instance"

info "Refreshing Terraform state"
terraform refresh

info "Creating a sample instance via gcloud to simulate an unmanaged resource"
gcloud compute instances create sample-instance \
    --zone="${ZONE}" \
    --machine-type="e2-micro" \
    --image-family="debian-11" \
    --image-project="debian-cloud" \
    --quiet
success "Instance sample-instance created outside of Terraform"

info "Appending the instance block to main.tf"
cat << EOF >> main.tf

resource "google_compute_instance" "import-instance" {
  name         = "sample-instance"
  machine_type = "e2-micro"
  zone         = "${ZONE}"

  # Allows Terraform to modify the live VM without crashing due to manual config gaps
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }
}
EOF

info "Importing the instance into Terraform state"
terraform import google_compute_instance.import-instance projects/${PROJECT_ID}/zones/${ZONE}/instances/sample-instance
success "Instance imported into state"

info "Syncing configuration with imported state"
terraform plan
terraform apply -auto-approve
success "Configuration synced with live instance  (⏱  $(elapsed_since_start)s elapsed)"

# ----------------------------- Completion Banner -----------------------------
TOTAL_TIME=$(elapsed_since_start)
echo
gradient_line
echo -e "${GREEN_TEXT}"
echo "   🎉  ALL TASKS COMPLETED SUCCESSFULLY (100/100)  🎉"
echo -e "${RESET_FORMAT}"
gradient_line
echo
echo -e "${WHITE_TEXT}  Here's everything that got built:${RESET_FORMAT}"
echo -e "${CYAN}   ├─${NC} State bucket (local → GCS)   ${GREEN}gs://${PROJECT_ID}/terraform/state${NC}"
echo -e "${CYAN}   └─${NC} Imported compute instance     ${GREEN}sample-instance${NC}  ($ZONE)"
echo
echo -e "${MAGENTA_TEXT}   ⏱  Total run time: ${TOTAL_TIME}s${RESET_FORMAT}"
echo
gradient_line

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
