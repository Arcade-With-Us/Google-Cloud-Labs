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
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}⚙️  Gathering essential Google Cloud project details...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

echo "${CYAN_TEXT}Project ID set to: ${WHITE_TEXT}${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo "${CYAN_TEXT}Project Number identified as: ${WHITE_TEXT}${BOLD_TEXT}$PROJECT_NUMBER${RESET_FORMAT}"
echo "${CYAN_TEXT}Default Zone is: ${WHITE_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo "${CYAN_TEXT}Default Region derived as: ${WHITE_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}🛠️  Activating necessary Google Cloud APIs for the project...${RESET_FORMAT}"
gcloud services enable \
  cloudkms.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  containerscanning.googleapis.com \
  ondemandscanning.googleapis.com \
  binaryauthorization.googleapis.com
echo "${GREEN_TEXT}✅ Services have been successfully enabled!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}📁 Setting up the directory structure and fetching sample application files...${RESET_FORMAT}"
mkdir sample-app && cd sample-app
gcloud storage cp gs://spls/gsp521/* .
echo "${GREEN_TEXT}✅ Sample application directory created and files copied!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}📦 Creating Docker repositories in Artifact Registry for scanning and production...${RESET_FORMAT}"
gcloud artifacts repositories create artifact-scanning-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Scanning repository"

gcloud artifacts repositories create artifact-prod-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Production repository"

echo "${YELLOW_TEXT}🔑 Configuring Docker authentication for the Artifact Registry...${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev
echo "${GREEN_TEXT}✅ Artifact Registry repositories created and Docker configured!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}👤 Granting necessary IAM roles to the Cloud Build service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/ondemandscanning.admin"
echo "${GREEN_TEXT}✅ Required IAM permissions granted successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}📝 Creating the initial Cloud Build configuration file (cloudbuild.yaml)...${RESET_FORMAT}"
cat > cloudbuild.yaml <<EOF
steps:
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image']

images:
  - ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF

echo "${YELLOW_TEXT}🏗️ Submitting the initial build process to Cloud Build...${RESET_FORMAT}"
gcloud builds submit
echo "${GREEN_TEXT}✅ Initial application build and push completed!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}🛡️  Creating a Container Analysis note for vulnerability attestations...${RESET_FORMAT}"
cat > ./vulnerability_note.json << EOM
{
"attestation": {
"hint": {
 "human_readable_name": "Container Vulnerabilities attestation authority"
}
}
}
EOM

NOTE_ID=vulnerability_note
echo "${YELLOW_TEXT}📡 Sending request to create the Container Analysis note...${RESET_FORMAT}"
curl -X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
--data-binary @./vulnerability_note.json \
"https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"
echo "${GREEN_TEXT}✅ Vulnerability note successfully created!${RESET_FORMAT}"

echo "${YELLOW_TEXT}✍️  Creating a Binary Authorization attestor linked to the note...${RESET_FORMAT}"
ATTESTOR_ID=vulnerability-attestor
gcloud container binauthz attestors create $ATTESTOR_ID \
--attestation-authority-note=$NOTE_ID \
--attestation-authority-note-project=${PROJECT_ID}
echo "${GREEN_TEXT}✅ Binary Authorization attestor created!${RESET_FORMAT}"

echo "${YELLOW_TEXT}🔐 Configuring IAM permissions for the Binary Authorization service account on the note...${RESET_FORMAT}"
BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
cat > ./iam_request.json << EOM
{
'resource': 'projects/${PROJECT_ID}/notes/${NOTE_ID}',
'policy': {
'bindings': [
 {
   'role': 'roles/containeranalysis.notes.occurrences.viewer',
   'members': [
     'serviceAccount:${BINAUTHZ_SA_EMAIL}'
   ]
 }
]
}
}
EOM

echo "${YELLOW_TEXT}📡 Sending request to set IAM policy for the note...${RESET_FORMAT}"
curl -X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
--data-binary @./iam_request.json \
"https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"
echo "${GREEN_TEXT}✅ IAM permissions configured for the attestor!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}🔑 Creating a KMS keyring and an asymmetric signing key for attestations...${RESET_FORMAT}"
KEY_LOCATION=global
KEYRING=binauthz-keys
KEY_NAME=lab-key
KEY_VERSION=1

gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}"

gcloud kms keys create "${KEY_NAME}" \
--keyring="${KEYRING}" --location="${KEY_LOCATION}" \
--purpose asymmetric-signing \
--default-algorithm="ec-sign-p256-sha256"

echo "${YELLOW_TEXT}🔗 Associating the KMS key's public part with the Binary Authorization attestor...${RESET_FORMAT}"
gcloud beta container binauthz attestors public-keys add \
--attestor="${ATTESTOR_ID}" \
--keyversion-project="${PROJECT_ID}" \
--keyversion-location="${KEY_LOCATION}" \
--keyversion-keyring="${KEYRING}" \
--keyversion-key="${KEY_NAME}" \
--keyversion="${KEY_VERSION}"
echo "${GREEN_TEXT}✅ KMS keyring, key, and attestor association complete!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}📜 Defining the Binary Authorization policy to require attestations...${RESET_FORMAT}"
cat > my_policy.yaml << EOM
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: REQUIRE_ATTESTATION
  requireAttestationsBy:
    - projects/${PROJECT_ID}/attestors/vulnerability-attestor
globalPolicyEvaluationMode: ENABLE
name: projects/${PROJECT_ID}/policy
EOM

echo "${YELLOW_TEXT}🚢 Importing the defined policy into Binary Authorization...${RESET_FORMAT}"
gcloud container binauthz policy import my_policy.yaml
echo "${GREEN_TEXT}✅ Binary Authorization policy successfully configured!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}➕ Granting further necessary IAM roles for build and deployment processes...${RESET_FORMAT}"
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
echo "${GREEN_TEXT}✅ Additional IAM permissions granted!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}🔗 Cloning the community cloud builders repository for the attestation builder...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
cd cloud-builders-community/binauthz-attestation
echo "${YELLOW_TEXT}🛠️ Building the custom BinAuthz attestation Cloud Builder...${RESET_FORMAT}"
gcloud builds submit . --config cloudbuild.yaml
cd ../..
echo "${YELLOW_TEXT}🧹 Cleaning up the cloned repository...${RESET_FORMAT}"
rm -rf cloud-builders-community
echo "${GREEN_TEXT}✅ Custom attestation builder setup is complete!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}📝 Creating the final, comprehensive Cloud Build pipeline configuration...${RESET_FORMAT}"
cat <<EOF > cloudbuild.yaml
steps:
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest', '.']
  waitFor: ['-']

- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest']

- id: scan
  name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
      (gcloud artifacts docker images scan \\
      ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest \\
      --location us \\
      --format="value(response.scan)") > /workspace/scan_id.txt

- id: severity check
  name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
      gcloud artifacts docker images list-vulnerabilities \$(cat /workspace/scan_id.txt) \\
      --format="value(vulnerability.effectiveSeverity)" | if grep -Fxq CRITICAL; \\
      then echo "Failed vulnerability check for CRITICAL level" && exit 1; else echo \\
      "No CRITICAL vulnerability found, congrats !" && exit 0; fi

- id: 'create-attestation'
  name: 'gcr.io/${PROJECT_ID}/binauthz-attestation:latest'
  args:
    - '--artifact-url'
    - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest'
    - '--attestor'
    - 'projects/${PROJECT_ID}/attestors/vulnerability-attestor'
    - '--keyversion'
    - 'projects/${PROJECT_ID}/locations/global/keyRings/binauthz-keys/cryptoKeys/lab-key/cryptoKeyVersions/1'

- id: "push-to-prod"
  name: 'gcr.io/cloud-builders/docker'
  args:
    - 'tag'
    - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest'
    - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-prod-repo/sample-image:latest'
- id: "push-to-prod-final"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-prod-repo/sample-image:latest']

- id: 'deploy-to-cloud-run'
  name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
    gcloud run deploy auth-service --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest \
    --binary-authorization=default --region=$REGION --allow-unauthenticated

images:
  - ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest
EOF

echo "${YELLOW_TEXT}🚀 Executing the final build pipeline including scan, attest, and deploy steps...${RESET_FORMAT}"
gcloud builds submit
echo "${GREEN_TEXT}✅ Final build pipeline executed successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}🔄 Updating application dependencies in the Dockerfile...${RESET_FORMAT}"
cat > ./Dockerfile << EOF
FROM python:3.8-alpine

# App
WORKDIR /app
COPY . ./

RUN pip3 install Flask==3.0.3
RUN pip3 install gunicorn==23.0.0
RUN pip3 install Werkzeug==3.0.4

CMD exec gunicorn --bind :\$PORT --workers 1 --threads 8 main:app
EOF

echo "${YELLOW_TEXT}🏗️ Submitting a new build to reflect the dependency updates...${RESET_FORMAT}"
gcloud builds submit
echo "${GREEN_TEXT}✅ Application dependencies updated and rebuilt successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}☁️  Configuring the deployed Cloud Run service to allow public access...${RESET_FORMAT}"
gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker auth-service
echo "${GREEN_TEXT}✅ Cloud Run service permissions configured for public access!${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 If you found this helpful, please subscribe to Arcade With Us! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
