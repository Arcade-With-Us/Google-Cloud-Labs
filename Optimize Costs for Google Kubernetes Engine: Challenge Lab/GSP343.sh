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

# ======================
#  USER INPUT SECTION
# ======================
echo "${BOLD}${MAGENTA}🔧 Please provide the following configuration values:${RESET}"

# Export the variables name correctly
read -p "${WHITE}Enter the ZONE (e.g. us-central1-a): ${YELLOW}" ZONE
read -p "${WHITE}Enter the CLUSTER_NAME (e.g. autoscale-cluster): ${YELLOW}" CLUSTER_NAME
read -p "${WHITE}Enter the POOL_NAME (e.g. worker-pool): ${YELLOW}" POOL_NAME
read -p "${WHITE}Enter the MAX_REPLICAS (e.g. 5): ${YELLOW}" MAX_REPLICAS

echo "${RESET}"
echo "${GREEN}✔ Configuration values received${RESET}"
echo ""

# ======================
#  INITIAL SETUP
# ======================
echo "${BOLD}${BLUE}🔐 STEP 1: Verifying Authentication${RESET}"
gcloud auth list
echo ""

PROJECT=$(gcloud config get-value project)
echo "${WHITE}Current Project: ${YELLOW}$PROJECT${RESET}"
echo ""

# ======================
#  CLUSTER CREATION
# ======================
echo "${BOLD}${GREEN}☸️ STEP 2: Creating GKE Cluster${RESET}"
gcloud container clusters create $CLUSTER_NAME \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --num-nodes=2 || {
    echo "${RED}${BOLD}❌ Failed to create cluster${RESET}"
    exit 1
}
echo "${GREEN}✔ Cluster created successfully${RESET}"
echo ""

# ======================
#  NAMESPACE SETUP
# ======================
echo "${BOLD}${CYAN}📦 STEP 3: Creating Namespaces${RESET}"
kubectl create namespace dev
kubectl create namespace prod
echo "${GREEN}✔ Namespaces created${RESET}"
echo ""

# ======================
#  APPLICATION DEPLOYMENT
# ======================
echo "${BOLD}${YELLOW}🚀 STEP 4: Deploying Microservices Demo${RESET}"
git clone -q https://github.com/GoogleCloudPlatform/microservices-demo.git &&
cd microservices-demo && 
kubectl apply -f ./release/kubernetes-manifests.yaml --namespace dev || {
    echo "${RED}${BOLD}❌ Failed to deploy microservices${RESET}"
    exit 1
}
echo "${GREEN}✔ Microservices deployed to dev namespace${RESET}"
echo ""

# ======================
#  NODE POOL SETUP
# ======================
echo "${BOLD}${MAGENTA}🛠️ STEP 5: Creating Custom Node Pool${RESET}"
gcloud container node-pools create $POOL_NAME \
    --cluster=$CLUSTER_NAME \
    --machine-type=custom-2-3584 \
    --num-nodes=2 \
    --zone=$ZONE || {
    echo "${RED}${BOLD}❌ Failed to create node pool${RESET}"
    exit 1
}
echo "${GREEN}✔ Node pool created successfully${RESET}"
echo ""

# ======================
#  DEFAULT POOL MIGRATION
# ======================
echo "${BOLD}${BLUE}🔄 STEP 6: Migrating from Default Pool${RESET}"
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
    kubectl cordon "$node"
done

for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
    kubectl drain --force --ignore-daemonsets --delete-local-data --grace-period=10 "$node"
done

kubectl get pods -o=wide --namespace=dev
echo "${GREEN}✔ Workloads migrated to new node pool${RESET}"
echo ""

# ======================
#  CLEANUP DEFAULT POOL
# ======================
echo "${BOLD}${RED}🧹 STEP 7: Removing Default Node Pool${RESET}"
gcloud container node-pools delete default-pool \
    --cluster=$CLUSTER_NAME \
    --project=$DEVSHELL_PROJECT_ID \
    --zone $ZONE \
    --quiet || {
    echo "${YELLOW}⚠️ Default pool may already be deleted${RESET}"
}
echo "${GREEN}✔ Default pool removed${RESET}"
echo ""

# ======================
#  POD DISRUPTION BUDGET
# ======================
echo "${BOLD}${CYAN}🛡️ STEP 8: Creating Pod Disruption Budget${RESET}"
kubectl create poddisruptionbudget onlineboutique-frontend-pdb \
    --selector app=frontend \
    --min-available 1 \
    --namespace dev || {
    echo "${RED}${BOLD}❌ Failed to create PDB${RESET}"
    exit 1
}
echo "${GREEN}✔ PDB created successfully${RESET}"
echo ""

# ======================
#  DEPLOYMENT UPDATE
# ======================
echo "${BOLD}${YELLOW}🔄 STEP 9: Updating Frontend Deployment${RESET}"
kubectl patch deployment frontend -n dev --type=json -p '[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/image",
    "value": "gcr.io/qwiklabs-resources/onlineboutique-frontend:v2.1"
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/imagePullPolicy",
    "value": "Always"
  }
]' || {
    echo "${RED}${BOLD}❌ Failed to update deployment${RESET}"
    exit 1
}
echo "${GREEN}✔ Frontend deployment updated${RESET}"
echo ""

# ======================
#  AUTOSCALING CONFIG
# ======================
echo "${BOLD}${MAGENTA}📈 STEP 10: Configuring Horizontal Pod Autoscaler${RESET}"
kubectl autoscale deployment frontend \
    --cpu-percent=50 \
    --min=1 \
    --max=$MAX_REPLICAS \
    --namespace dev || {
    echo "${RED}${BOLD}❌ Failed to configure HPA${RESET}"
    exit 1
}

kubectl get hpa --namespace dev
echo "${GREEN}✔ HPA configured successfully${RESET}"
echo ""

# ======================
#  CLUSTER AUTOSCALING
# ======================
echo "${BOLD}${BLUE}⚖️ STEP 11: Enabling Cluster Autoscaling${RESET}"
gcloud beta container clusters update $CLUSTER_NAME \
    --zone=$ZONE \
    --project=$DEVSHELL_PROJECT_ID \
    --enable-autoscaling \
    --min-nodes 1 \
    --max-nodes 6 || {
    echo "${RED}${BOLD}❌ Failed to enable cluster autoscaling${RESET}"
    exit 1
}
echo "${GREEN}✔ Cluster autoscaling enabled${RESET}"
echo ""

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
