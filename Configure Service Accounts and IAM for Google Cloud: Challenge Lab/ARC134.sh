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


echo "Please set the below values correctly"
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the ZONE: ${RESET_FORMAT}" ZONE

echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Setting up the region based on the provided zone...${RESET_FORMAT}"
export ZONE
export REGION="${ZONE%-*}"

echo "${BLUE_TEXT}${BOLD_TEXT}Region derived: ${REGION}${RESET_FORMAT}"

cat > cp_disk.sh <<'EOF_CP'
echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Authenticating with Google Cloud...${RESET_FORMAT}"
gcloud auth login --quiet

echo "${YELLOW_TEXT}${BOLD_TEXT}📋 Fetching the current project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)

echo "${GREEN_TEXT}${BOLD_TEXT}🌐 Retrieving the default compute zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo "${MAGENTA_TEXT}${BOLD_TEXT}🛠️ Creating a service account named 'devops'...${RESET_FORMAT}"
gcloud iam service-accounts create devops --display-name devops

echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Activating the default configuration...${RESET_FORMAT}"
gcloud config configurations activate default

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Listing service accounts to verify creation...${RESET_FORMAT}"
gcloud iam service-accounts list --filter "displayName=devops"

SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")

echo "${GREEN_TEXT}${BOLD_TEXT}Service account email: ${SERVICE_ACCOUNT}${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}🔒 Assigning IAM roles to the service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/compute.instanceAdmin"

echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Creating a VM instance named 'vm-2'...${RESET_FORMAT}"
gcloud compute instances create vm-2 --project=$PROJECT_ID --zone=$ZONE --service-account=$SERVICE_ACCOUNT --scopes=https://www.googleapis.com/auth/bigquery

echo "${MAGENTA_TEXT}${BOLD_TEXT}📄 Defining a custom IAM role...${RESET_FORMAT}"
cat > role-definition.yaml <<EOF
title: Custom Role
description: Custom role with cloudsql.instances.connect and cloudsql.instances.get permissions
includedPermissions:
- cloudsql.instances.connect
- cloudsql.instances.get
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}🔧 Creating the custom IAM role...${RESET_FORMAT}"
gcloud iam roles create customRole --project=$PROJECT_ID --file=role-definition.yaml

echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️ Creating a service account named 'bigquery-qwiklab'...${RESET_FORMAT}"
gcloud iam service-accounts create bigquery-qwiklab --display-name bigquery-qwiklab

SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=bigquery-qwiklab")

echo "${GREEN_TEXT}${BOLD_TEXT}🔒 Assigning BigQuery roles to the service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/bigquery.dataViewer

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/bigquery.user

echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Creating a VM instance named 'bigquery-instance'...${RESET_FORMAT}"
gcloud compute instances create bigquery-instance --project=$PROJECT_ID --zone=$ZONE --service-account=$SERVICE_ACCOUNT --scopes=https://www.googleapis.com/auth/bigquery
EOF_CP

echo -n "${YELLOW_TEXT}${BOLD_TEXT}⏳ Waiting a moment... ${RESET_FORMAT}"
for i in {1..10}; do
  echo -n "."
  sleep 1
done
echo " ${GREEN_TEXT}Done!${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}Zone: ${ZONE}${RESET_FORMAT}"

export PROJECT_ID=$(gcloud config get-value project)

echo "${YELLOW_TEXT}${BOLD_TEXT}📤 Copying the script to 'lab-vm'...${RESET_FORMAT}"
gcloud compute scp cp_disk.sh lab-vm:/tmp --project=$PROJECT_ID --zone=$ZONE --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Executing the script on 'lab-vm'...${RESET_FORMAT}"
gcloud compute ssh lab-vm --project=$PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/cp_disk.sh"

echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Waiting for resources to provision...${RESET_FORMAT}"
total_seconds=45
bar_width=40 # Width of the progress bar

# Print initial empty bar
echo -ne "${YELLOW_TEXT}${BOLD_TEXT}["
printf "%${bar_width}s" " " | tr ' ' '-'
echo -ne "] 0%${RESET_FORMAT}"

for i in $(seq 1 $total_seconds); do
  # Calculate progress
  percent=$(( (i * 100) / total_seconds ))
  filled_width=$(( (i * bar_width) / total_seconds ))
  empty_width=$(( bar_width - filled_width ))

  # Build the bar string parts
  filled_part=$(printf "%${filled_width}s" "" | tr ' ' '#')
  empty_part=$(printf "%${empty_width}s" "" | tr ' ' '-')

  # Move cursor back to the beginning of the line, print the updated bar and percentage
  echo -ne "\r${YELLOW_TEXT}${BOLD_TEXT}[${GREEN_TEXT}${filled_part}${YELLOW_TEXT}${empty_part}] ${percent}%${RESET_FORMAT}"

  sleep 1
done

# Print a newline at the end to move off the progress bar line
echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Wait complete!${RESET_FORMAT}"

cat > cp_disk.sh <<'EOF_CP'
echo "${GREEN_TEXT}${BOLD_TEXT}🔄 Updating the system packages...${RESET_FORMAT}"
sudo apt-get update

echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Installing Python 3 and required dependencies...${RESET_FORMAT}"
sudo apt install python3 -y

sudo apt-get install -y git python3-pip

sudo apt install python3.11-venv -y

echo "${BLUE_TEXT}${BOLD_TEXT}🌐 Setting up a Python virtual environment...${RESET_FORMAT}"
python3 -m venv create myvenv

source myvenv/bin/activate

echo "${CYAN_TEXT}${BOLD_TEXT}📦 Upgrading pip and installing required Python libraries...${RESET_FORMAT}"
pip3 install --upgrade pip

pip3 install google-cloud-bigquery

pip3 install pyarrow

pip3 install pandas

pip3 install db-dtypes

pip3 install --upgrade google-cloud

export PROJECT_ID=$(gcloud config get-value project)
export SERVICE_ACCOUNT_EMAIL=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email" -H "Metadata-Flavor: Google")

echo "${MAGENTA_TEXT}${BOLD_TEXT}📄 Creating a Python script to query BigQuery...${RESET_FORMAT}"
echo "
from google.auth import compute_engine
from google.cloud import bigquery
credentials = compute_engine.Credentials(
service_account_email='$SERVICE_ACCOUNT_EMAIL')
query = '''
SELECT name, SUM(number) as total_people
FROM "bigquery-public-data.usa_names.usa_1910_2013"
WHERE state = 'TX'
GROUP BY name, state
ORDER BY total_people DESC
LIMIT 20
'''
client = bigquery.Client(
  project='$PROJECT_ID',
  credentials=credentials)
print(client.query(query).to_dataframe())
" > query.py

sleep 10

echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Executing the BigQuery Python script...${RESET_FORMAT}"
python3 query.py
EOF_CP

echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Waiting a moment... ${RESET_FORMAT}"
total_seconds=10 # Set duration to 10 seconds
bar_width=40 # Width of the progress bar

# Print initial empty bar
echo -ne "${YELLOW_TEXT}${BOLD_TEXT}["
printf "%${bar_width}s" " " | tr ' ' '-'
echo -ne "] 0%${RESET_FORMAT}"

for i in $(seq 1 $total_seconds); do
  # Calculate progress
  percent=$(( (i * 100) / total_seconds ))
  filled_width=$(( (i * bar_width) / total_seconds ))
  empty_width=$(( bar_width - filled_width ))

  # Build the bar string parts
  filled_part=$(printf "%${filled_width}s" "" | tr ' ' '#')
  empty_part=$(printf "%${empty_width}s" "" | tr ' ' '-')

  # Move cursor back to the beginning of the line, print the updated bar and percentage
  echo -ne "\r${YELLOW_TEXT}${BOLD_TEXT}[${GREEN_TEXT}${filled_part}${YELLOW_TEXT}${empty_part}] ${percent}%${RESET_FORMAT}"

  sleep 1
done

# Print a newline at the end to move off the progress bar line
echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Wait complete!${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}Zone: ${ZONE}${RESET_FORMAT}"

export PROJECT_ID=$(gcloud config get-value project)

echo "${YELLOW_TEXT}${BOLD_TEXT}📤 Copying the script to 'bigquery-instance'...${RESET_FORMAT}"
gcloud compute scp cp_disk.sh bigquery-instance:/tmp --project=$PROJECT_ID --zone=$ZONE --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Executing the script on 'bigquery-instance'...${RESET_FORMAT}"
gcloud compute ssh bigquery-instance --project=$PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/cp_disk.sh"

# Completion message

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
