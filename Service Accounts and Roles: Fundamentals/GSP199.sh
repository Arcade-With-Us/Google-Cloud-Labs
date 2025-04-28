#!/bin/bash
# Define text formatting variables
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
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}👉 Listing active GCP accounts...${RESET_FORMAT}"
gcloud auth list

echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Setting PROJECT_ID variable from current gcloud configuration...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}   Project ID set to: ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}🌍 Determining default compute zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo "${GREEN_TEXT}   Zone set to: ${BOLD_TEXT}$ZONE${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}🌏 Determining default compute region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${GREEN_TEXT}   Region set to: ${BOLD_TEXT}$REGION${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}👤 Creating the first service account 'my-sa-123'...${RESET_FORMAT}"
gcloud iam service-accounts create my-sa-123 --display-name "Subscribe to Arcade Crew"

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Granting 'Editor' role to 'my-sa-123' on the project...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:my-sa-123@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/editor

echo "${YELLOW_TEXT}${BOLD_TEXT}👤 Creating the second service account 'bigquery-qwiklab'...${RESET_FORMAT}"
gcloud iam service-accounts create bigquery-qwiklab --description="Subscribe to Arcade Crew" --display-name="bigquery-qwiklab"

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Granting 'BigQuery Data Viewer' role to 'bigquery-qwiklab'...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member="serviceAccount:bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" --role="roles/bigquery.dataViewer"

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Granting 'BigQuery User' role to 'bigquery-qwiklab'...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member="serviceAccount:bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" --role="roles/bigquery.user"

echo "${YELLOW_TEXT}${BOLD_TEXT}💻 Creating a Compute Engine instance 'bigquery-instance' with the 'bigquery-qwiklab' service account...${RESET_FORMAT}"
gcloud compute instances create bigquery-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --create-disk=auto-delete=yes,boot=yes,device-name=bigquery-instance,image=projects/debian-cloud/global/images/debian-11-bullseye-v20231010,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for 20 seconds for the instance to initialize...${RESET_FORMAT}"
echo -n "${BLUE_TEXT}${BOLD_TEXT}   ["
for i in {1..20}; do
    echo -n "."
    sleep 1
done
echo "]${RESET_FORMAT}"
echo 

echo "${YELLOW_TEXT}${BOLD_TEXT}📝 Creating a script 'cp_disk.sh' locally. This script will run on the VM.${RESET_FORMAT}"
cat > cp_disk.sh <<'EOF_CP'
#!/bin/bash

# Install required packages
sudo apt-get update
sudo apt-get install -y git python3-pip

# Upgrade pip and install Python libraries
pip3 install --upgrade pip
pip3 install google-cloud-bigquery
pip3 install pyarrow
pip3 install pandas
pip3 install db-dtypes

cat > query.py <<'EOF_PY'
from google.auth import compute_engine
from google.cloud import bigquery

credentials = compute_engine.Credentials(
    service_account_email='YOUR_SERVICE_ACCOUNT')

query = '''
SELECT
  year,
  COUNT(1) as num_babies
FROM
  publicdata.samples.natality
WHERE
  year > 2000
GROUP BY
  year
'''

client = bigquery.Client(
    project='PROJECT_ID',
    credentials=credentials)
print(client.query(query).to_dataframe())
EOF_PY

sed -i -e "s/PROJECT_ID/$(gcloud config get-value project)/g" query.py

sed -i -e "s/YOUR_SERVICE_ACCOUNT/bigquery-qwiklab@$(gcloud config get-value project).iam.gserviceaccount.com/g" query.py

python3 query.py

EOF_CP
echo "${GREEN_TEXT}${BOLD_TEXT}   ✅ Script 'cp_disk.sh' created successfully.${RESET_FORMAT}"


echo "${YELLOW_TEXT}${BOLD_TEXT}📤 Copying 'cp_disk.sh' to the 'bigquery-instance' VM...${RESET_FORMAT}"
gcloud compute scp cp_disk.sh bigquery-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 Executing 'cp_disk.sh' on the 'bigquery-instance' VM via SSH...${RESET_FORMAT}"
gcloud compute ssh bigquery-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/cp_disk.sh"


echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
