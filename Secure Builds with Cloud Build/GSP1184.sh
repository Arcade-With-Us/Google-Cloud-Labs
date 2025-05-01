#!/bin/bash

# Bright Foreground Colors
BRIGHT_BLACK_TEXT=$'\033[0;90m'
BRIGHT_RED_TEXT=$'\033[0;91m'
BRIGHT_GREEN_TEXT=$'\033[0;92m'
BRIGHT_YELLOW_TEXT=$'\033[0;93m'
BRIGHT_BLUE_TEXT=$'\033[0;94m'
BRIGHT_MAGENTA_TEXT=$'\033[0;95m'
BRIGHT_CYAN_TEXT=$'\033[0;96m'
BRIGHT_WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

# Start of the script
echo
echo "${BRIGHT_MAGENTA_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

echo "${BRIGHT_CYAN_TEXT}${BOLD_TEXT}Fetching project details...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
    --format='value(projectNumber)')

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Enabling necessary Google Cloud services...${RESET_FORMAT}"
gcloud services enable \
  cloudkms.googleapis.com \
  cloudbuild.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  containerscanning.googleapis.com \
  ondemandscanning.googleapis.com \
  binaryauthorization.googleapis.com

echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Granting required IAM permissions...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/ondemandscanning.admin"

echo "${BRIGHT_BLUE_TEXT}${BOLD_TEXT}Creating and navigating to project directory...${RESET_FORMAT}"
mkdir vuln-scan && cd vuln-scan

echo "${BRIGHT_MAGENTA_TEXT}${BOLD_TEXT}Creating Dockerfile...${RESET_FORMAT}"
cat > ./Dockerfile << EOF
FROM gcr.io/google-appengine/debian10@sha256:d25b680d69e8b386ab189c3ab45e219fededb9f91e1ab51f8e999f3edc40d2a1

# System
RUN apt update && apt install python3-pip -y

# App
WORKDIR /app
COPY . ./

RUN pip3 install Flask==1.1.4  
RUN pip3 install gunicorn==20.1.0  

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
EOF

echo "${BRIGHT_CYAN_TEXT}${BOLD_TEXT}Creating main.py...${RESET_FORMAT}"
cat > ./main.py << EOF
import os
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "World")
    return "Hello {}!".format(name)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Creating Cloud Build YAML file...${RESET_FORMAT}"
cat > ./cloudbuild.yaml << EOF
steps:

# build
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']
EOF

echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Submitting Cloud Build...${RESET_FORMAT}"
gcloud builds submit

echo "${BRIGHT_BLUE_TEXT}${BOLD_TEXT}Creating Artifact Registry...${RESET_FORMAT}"
gcloud artifacts repositories create artifact-scanning-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository"

# Authenticate with Google Cloud
echo "${BRIGHT_BLUE_TEXT}${BOLD_TEXT}Authenticating Docker with Google Cloud...${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev

echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Creating cloudbuild.yaml file...${RESET_FORMAT}"
cat > ./cloudbuild.yaml << EOF
steps:

# build
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

# push to artifact registry
- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push',  '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image']

images:
  - $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Submitting the Cloud Build...${RESET_FORMAT}"
gcloud builds submit

echo "${BRIGHT_CYAN_TEXT}${BOLD_TEXT}Building the Docker image locally...${RESET_FORMAT}"
docker build -t $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image .

echo "${BRIGHT_MAGENTA_TEXT}${BOLD_TEXT}Scanning the Docker image for vulnerabilities...${RESET_FORMAT}"
gcloud artifacts docker images scan \
    $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image \
    --format="value(response.scan)" > scan_id.txt

echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Scan ID stored in scan_id.txt. Fetching results...${RESET_FORMAT}"
cat scan_id.txt

gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt)

echo "${BRIGHT_RED_TEXT}${BOLD_TEXT}Checking for critical vulnerabilities...${RESET_FORMAT}"
export SEVERITY=CRITICAL
gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) --format="value(vulnerability.effectiveSeverity)" | if grep -Fxq ${SEVERITY}; then echo "${BRIGHT_RED_TEXT}${BOLD_TEXT}Failed vulnerability check for ${SEVERITY} level${RESET_FORMAT}"; else echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}No ${SEVERITY} vulnerabilities found${RESET_FORMAT}"; fi

echo "${BRIGHT_BLUE_TEXT}${BOLD_TEXT}Granting IAM permissions to Cloud Build service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/ondemandscanning.admin"

echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Creating a more detailed cloudbuild.yaml...${RESET_FORMAT}"
cat > ./cloudbuild.yaml << EOF
steps:

# build
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

# Run a vulnerability scan
- id: "scan"
  name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
    gcloud artifacts docker images scan \
    $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image \
    --location us \
    --format="value(response.scan)" > /workspace/scan_id.txt

# Analyze the result of the scan
- id: "severity_check"
  name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
    gcloud artifacts docker images list-vulnerabilities \$(cat /workspace/scan_id.txt) \
    --format="value(vulnerability.effectiveSeverity)" | if grep -Fxq CRITICAL; \
    then echo "Failed vulnerability check for CRITICAL level" && exit 1; else echo "No CRITICAL vulnerability found!" && exit 0; fi

# Retagging and pushing
- id: "retag"
  name: 'gcr.io/cloud-builders/docker'
  args: ['tag', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']

- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']

images:
  - $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF

echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Submitting final Cloud Build...${RESET_FORMAT}"
gcloud builds submit

echo "${BRIGHT_CYAN_TEXT}${BOLD_TEXT}Creating Dockerfile...${RESET_FORMAT}"
cat > ./Dockerfile << EOF
FROM python:3.8-alpine 

# App
WORKDIR /app
COPY . ./

RUN pip3 install Flask==2.1.0
RUN pip3 install gunicorn==20.1.0
RUN pip3 install Werkzeug==2.2.2

CMD exec gunicorn --bind :\$PORT --workers 1 --threads 8 main:app
EOF

echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Submitting final build with Dockerfile...${RESET_FORMAT}"
gcloud builds submit
echo

# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
