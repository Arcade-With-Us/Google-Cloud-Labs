#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

# Clear the screen
clear

# Print the welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Instruction for setting REGION
echo "${YELLOW_TEXT}${BOLD_TEXT}Please set the REGION variable before proceeding.${RESET_FORMAT}"
read -p "${CYAN_TEXT}${BOLD_TEXT}Enter the REGION: ${RESET_FORMAT}" REGION
export REGION
export PROJECT_ID=$(gcloud info --format="value(config.project)")

# Instruction for cloning the repository
echo "${GREEN_TEXT}${BOLD_TEXT}Cloning the DIY-Tools repository from GitHub...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/DIY-Tools.git

# Instruction for Firestore import
echo "${MAGENTA_TEXT}${BOLD_TEXT}Importing Firestore data from the specified bucket...${RESET_FORMAT}"
gcloud firestore import gs://$PROJECT_ID-firestore/prd-back

PROJECT_NUMBER=$(gcloud projects list --filter="PROJECT_ID=$PROJECT_ID" --format="value(PROJECT_NUMBER)")
SERVICE_ACCOUNT_EMAIL="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Instruction for adding IAM policy binding
echo "${CYAN_TEXT}${BOLD_TEXT}Adding IAM policy binding for the service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role "roles/artifactregistry.reader"

cd ~/DIY-Tools/gcp-data-drive

# Instruction for submitting the Cloud Build
echo "${GREEN_TEXT}${BOLD_TEXT}Submitting the Cloud Build for Cloud Run deployment...${RESET_FORMAT}"
gcloud builds submit --config cloudbuild_run.yaml \
  --project $PROJECT_ID --no-source \
  --substitutions=_GIT_SOURCE_BRANCH="master",_GIT_SOURCE_URL="https://github.com/GoogleCloudPlatform/DIY-Tools"

# Instruction for adding IAM policy binding for Cloud Run
echo "${MAGENTA_TEXT}${BOLD_TEXT}Adding IAM policy binding for Cloud Run service...${RESET_FORMAT}"
gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker gcp-data-drive

export CLOUD_RUN_SERVICE_URL=$(gcloud run services --platform managed describe gcp-data-drive --region $REGION --format="value(status.url)")

# Instruction for testing the Cloud Run service
echo "${CYAN_TEXT}${BOLD_TEXT}Testing the Cloud Run service with sample requests...${RESET_FORMAT}"
curl $CLOUD_RUN_SERVICE_URL/fs/$PROJECT_ID/symbols/product/symbol | jq .

curl $CLOUD_RUN_SERVICE_URL/bq/$PROJECT_ID/publicviews/ca_zip_codes | jq .

sleep 60

#TASK 3

# Instruction for creating the Cloud Build configuration for Cloud Functions
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Cloud Build configuration for deploying Cloud Functions...${RESET_FORMAT}"
cat > cloudbuild_gcf.yaml <<'EOF_END'
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

steps:
- name: 'gcr.io/cloud-builders/git'
# The gcloud command used to call this cloud build uses the --no-source switch which ensures the source builds correctly. As a result we need to
# clone the specified source to preform the build.
  args: ['clone','--single-branch','--branch','${_GIT_SOURCE_BRANCH}','${_GIT_SOURCE_URL}']

- name: 'gcr.io/cloud-builders/gcloud'
  args: ['functions','deploy','gcp-data-drive','--trigger-http','--runtime','go121','--entry-point','GetJSONData', '--project','$PROJECT_ID','--memory','2048']
  dir: 'DIY-Tools/gcp-data-drive'
EOF_END

# Instruction for submitting the Cloud Build for Cloud Functions
echo "${GREEN_TEXT}${BOLD_TEXT}Submitting the Cloud Build for deploying Cloud Functions...${RESET_FORMAT}"
gcloud builds submit --config cloudbuild_gcf.yaml --project $PROJECT_ID --no-source --substitutions=_GIT_SOURCE_BRANCH="master",_GIT_SOURCE_URL="https://github.com/GoogleCloudPlatform/DIY-Tools"

# Instruction for adding IAM policy binding for Cloud Functions
echo "${MAGENTA_TEXT}${BOLD_TEXT}Adding IAM policy binding for Cloud Functions...${RESET_FORMAT}"
gcloud alpha functions add-iam-policy-binding gcp-data-drive --member=allUsers --role=roles/cloudfunctions.invoker

export CF_TRIGGER_URL=$(gcloud functions describe gcp-data-drive --format="value(httpsTrigger.url)")

# Instruction for testing the Cloud Function
echo "${CYAN_TEXT}${BOLD_TEXT}Testing the Cloud Function with sample requests...${RESET_FORMAT}"
curl $CF_TRIGGER_URL/fs/$PROJECT_ID/symbols/product/symbol | jq .

curl $CF_TRIGGER_URL/bq/$PROJECT_ID/publicviews/ca_zip_codes

#TASK 4

# Instruction for creating the Cloud Build configuration for App Engine
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Cloud Build configuration for deploying App Engine...${RESET_FORMAT}"
cat > cloudbuild_appengine.yaml <<'EOF_END'
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

steps:
- name: 'gcr.io/cloud-builders/git'
# The gcloud command used to call this cloud build uses the --no-source switch which ensures the source builds correctly. As a result we need to
# clone the specified source to preform the build.
  args: ['clone','--single-branch','--branch','${_GIT_SOURCE_BRANCH}','${_GIT_SOURCE_URL}']

- name: 'ubuntu'  # Or any base image containing 'sed'
  args: ['sed', '-i', 's/runtime: go113/runtime: go121/', 'app.yaml'] # Replace go113 with go121
  dir: 'DIY-Tools/gcp-data-drive/cmd/webserver'

- name: 'gcr.io/cloud-builders/gcloud'
  args: ['app','deploy','app.yaml','--project','$PROJECT_ID']
  dir: 'DIY-Tools/gcp-data-drive/cmd/webserver'
EOF_END

# Instruction for submitting the Cloud Build for App Engine
echo "${GREEN_TEXT}${BOLD_TEXT}Submitting the Cloud Build for deploying App Engine...${RESET_FORMAT}"
gcloud builds submit  --config cloudbuild_appengine.yaml \
   --project $PROJECT_ID --no-source \
   --substitutions=_GIT_SOURCE_BRANCH="master",_GIT_SOURCE_URL="https://github.com/GoogleCloudPlatform/DIY-Tools"

export TARGET_URL=https://$(gcloud app describe --format="value(defaultHostname)")

# Instruction for testing the App Engine service
echo "${CYAN_TEXT}${BOLD_TEXT}Testing the App Engine service with sample requests...${RESET_FORMAT}"
curl $TARGET_URL/fs/$PROJECT_ID/symbols/product/symbol | jq .

curl $TARGET_URL/bq/$PROJECT_ID/publicviews/ca_zip_codes | jq .

# Instruction for creating the load generator script
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the load generator script...${RESET_FORMAT}"
cat > loadgen.sh <<EOF
#!/bin/bash
for ((i=1;i<=1000;i++));
do
   curl $TARGET_URL/bq/$PROJECT_ID/publicviews/ca_zip_codes > /dev/null &
done
EOF

# Instruction for submitting the Cloud Build again
echo "${GREEN_TEXT}${BOLD_TEXT}Submitting the Cloud Build again for verification...${RESET_FORMAT}"
gcloud builds submit --config cloudbuild_gcf.yaml --project $PROJECT_ID --no-source --substitutions=_GIT_SOURCE_BRANCH="master",_GIT_SOURCE_URL="https://github.com/GoogleCloudPlatform/DIY-Tools"

chmod +x loadgen.sh

# Instruction for running the load generator script
echo "${MAGENTA_TEXT}${BOLD_TEXT}Running the load generator script to simulate traffic...${RESET_FORMAT}"
./loadgen.sh

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
