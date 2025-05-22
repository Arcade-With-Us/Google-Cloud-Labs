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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE:${NO_COLOR}"
read -p "${BOLD_TEXT}Zone: ${NO_COLOR}" ZONE
export ZONE
export REGION="${ZONE%-*}"

echo "${BOLD_TEXT}${GREEN_TEXT}Enabling required GCP services...${NO_COLOR}"
gcloud services enable compute.googleapis.com 
gcloud services enable container.googleapis.com 
gcloud services enable containerregistry.googleapis.com 
gcloud services enable containeranalysis.googleapis.com 
gcloud services enable binaryauthorization.googleapis.com 

echo "${BOLD_TEXT}${CYAN_TEXT}Waiting for services to be enabled...${NO_COLOR}"
sleep 50

echo "${BOLD_TEXT}${GREEN_TEXT}Copying demo files from Google Cloud Storage...${NO_COLOR}"
gsutil -m cp -r gs://spls/gke-binary-auth/* .

echo "${BOLD_TEXT}${CYAN_TEXT}Navigating to the demo directory...${NO_COLOR}"
cd gke-binary-auth-demo

echo "${BOLD_TEXT}${GREEN_TEXT}Setting compute region and zone...${NO_COLOR}"
gcloud config set compute/region $REGION    
gcloud config set compute/zone $ZONE

echo "${BOLD_TEXT}${CYAN_TEXT}Making scripts executable...${NO_COLOR}"
chmod +x create.sh
chmod +x delete.sh
chmod 777 validate.sh

echo "${BOLD_TEXT}${GREEN_TEXT}Modifying create.sh script...${NO_COLOR}"
sed -i 's/validMasterVersions\[0\]/defaultClusterVersion/g' ./create.sh

echo "${BOLD_TEXT}${CYAN_TEXT}Creating GKE cluster...${NO_COLOR}"
./create.sh -c my-cluster-1

echo "${BOLD_TEXT}${GREEN_TEXT}Validating the cluster setup...${NO_COLOR}"
./validate.sh -c my-cluster-1

echo "${BOLD_TEXT}${CYAN_TEXT}Exporting Binary Authorization policy...${NO_COLOR}"
gcloud beta container binauthz policy export > policy.yaml

echo "${BOLD_TEXT}${GREEN_TEXT}Updating Binary Authorization policy...${NO_COLOR}"
cat > policy.yaml <<EOF_END
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
globalPolicyEvaluationMode: ENABLE
clusterAdmissionRules:
  $ZONE.my-cluster-1:
    evaluationMode: ALWAYS_ALLOW
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
name: projects/$DEVSHELL_PROJECT_ID/policy
EOF_END

echo "${BOLD_TEXT}${CYAN_TEXT}Importing updated policy...${NO_COLOR}"
gcloud beta container binauthz policy import policy.yaml

echo "${BOLD_TEXT}${GREEN_TEXT}Pulling and pushing Docker image...${NO_COLOR}"
docker pull gcr.io/google-containers/nginx:latest
gcloud auth configure-docker --quiet

PROJECT_ID="$(gcloud config get-value project)"
docker tag gcr.io/google-containers/nginx "gcr.io/${PROJECT_ID}/nginx:latest"
docker push "gcr.io/${PROJECT_ID}/nginx:latest"

echo "${BOLD_TEXT}${CYAN_TEXT}Listing Docker image tags...${NO_COLOR}"
gcloud container images list-tags "gcr.io/${PROJECT_ID}/nginx"

echo "${BOLD_TEXT}${GREEN_TEXT}Creating Kubernetes Pod...${NO_COLOR}"
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: "gcr.io/${PROJECT_ID}/nginx:latest"
    ports:
    - containerPort: 80
EOF

echo "${BOLD_TEXT}${CYAN_TEXT}Getting Kubernetes Pods...${NO_COLOR}"
kubectl get pods

echo "${BOLD_TEXT}${GREEN_TEXT}Deleting Kubernetes Pod...${NO_COLOR}"
kubectl delete pod nginx

echo "${BOLD_TEXT}${CYAN_TEXT}Exporting Binary Authorization policy again...${NO_COLOR}"
gcloud beta container binauthz policy export > policy.yaml

echo "${BOLD_TEXT}${GREEN_TEXT}Updating Binary Authorization policy to enforce denial...${NO_COLOR}"
cat > policy.yaml <<EOF_END
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
globalPolicyEvaluationMode: ENABLE
clusterAdmissionRules:
  $ZONE.my-cluster-1:
    evaluationMode: ALWAYS_DENY
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
name: projects/$DEVSHELL_PROJECT_ID/policy
EOF_END

echo "${BOLD_TEXT}${CYAN_TEXT}Importing updated policy...${NO_COLOR}"
gcloud beta container binauthz policy import policy.yaml

echo "${BOLD_TEXT}${GREEN_TEXT}Creating Kubernetes Pod again...${NO_COLOR}"
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: "gcr.io/${PROJECT_ID}/nginx:latest"
    ports:
    - containerPort: 80
EOF

echo "${BOLD_TEXT}${CYAN_TEXT}Filtering logs for policy violations...${NO_COLOR}"
gcloud logging read "resource.type='k8s_cluster'  AND protoPayload.response.reason='VIOLATES_POLICY'" --project=$DEVSHELL_PROJECT_ID

echo "${BOLD_TEXT}${GREEN_TEXT}Running a specific query...${NO_COLOR}"
gcloud logging read "resource.type='k8s_cluster'  AND protoPayload.response.reason='VIOLATES_POLICY'" --project=$DEVSHELL_PROJECT_ID --format=json

IMAGE_PATH=$(echo "gcr.io/${PROJECT_ID}/nginx*")

echo "${BOLD_TEXT}${CYAN_TEXT}Updating Binary Authorization policy with whitelist...${NO_COLOR}"
cat > policy.yaml <<EOF_END
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: ALWAYS_DENY
globalPolicyEvaluationMode: ENABLE
clusterAdmissionRules:
  $ZONE.my-cluster-1:
    evaluationMode: ALWAYS_DENY
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
admissionWhitelistPatterns:
- namePattern: "gcr.io/${DEVSHELL_PROJECT_ID}/nginx*"
name: projects/$DEVSHELL_PROJECT_ID/policy
EOF_END

echo "${BOLD_TEXT}${GREEN_TEXT}Importing updated policy...${NO_COLOR}"
gcloud beta container binauthz policy import policy.yaml

echo "${BOLD_TEXT}${CYAN_TEXT}Creating Kubernetes Pod with whitelisted image...${NO_COLOR}"
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: "gcr.io/${PROJECT_ID}/nginx:latest"
    ports:
    - containerPort: 80
EOF

echo "${BOLD_TEXT}${GREEN_TEXT}Deleting Kubernetes Pod...${NO_COLOR}"
kubectl delete pod nginx

ATTESTOR="manually-verified" # No spaces allowed
ATTESTOR_NAME="Manual Attestor"
ATTESTOR_EMAIL="$(gcloud config get-value core/account)" # This uses your current user/email

NOTE_ID="Human-Attestor-Note" # No spaces
NOTE_DESC="Human Attestation Note Demo"

NOTE_PAYLOAD_PATH="note_payload.json"
IAM_REQUEST_JSON="iam_request.json"

echo "${BOLD_TEXT}${CYAN_TEXT}Creating attestation note payload...${NO_COLOR}"
cat > ${NOTE_PAYLOAD_PATH} << EOF
{
  "name": "projects/${PROJECT_ID}/notes/${NOTE_ID}",
  "attestation_authority": {
    "hint": {
      "human_readable_name": "${NOTE_DESC}"
    }
  }
}
EOF

echo "${BOLD_TEXT}${GREEN_TEXT}Creating attestation note...${NO_COLOR}"
curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    --data-binary @${NOTE_PAYLOAD_PATH}  \
    "https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

echo "${BOLD_TEXT}${CYAN_TEXT}Fetching attestation note...${NO_COLOR}"
curl -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    "https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECT_ID}/notes/${NOTE_ID}"

PGP_PUB_KEY="generated-key.pgp"

echo "${BOLD_TEXT}${GREEN_TEXT}Installing rng-tools...${NO_COLOR}"
sudo apt-get install rng-tools -y

echo "${BOLD_TEXT}${CYAN_TEXT}Generating entropy...${NO_COLOR}"
sudo rngd -r /dev/urandom -y

echo "${BOLD_TEXT}${GREEN_TEXT}Creating attestor...${NO_COLOR}"
gcloud --project="${PROJECT_ID}" \
    beta container binauthz attestors create "${ATTESTOR}" \
    --attestation-authority-note="${NOTE_ID}" \
    --attestation-authority-note-project="${PROJECT_ID}"

echo "${BOLD_TEXT}${CYAN_TEXT}Adding public key to attestor...${NO_COLOR}"
gcloud --project="${PROJECT_ID}" \
    beta container binauthz attestors public-keys add \
    --attestor="${ATTESTOR}" \
    --pgp-public-key-file="${PGP_PUB_KEY}"

echo "${BOLD_TEXT}${GREEN_TEXT}Listing attestors...${NO_COLOR}"
gcloud --project="${PROJECT_ID}" \
    beta container binauthz attestors list

GENERATED_PAYLOAD="generated_payload.json"
GENERATED_SIGNATURE="generated_signature.pgp"

PGP_FINGERPRINT="$(gpg --list-keys ${ATTESTOR_EMAIL} | head -2 | tail -1 | awk '{print $1}')"

IMAGE_PATH="gcr.io/${PROJECT_ID}/nginx"
IMAGE_DIGEST="$(gcloud container images list-tags --format='get(digest)' $IMAGE_PATH | head -1)"

echo "${BOLD_TEXT}${CYAN_TEXT}Creating signature payload...${NO_COLOR}"
gcloud beta container binauthz create-signature-payload \
    --artifact-url="${IMAGE_PATH}@${IMAGE_DIGEST}" > ${GENERATED_PAYLOAD}

echo "${BOLD_TEXT}${GREEN_TEXT}Signing payload...${NO_COLOR}"
gpg --local-user "${ATTESTOR_EMAIL}" \
    --armor \
    --output ${GENERATED_SIGNATURE} \
    --sign ${GENERATED_PAYLOAD}

echo "${BOLD_TEXT}${CYAN_TEXT}Creating attestation...${NO_COLOR}"
gcloud beta container binauthz attestations create \
    --artifact-url="${IMAGE_PATH}@${IMAGE_DIGEST}" \
    --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR}" \
    --signature-file=${GENERATED_SIGNATURE} \
    --public-key-id="${PGP_FINGERPRINT}"

echo "${BOLD_TEXT}${GREEN_TEXT}Listing attestations...${NO_COLOR}"
gcloud beta container binauthz attestations list \
    --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR}"

echo "${BOLD_TEXT}${CYAN_TEXT}Importing Binary Authorization policy...${NO_COLOR}"
gcloud beta container binauthz policy import policy.yaml

echo "${BOLD_TEXT}${GREEN_TEXT}Updating Binary Authorization policy to require attestations...${NO_COLOR}"
gcloud beta container binauthz policy update \
--project=${PROJECT_ID} \
--require-attestations \
--attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR}"

echo "${BOLD_TEXT}${CYAN_TEXT}Creating Kubernetes Pod with attested image...${NO_COLOR}"
IMAGE_PATH="gcr.io/${PROJECT_ID}/nginx"
IMAGE_DIGEST="$(gcloud container images list-tags --format='get(digest)' $IMAGE_PATH | head -1)"

cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: "${IMAGE_PATH}@${IMAGE_DIGEST}"
    ports:
    - containerPort: 80
EOF

echo "${BOLD_TEXT}${GREEN_TEXT}Creating Kubernetes Pod with break-glass annotation...${NO_COLOR}"
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-alpha
  annotations:
    alpha.image-policy.k8s.io/break-glass: "true"
spec:
  containers:
  - name: nginx
    image: "nginx:latest"
    ports:
    - containerPort: 80
EOF

echo "${BOLD_TEXT}${CYAN_TEXT}Deleting GKE cluster...${NO_COLOR}"
./delete.sh -c my-cluster-1

echo "${CYAN_TEXT}${BOLD_TEXT}Attestor resource path: projects/${PROJECT_ID}/attestors/${ATTESTOR}${NO_COLOR}"
echo "${CYAN_TEXT}${BOLD_TEXT}Binary Authorization policy URL: https://console.cloud.google.com/security/binary-authorization/policy?referrer=search&project=$DEVSHELL_PROJECT_ID${NO_COLOR}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
