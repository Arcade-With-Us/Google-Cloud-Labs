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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

projectid_check() {
  local project_id=$1
  if [[ -z "$project_id" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: PROJECT_ID is not set.${RESET_FORMAT}"
  fi
}

# Function to set zone and region
lab_setup() {
  echo "${CYAN_TEXT}${BOLD_TEXT}Detecting zone and region from gcloud config...${RESET_FORMAT}"
  # Try to detect zone from gcloud config
  ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
  REGION=$(gcloud config get-value compute/region 2>/dev/null)
  
  # If not set, prompt user
  if [[ -z "$ZONE" ]]; then
    echo "${MAGENTA_TEXT}${BOLD_TEXT}Zone not set in gcloud config.${RESET_FORMAT}"
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the zone: ${RESET_FORMAT}" ZONE
  fi
  
  echo "${GREEN_TEXT}${BOLD_TEXT}Using zone: $ZONE${RESET_FORMAT}"
  if [[ -z "$REGION" ]]; then
    # Derive region from zone if not set
    if [[ -n "$ZONE" ]]; then
      REGION=$(echo $ZONE | awk -F'-' '{print $1"-"$2}')
    else
      read -p "${MAGENTA_TEXT}${BOLD_TEXT}Enter the region: ${RESET_FORMAT}" REGION
    fi
  fi
  
  export ZONE
  export REGION
  echo "${GREEN_TEXT}${BOLD_TEXT}Using zone: $ZONE and region: $REGION${RESET_FORMAT}"
}

# Main script
echo "${CYAN_TEXT}${BOLD_TEXT}Starting lab setup...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Setting up project variables...${RESET_FORMAT}"

# Set project variables
export PROJECT_ID=$(gcloud config get-value project)
projectid_check "$PROJECT_ID"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

# Set zone and region
lab_setup

# Enable services
echo "${CYAN_TEXT}${BOLD_TEXT}Enabling required services...${RESET_FORMAT}"
gcloud services enable \
  cloudkms.googleapis.com \
  cloudbuild.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  containerscanning.googleapis.com \
  ondemandscanning.googleapis.com \
  binaryauthorization.googleapis.com

# Task 1: Create Artifact Registry repository
echo "${CYAN_TEXT}${BOLD_TEXT}Creating Artifact Registry repository...${RESET_FORMAT}"
gcloud artifacts repositories create artifact-scanning-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository"

echo "${CYAN_TEXT}${BOLD_TEXT}Configuring Docker authentication...${RESET_FORMAT}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev

echo "${CYAN_TEXT}${BOLD_TEXT}Creating directory for vulnerability scanning...${RESET_FORMAT}"
mkdir -p vuln-scan && cd vuln-scan

# Create Dockerfile
echo "${CYAN_TEXT}${BOLD_TEXT}Creating Dockerfile...${RESET_FORMAT}"
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

# Create main.py
echo "${CYAN_TEXT}${BOLD_TEXT}Creating main.py...${RESET_FORMAT}"
cat > ./main.py << EOF
import os
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "Worlds")
    return "Hello {}!".format(name)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF

# Build and push image
echo "${CYAN_TEXT}${BOLD_TEXT}Building and pushing Docker image...${RESET_FORMAT}"
gcloud builds submit . -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image

# Task 2: Image Signing
echo "${CYAN_TEXT}${BOLD_TEXT}Setting up image signing...${RESET_FORMAT}"

# Create note
echo "${CYAN_TEXT}${BOLD_TEXT}Creating vulnerability note...${RESET_FORMAT}"
cat > ./vulnz_note.json << EOM
{
  "attestation": {
    "hint": {
      "human_readable_name": "Container Vulnerabilities attestation authority"
    }
  }
}
EOM

NOTE_ID=vulnz_note

echo "${CYAN_TEXT}${BOLD_TEXT}Uploading note to Container Analysis API...${RESET_FORMAT}"
curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data-binary @./vulnz_note.json \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

# Create attestor
ATTESTOR_ID=vulnz-attestor

echo "${CYAN_TEXT}${BOLD_TEXT}Creating attestor...${RESET_FORMAT}"
gcloud container binauthz attestors create $ATTESTOR_ID \
    --attestation-authority-note=$NOTE_ID \
    --attestation-authority-note-project=${PROJECT_ID}

# Set IAM policy
BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

echo "${CYAN_TEXT}${BOLD_TEXT}Setting IAM policy for attestor...${RESET_FORMAT}"
cat > ./iam_request.json << EOM
{
  "resource": "projects/${PROJECT_ID}/notes/${NOTE_ID}",
  "policy": {
    "bindings": [
      {
        "role": "roles/containeranalysis.notes.occurrences.viewer",
        "members": [
          "serviceAccount:${BINAUTHZ_SA_EMAIL}"
        ]
      }
    ]
  }
}
EOM

curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data-binary @./iam_request.json \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

# Task 3: Adding a KMS key
echo "${CYAN_TEXT}${BOLD_TEXT}Setting up KMS key...${RESET_FORMAT}"

KEY_LOCATION=global
KEYRING=binauthz-keys
KEY_NAME=codelab-key
KEY_VERSION=1

echo "${CYAN_TEXT}${BOLD_TEXT}Creating keyring...${RESET_FORMAT}"
gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating asymmetric signing key...${RESET_FORMAT}"
gcloud kms keys create "${KEY_NAME}" \
    --keyring="${KEYRING}" --location="${KEY_LOCATION}" \
    --purpose asymmetric-signing \
    --default-algorithm="ec-sign-p256-sha256"

echo "${CYAN_TEXT}${BOLD_TEXT}Adding public key to attestor...${RESET_FORMAT}"
gcloud beta container binauthz attestors public-keys add \
    --attestor="${ATTESTOR_ID}" \
    --keyversion-project="${PROJECT_ID}" \
    --keyversion-location="${KEY_LOCATION}" \
    --keyversion-keyring="${KEYRING}" \
    --keyversion-key="${KEY_NAME}" \
    --keyversion="${KEY_VERSION}"

# Task 4: Creating a signed attestation
echo "${CYAN_TEXT}${BOLD_TEXT}Creating signed attestation...${RESET_FORMAT}"

CONTAINER_PATH=${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:latest --format='get(image_summary.digest)')

echo "${CYAN_TEXT}${BOLD_TEXT}Signing and creating attestation...${RESET_FORMAT}"
gcloud beta container binauthz attestations sign-and-create \
    --artifact-url="${CONTAINER_PATH}@${DIGEST}" \
    --attestor="${ATTESTOR_ID}" \
    --attestor-project="${PROJECT_ID}" \
    --keyversion-project="${PROJECT_ID}" \
    --keyversion-location="${KEY_LOCATION}" \
    --keyversion-keyring="${KEYRING}" \
    --keyversion-key="${KEY_NAME}" \
    --keyversion="${KEY_VERSION}"

# Task 5: Admission control policies
echo "${CYAN_TEXT}${BOLD_TEXT}Setting up GKE cluster with Binary Authorization...${RESET_FORMAT}"

gcloud beta container clusters create binauthz \
    --zone $ZONE \
    --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/container.developer"

# Task 6: Automatically signing images
echo "${CYAN_TEXT}${BOLD_TEXT}Configuring automatic image signing...${RESET_FORMAT}"

# Add required roles
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
  --role roles/binaryauthorization.attestorsViewer

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
  --role roles/cloudkms.signerVerifier

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --role roles/cloudkms.signerVerifier

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
  --role roles/containeranalysis.notes.attacher

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/ondemandscanning.admin"

echo "${CYAN_TEXT}${BOLD_TEXT}Cloning cloud-builders-community repository...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
cd cloud-builders-community/binauthz-attestation
gcloud builds submit . --config cloudbuild.yaml
cd ../..
rm -rf cloud-builders-community

# Create cloudbuild.yaml
echo "${CYAN_TEXT}${BOLD_TEXT}Creating cloudbuild.yaml...${RESET_FORMAT}"
cat > ./cloudbuild.yaml << EOF
steps:
# build
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

# additional CICD checks (not shown)

#Retag
- id: "retag"
  name: 'gcr.io/cloud-builders/docker'
  args: ['tag',  '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']

#pushing to artifact registry
- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push',  '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']

#Sign the image only if the previous severity check passes
- id: 'create-attestation'
  name: 'gcr.io/${PROJECT_ID}/binauthz-attestation:latest'
  args:
    - '--artifact-url'
    - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good'
    - '--attestor'
    - 'projects/${PROJECT_ID}/attestors/$ATTESTOR_ID'
    - '--keyversion'
    - 'projects/${PROJECT_ID}/locations/$KEY_LOCATION/keyRings/$KEYRING/cryptoKeys/$KEY_NAME/cryptoKeyVersions/$KEY_VERSION'

images:
  - ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good
EOF

# Run the build
echo "${CYAN_TEXT}${BOLD_TEXT}Submitting build to Cloud Build...${RESET_FORMAT}"
gcloud builds submit

# Task 7: Authorizing signed images
echo "${CYAN_TEXT}${BOLD_TEXT}Updating GKE policy to require attestation...${RESET_FORMAT}"

cat > binauth_policy.yaml << EOM
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: REQUIRE_ATTESTATION
  requireAttestationsBy:
  - projects/${PROJECT_ID}/attestors/vulnz-attestor
globalPolicyEvaluationMode: ENABLE
clusterAdmissionRules:
  ${ZONE}.binauthz:
    evaluationMode: REQUIRE_ATTESTATION
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    requireAttestationsBy:
    - projects/${PROJECT_ID}/attestors/vulnz-attestor
EOM

gcloud beta container binauthz policy import binauth_policy.yaml

# Deploy signed image
echo "${CYAN_TEXT}${BOLD_TEXT}Deploying signed image to GKE...${RESET_FORMAT}"
CONTAINER_PATH=${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:good --format='get(image_summary.digest)')

cat > deploy.yaml << EOM
apiVersion: v1
kind: Service
metadata:
  name: deb-httpd
spec:
  selector:
    app: deb-httpd
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deb-httpd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: deb-httpd
  template:
    metadata:
      labels:
        app: deb-httpd
    spec:
      containers:
      - name: deb-httpd
        image: ${CONTAINER_PATH}@${DIGEST}
        ports:
        - containerPort: 8080
        env:
          - name: PORT
            value: "8080"
EOM

kubectl apply -f deploy.yaml

# Task 8: Blocked unsigned Images
echo "${CYAN_TEXT}${BOLD_TEXT}Testing blocked unsigned images...${RESET_FORMAT}"

docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:bad .
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:bad

DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:bad --format='get(image_summary.digest)')

cat > deploy.yaml << EOM
apiVersion: v1
kind: Service
metadata:
  name: deb-httpd
spec:
  selector:
    app: deb-httpd
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deb-httpd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: deb-httpd
  template:
    metadata:
      labels:
        app: deb-httpd
    spec:
      containers:
      - name: deb-httpd
        image: ${CONTAINER_PATH}@${DIGEST}
        ports:
        - containerPort: 8080
        env:
          - name: PORT
            value: "8080"
EOM

kubectl apply -f deploy.yaml

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
