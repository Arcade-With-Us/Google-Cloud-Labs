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

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 1: Fetching default region configuration...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}⚡ Retrieving project metadata for region information${RESET_FORMAT}"
echo

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 2: Obtaining default zone configuration...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}⚡ Extracting zone details from project settings${RESET_FORMAT}"
echo

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

if [[ -z "$ZONE" ]]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}No default zone found.${RESET_FORMAT}"
  read -p "${CYAN_TEXT}${BOLD_TEXT}Please enter your zone: ${RESET_FORMAT}" ZONE
  export ZONE
fi

if [[ -z "$REGION" ]]; then
  export REGION=${ZONE%-*}
  echo "${GREEN_TEXT}${BOLD_TEXT}Derived region from zone: $REGION${RESET_FORMAT}"
fi

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 3: Setting up project environment...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🔧 Configuring project ID and number variables${RESET_FORMAT}"
echo

PROJECT_ID=`gcloud config get-value project`

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 4: Connecting to GKE cluster...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🔗 Establishing kubectl credentials for hello-demo-cluster${RESET_FORMAT}"
echo

gcloud container clusters get-credentials hello-demo-cluster --zone $ZONE

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 5: Scaling application deployment...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}📈 Increasing hello-server replicas to 2 instances${RESET_FORMAT}"
echo

kubectl scale deployment hello-server --replicas=2

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 6: Resizing existing node pool...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🔧 Expanding my-node-pool to 3 nodes for better capacity${RESET_FORMAT}"
echo

gcloud container clusters resize hello-demo-cluster --node-pool my-node-pool \
    --num-nodes 3 --zone $ZONE --quiet

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 7: Creating enhanced node pool...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🏗️ Setting up larger-pool with e2-standard-2 machine type${RESET_FORMAT}"
echo

gcloud container node-pools create larger-pool \
  --cluster=hello-demo-cluster \
  --machine-type=e2-standard-2 \
  --num-nodes=1 \
  --zone=$ZONE

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 8: Cordoning old node pool...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🚫 Marking my-node-pool nodes as unschedulable${RESET_FORMAT}"
echo

for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=my-node-pool -o=name); do
  kubectl cordon "$node";
done

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 9: Draining workloads from old nodes...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🔄 Migrating pods from my-node-pool to new nodes${RESET_FORMAT}"
echo

for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=my-node-pool -o=name); do
  kubectl drain --force --ignore-daemonsets --delete-local-data --grace-period=10 "$node";
done

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 10: Checking pod distribution...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}👀 Verifying current pod placement across nodes${RESET_FORMAT}"
echo

kubectl get pods -o=wide

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 11: Removing old node pool...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🗑️ Cleaning up my-node-pool resources${RESET_FORMAT}"
echo

gcloud container node-pools delete my-node-pool --cluster hello-demo-cluster --zone $ZONE --quiet

echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Waiting for resource cleanup...${RESET_FORMAT}"
echo

for i in {20..1}; do
  printf "\r${CYAN_TEXT}${BOLD_TEXT}[%s] %d seconds remaining...${RESET_FORMAT}" "$(printf '%*s' $((20-i+1)) '' | tr ' ' '█')" "$i"
  sleep 1
done
printf "\r${GREEN_TEXT}${BOLD_TEXT}[████████████████████] Cleanup completed!${RESET_FORMAT}\n"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 12: Creating regional cluster...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🌍 Setting up regional-demo cluster for high availability${RESET_FORMAT}"
echo

gcloud container clusters create regional-demo --region=$REGION --num-nodes=1

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 13: Generating pod-1 configuration...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}📝 Creating YAML manifest for security-labeled pod${RESET_FORMAT}"
echo

cat << EOF > pod-1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-1
  labels:
    security: demo
spec:
  containers:
  - name: container-1
    image: wbitt/network-multitool
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 14: Deploying first pod...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🚀 Launching pod-1 with network-multitool container${RESET_FORMAT}"
echo

kubectl apply -f pod-1.yaml

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 15: Creating pod-2 with anti-affinity...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}📝 Generating YAML with pod anti-affinity rules${RESET_FORMAT}"
echo

cat << EOF > pod-2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-2
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - demo
        topologyKey: "kubernetes.io/hostname"
  containers:
  - name: container-2
    image: gcr.io/google-samples/node-hello:1.0
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 16: Deploying second pod...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🚀 Launching pod-2 with anti-affinity configuration${RESET_FORMAT}"
echo

kubectl apply -f pod-2.yaml

echo "${BLUE_TEXT}${BOLD_TEXT}📍 Step 17: Verifying pod deployment...${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}✅ Checking status and placement of both pods${RESET_FORMAT}"
echo

kubectl get pod pod-1 pod-2 --output wide

echo
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo "${WHITE_TEXT}${BOLD_TEXT}Lab Region: ${RESET_FORMAT}${CYAN_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo

echo "${WHITE_TEXT}${BOLD_TEXT}OPEN THIS LINK: ${RESET_FORMAT}${CYAN_TEXT}${BOLD_TEXT}https://console.cloud.google.com/networking/networks/details/default?project=${PROJECT_ID}${RESET_FORMAT}"


echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
