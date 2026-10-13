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

# ==========================================
# TASK 2 & 3: Create DevOps Service Account
# ==========================================

export PROJECT_ID=$(gcloud config get-value project)
export SA=devops@${PROJECT_ID}.iam.gserviceaccount.com

gcloud iam service-accounts create devops \
  --display-name="devops" 2>/dev/null || true

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA}" \
  --role="roles/iam.serviceAccountUser" \
  --condition=None

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA}" \
  --role="roles/compute.instanceAdmin" \
  --condition=None


# ==========================================
# TASK 4: Create VM with DevOps Service Account
# ==========================================

export ZONE=$(gcloud config get-value compute/zone)

gcloud compute instances create vm-2 \
  --zone=${ZONE} \
  --machine-type=e2-micro \
  --service-account=${SA} \
  --scopes=https://www.googleapis.com/auth/cloud-platform


# ==========================================
# TASK 5: Create Custom IAM Role
# ==========================================

cat <<'EOF' > role-definition.yaml
title: "Custom Role"
description: "Custom role for Cloud SQL access"
stage: "GA"
includedPermissions:
- cloudsql.instances.connect
- cloudsql.instances.get
EOF

gcloud iam roles create customRole \
  --project=${PROJECT_ID} \
  --file=role-definition.yaml


# ==========================================
# TASK 6: Create BigQuery Service Account
# ==========================================

export BQ_SA=bigquery-qwiklab@${PROJECT_ID}.iam.gserviceaccount.com

gcloud iam service-accounts create bigquery-qwiklab \
  --display-name="bigquery-qwiklab" 2>/dev/null || true

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${BQ_SA}" \
  --role="roles/bigquery.dataViewer" \
  --condition=None

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${BQ_SA}" \
  --role="roles/bigquery.user" \
  --condition=None


# ==========================================
# Create BigQuery VM with Service Account
# ==========================================
export ZONE=$(gcloud config get-value compute/zone)

gcloud compute instances create bigquery-instance \
  --zone=${ZONE} \
  --machine-type=e2-medium \
  --service-account=${BQ_SA} \
  --scopes=https://www.googleapis.com/auth/cloud-platform


# ==========================================
# Connect to BigQuery VM
# ==========================================
export ZONE=$(gcloud config get-value compute/zone)

gcloud compute ssh bigquery-instance --zone=${ZONE}
Important: The block above ends by connecting to the BigQuery VM. Once connected, run the following second block inside the VM to install dependencies and execute the query.

bash
# Install Python dependencies
sudo apt-get update
sudo apt-get install -y python3-pip python3-pandas python3-google-auth
pip3 install google-cloud-bigquery db-dtypes --break-system-packages

export PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id)

export BQ_SA=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email)

# Create the BigQuery query script
cat <<'EOF' > query.py
from google.auth import compute_engine
from google.cloud import bigquery
import os

PROJECT_ID = os.environ["PROJECT_ID"]
BQ_SA = os.environ["BQ_SA"]

credentials = compute_engine.Credentials(
    service_account_email=BQ_SA
)

query = """
SELECT name, SUM(number) AS total_people
FROM `bigquery-public-data.usa_names.usa_1910_2013`
WHERE state = 'TX'
GROUP BY name, state
ORDER BY total_people DESC
LIMIT 20
"""

client = bigquery.Client(
    project=PROJECT_ID,
    credentials=credentials
)

print(client.query(query).to_dataframe())
EOF

python3 query.py

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
