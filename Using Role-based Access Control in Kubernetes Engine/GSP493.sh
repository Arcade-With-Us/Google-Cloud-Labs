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

echo "${BLUE_TEXT}${BOLD_TEXT}📋 Step 1: Verifying Authentication Status${RESET_FORMAT}"
echo
gcloud auth list

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Step 2: Setting Up Regional Configuration${RESET_FORMAT}"
echo "${YELLOW_TEXT}Extracting default zone and region from project metadata...${RESET_FORMAT}"
echo

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Configuring default compute settings for your project${RESET_FORMAT}"
echo "${WHITE_TEXT}Setting region to: ${GREEN_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo "${WHITE_TEXT}Setting zone to: ${GREEN_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🔍 Step 3: Examining GKE Cluster Status${RESET_FORMAT}"
echo "${YELLOW_TEXT}Retrieving list of available Kubernetes clusters...${RESET_FORMAT}"
echo

gcloud container clusters list

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔐 Checking RBAC Configuration${RESET_FORMAT}"
echo "${YELLOW_TEXT}Verifying legacy ABAC settings for rbac-demo-cluster...${RESET_FORMAT}"
echo

gcloud container clusters describe rbac-demo-cluster --zone=$ZONE --format="value(legacyAbac.enabled)"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}👤 Step 4: Service Account Inventory${RESET_FORMAT}"
echo "${YELLOW_TEXT}Listing all service accounts in your project...${RESET_FORMAT}"
echo

gcloud iam service-accounts list

echo
echo "${CYAN_TEXT}${BOLD_TEXT}💻 Step 5: Compute Instance Overview${RESET_FORMAT}"
echo "${YELLOW_TEXT}Displaying all compute instances in your project...${RESET_FORMAT}"
echo

gcloud compute instances list

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}📝 Step 6: Creating Admin Setup Script${RESET_FORMAT}"
echo "${YELLOW_TEXT}Generating configuration script for GKE tutorial admin instance...${RESET_FORMAT}"
echo

cat > cp.sh <<'EOF_CP'
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin

echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc

source ~/.bashrc

export ZONE=$(gcloud container clusters list --format="value(location)" --filter="name=rbac-demo-cluster")
echo $ZONE

gcloud container clusters get-credentials rbac-demo-cluster --zone "$ZONE"

kubectl apply -f ./manifests/rbac.yaml

EOF_CP

echo "${BLUE_TEXT}${BOLD_TEXT}📤 Step 7: Transferring Setup Script${RESET_FORMAT}"
echo "${YELLOW_TEXT}Copying configuration script to gke-tutorial-admin instance...${RESET_FORMAT}"
echo

gcloud compute scp cp.sh gke-tutorial-admin:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔧 Step 8: Executing Admin Configuration${RESET_FORMAT}"
echo "${YELLOW_TEXT}Running setup script on gke-tutorial-admin instance...${RESET_FORMAT}"
echo

gcloud compute ssh gke-tutorial-admin --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/cp.sh"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}⏳ Pausing execution for system stabilization...${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}System stabilization in progress...${RESET_FORMAT}"
for i in {10..1}; do
  echo -ne "\r${CYAN_TEXT}⏳ $i seconds remaining...${RESET_FORMAT}"
  sleep 1
done
echo -e "\r${GREEN_TEXT}✅ System stabilization complete!${RESET_FORMAT}    "

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}👑 Step 9: Owner Instance Configuration${RESET_FORMAT}"
echo "${YELLOW_TEXT}Setting up GKE authentication and deploying hello-server across namespaces...${RESET_FORMAT}"
echo

gcloud compute ssh gke-tutorial-owner --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command='
  sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin &&
  echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc &&
  source ~/.bashrc &&
  export ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | awk -F'/' "{print \$NF}") &&
  gcloud container clusters get-credentials rbac-demo-cluster --zone "$ZONE" &&
  kubectl create -n dev -f ./manifests/hello-server.yaml &&
  kubectl create -n prod -f ./manifests/hello-server.yaml &&
  kubectl create -n test -f ./manifests/hello-server.yaml
'

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ System synchronization in progress...${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}System synchronization in progress...${RESET_FORMAT}"
for i in {10..1}; do
  echo -ne "\r${CYAN_TEXT}⏳ $i seconds remaining...${RESET_FORMAT}"
  sleep 1
done
echo -e "\r${GREEN_TEXT}✅ System synchronization complete!${RESET_FORMAT}    "

echo
echo "${RED_TEXT}${BOLD_TEXT}🔍 Step 10: Auditor Permission Testing${RESET_FORMAT}"
echo "${YELLOW_TEXT}Configuring auditor instance and testing RBAC permissions...${RESET_FORMAT}"
echo

gcloud compute ssh gke-tutorial-auditor --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command='
  sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin &&
  echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc &&
  source ~/.bashrc &&
  gcloud container clusters get-credentials rbac-demo-cluster --zone "$ZONE" &&
  kubectl get pods -l app=hello-server --all-namespaces ||
  kubectl get pods -l app=hello-server --namespace=dev &&
  kubectl get pods -l app=hello-server --namespace=test ||
  kubectl get pods -l app=hello-server --namespace=prod ||
  kubectl create -n dev -f manifests/hello-server.yaml ||
  kubectl delete deployment -n dev -l app=hello-server ||
  true
'

echo
echo "${GREEN_TEXT}${BOLD_TEXT}⏳ Processing interval...${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}Processing in progress...${RESET_FORMAT}"
for i in {10..1}; do
  echo -ne "\r${CYAN_TEXT}⏳ $i seconds remaining...${RESET_FORMAT}"
  sleep 1
done
echo -e "\r${GREEN_TEXT}✅ Processing complete!${RESET_FORMAT}       "

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🏷️  Step 11: Pod Labeler Deployment${RESET_FORMAT}"
echo "${YELLOW_TEXT}Deploying pod-labeler service and examining its behavior...${RESET_FORMAT}"
echo

gcloud compute ssh gke-tutorial-admin --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command='
  kubectl apply -f manifests/pod-labeler.yaml &&
  kubectl get pods -l app=pod-labeler &&
  kubectl describe pod -l app=pod-labeler | tail -n 20 &&
  kubectl logs -l app=pod-labeler &&
  kubectl get pod -o yaml -l app=pod-labeler &&
  kubectl apply -f manifests/pod-labeler-fix-1.yaml &&
  kubectl get deployment pod-labeler -o yaml
'

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}⏳ Stabilization period...${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}Stabilization in progress...${RESET_FORMAT}"
for i in {10..1}; do
  echo -ne "\r${CYAN_TEXT}⏳ $i seconds remaining...${RESET_FORMAT}"
  sleep 1
done
echo -e "\r${GREEN_TEXT}✅ Stabilization complete!${RESET_FORMAT}       "

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📊 Step 12: Audit Log Analysis${RESET_FORMAT}"
echo "${YELLOW_TEXT}Examining Kubernetes API audit logs for pod patch operations...${RESET_FORMAT}"
echo

gcloud logging read 'protoPayload.methodName="io.k8s.core.v1.pods.patch"' \
  --format="table(timestamp, protoPayload.authenticationInfo.principalEmail, protoPayload.resourceName)"

echo
echo "${RED_TEXT}${BOLD_TEXT}⏳ Final processing delay...${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}Final processing in progress...${RESET_FORMAT}"
for i in {10..1}; do
  echo -ne "\r${CYAN_TEXT}⏳ $i seconds remaining...${RESET_FORMAT}"
  sleep 1
done
echo -e "\r${GREEN_TEXT}✅ Final processing complete!${RESET_FORMAT}    "

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔧 Step 13: Final Pod Labeler Configuration${RESET_FORMAT}"
echo "${YELLOW_TEXT}Applying final fixes and examining RBAC role bindings...${RESET_FORMAT}"
echo

gcloud compute ssh gke-tutorial-admin --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command='
  kubectl get pods -l app=pod-labeler &&
  kubectl logs -l app=pod-labeler &&
  kubectl get rolebinding pod-labeler -o yaml &&
  kubectl get role pod-labeler -o yaml &&
  kubectl apply -f manifests/pod-labeler-fix-2.yaml'

echo
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
