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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter Repository Name: ${RESET_FORMAT}"
read REPO_NAME
export REPO_NAME

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter Cluster Name: ${RESET_FORMAT}"
read CLUSTER_NAME
export CLUSTER_NAME

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter Namespace: ${RESET_FORMAT}"
read NAMESPACE
export NAMESPACE

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter Monitoring Interval: ${RESET_FORMAT}"
read INTERVAL
export INTERVAL

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter Service Name for Helloweb: ${RESET_FORMAT}"
read SERVICE_NAME
export SERVICE_NAME

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Attempting to automatically determine the default Google Cloud Zone...${RESET_FORMAT}"
ZONE_CANDIDATE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE_CANDIDATE" ]; then
  echo -e "${RED_TEXT}${BOLD_TEXT}⚠️ Could not automatically determine zone. Please enter it manually: ${RESET_FORMAT}"
  read ZONE
else
  export ZONE="$ZONE_CANDIDATE"
  echo -e "${GREEN_TEXT}${BOLD_TEXT}✅ Zone automatically determined: $ZONE ${RESET_FORMAT}"
fi
export ZONE

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Configuring Google Cloud SDK to use zone '$ZONE'...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 Creating GKE cluster named '$CLUSTER_NAME' in zone '$ZONE'. This might take a few minutes...${RESET_FORMAT}"
gcloud container clusters create $CLUSTER_NAME \
--release-channel regular \
--cluster-version latest \
--num-nodes 3 \
--min-nodes 2 \
--max-nodes 6 \
--enable-autoscaling --no-enable-ip-alias

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Updating GKE cluster '$CLUSTER_NAME' to enable Managed Prometheus...${RESET_FORMAT}"
gcloud container clusters update $CLUSTER_NAME --enable-managed-prometheus --zone $ZONE

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 Creating Kubernetes namespace '$NAMESPACE'...${RESET_FORMAT}"
kubectl create ns $NAMESPACE

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Copying Prometheus application manifest 'prometheus-app.yaml' from Cloud Storage...${RESET_FORMAT}"
gsutil cp gs://spls/gsp510/prometheus-app.yaml .

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📄 Generating Prometheus application deployment manifest 'prometheus-app.yaml'...${RESET_FORMAT}"
cat > prometheus-app.yaml <<EOF

apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-test
  labels:
    app: prometheus-test
spec:
  selector:
    matchLabels:
      app: prometheus-test
  replicas: 3
  template:
    metadata:
      labels:
        app: prometheus-test
    spec:
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/arch: amd64
      containers:
      - image: nilebox/prometheus-example-app:latest
        name: prometheus-test
        ports:
        - name: metrics
          containerPort: 1234
        command:
        - "/main"
        - "--process-metrics"
        - "--go-metrics"
EOF

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🚢 Deploying Prometheus application to the '$NAMESPACE' namespace...${RESET_FORMAT}"
kubectl -n $NAMESPACE apply -f prometheus-app.yaml

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Copying PodMonitoring configuration 'pod-monitoring.yaml' from Cloud Storage...${RESET_FORMAT}"
gsutil cp gs://spls/gsp510/pod-monitoring.yaml .

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📄 Generating PodMonitoring custom resource manifest 'pod-monitoring.yaml' with interval '$INTERVAL'...${RESET_FORMAT}"
cat > pod-monitoring.yaml <<EOF

apiVersion: monitoring.googleapis.com/v1alpha1
kind: PodMonitoring
metadata:
  name: prometheus-test
  labels:
    app.kubernetes.io/name: prometheus-test
spec:
  selector:
    matchLabels:
      app: prometheus-test
  endpoints:
  - port: metrics
    interval: $INTERVAL
EOF

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Applying PodMonitoring configuration in the '$NAMESPACE' namespace...${RESET_FORMAT}"
kubectl -n $NAMESPACE apply -f pod-monitoring.yaml

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Downloading the 'hello-app' sample application files...${RESET_FORMAT}"
gsutil cp -r gs://spls/gsp510/hello-app/ .

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Fetching the current Google Cloud Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}${BOLD_TEXT}Project ID set to: $PROJECT_ID ${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Determining the Google Cloud Region from zone '$ZONE'...${RESET_FORMAT}"
export REGION="${ZONE%-*}"
echo "${GREEN_TEXT}${BOLD_TEXT}Region set to: $REGION ${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}➡️ Changing directory to 'hello-app'...${RESET_FORMAT}"
cd ~/hello-app

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Fetching credentials for GKE cluster '$CLUSTER_NAME' to configure kubectl...${RESET_FORMAT}"
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🚢 Applying the initial 'helloweb' deployment in namespace '$NAMESPACE'...${RESET_FORMAT}"
kubectl -n $NAMESPACE apply -f manifests/helloweb-deployment.yaml

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}➡️ Navigating into the 'manifests' directory...${RESET_FORMAT}"
cd manifests/

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📄 Updating 'helloweb-deployment.yaml' with new resource requests...${RESET_FORMAT}"
cat > helloweb-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloweb
  labels:
    app: hello
spec:
  selector:
    matchLabels:
      app: hello
      tier: web
  template:
    metadata:
      labels:
        app: hello
        tier: web
    spec:
      containers:
      - name: hello-app
        image: us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 200m
---
EOF

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}➡️ Returning to the parent 'hello-app' directory...${RESET_FORMAT}"
cd ..

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🗑️ Removing the existing 'helloweb' deployment from namespace '$NAMESPACE' to apply updates...${RESET_FORMAT}"
kubectl delete deployments helloweb  -n $NAMESPACE

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🚢 Re-applying the 'helloweb' deployment with updated manifest in namespace '$NAMESPACE'...${RESET_FORMAT}"
kubectl -n $NAMESPACE apply -f manifests/helloweb-deployment.yaml

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📄 Creating/Updating 'main.go' for 'hello-app' version 2.0.0...${RESET_FORMAT}"
cat > main.go <<EOF
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
)

func main() {
  mux := http.NewServeMux()
  mux.HandleFunc("/", hello)

  port := os.Getenv("PORT")
  if port == "" {
    port = "8080"
  }

  log.Printf("Server listening on port %s", port)
  log.Fatal(http.ListenAndServe(":"+port, mux))
}

func hello(w http.ResponseWriter, r *http.Request) {
  log.Printf("Serving request: %s", r.URL.Path)
  host, _ := os.Hostname()
  fmt.Fprintf(w, "Hello, world!\n")
  fmt.Fprintf(w, "Version: 2.0.0\n")
  fmt.Fprintf(w, "Hostname: %s\n", host)
}

EOF

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Re-confirming Google Cloud Project ID for Docker operations: $PROJECT_ID ${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project) # Already set, but good for clarity
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Re-confirming Google Cloud Region for Docker repository: $REGION ${RESET_FORMAT}"
export REGION="${ZONE%-*}" # Already set, but good for clarity

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}➡️ Ensuring we are in the 'hello-app' directory for Docker build...${RESET_FORMAT}"
cd ~/hello-app/

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Configuring Docker to authenticate with Google Artifact Registry in region '$REGION'...${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Building Docker image for 'hello-app:v2' and tagging for repository '$REPO_NAME'...${RESET_FORMAT}"
docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/hello-app:v2 .

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🚢 Pushing 'hello-app:v2' Docker image to Artifact Registry repository '$REPO_NAME'...${RESET_FORMAT}"
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/hello-app:v2

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Updating 'helloweb' deployment in namespace '$NAMESPACE' to use the new 'hello-app:v2' image from '$REPO_NAME'...${RESET_FORMAT}"
kubectl set image deployment/helloweb -n $NAMESPACE hello-app=$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/hello-app:v2

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🌐 Exposing 'helloweb' deployment in namespace '$NAMESPACE' as a LoadBalancer service named '$SERVICE_NAME'...${RESET_FORMAT}"
kubectl expose deployment helloweb -n $NAMESPACE --name=$SERVICE_NAME --type=LoadBalancer --port 8080 --target-port 8080

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}➡️ Navigating back to the script's initial directory...${RESET_FORMAT}"
cd ..

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Re-applying PodMonitoring configuration in namespace '$NAMESPACE' to ensure it's current...${RESET_FORMAT}"
kubectl -n $NAMESPACE apply -f pod-monitoring.yaml

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📊 Creating logs-based metric 'pod-image-errors' for tracking pod image issues...${RESET_FORMAT}"
gcloud logging metrics create pod-image-errors \
  --description="Subscribe to Arcade Crew" \
  --log-filter="resource.type=\"k8s_pod\"	
severity=WARNING"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📄 Generating JSON definition for 'Pod Error Alert' monitoring policy...${RESET_FORMAT}"
cat > arcadewithus.json <<EOF_END
{
  "displayName": "Pod Error Alert",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "Kubernetes Pod - logging/user/pod-image-errors",
      "conditionThreshold": {
        "filter": "resource.type = \"k8s_pod\" AND metric.type = \"logging.googleapis.com/user/pod-image-errors\"",
        "aggregations": [
          {
            "alignmentPeriod": "600s",
            "crossSeriesReducer": "REDUCE_SUM",
            "perSeriesAligner": "ALIGN_COUNT"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 0
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "604800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": []
}
EOF_END

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Creating 'Pod Error Alert' monitoring policy using 'arcadewithus.json'...${RESET_FORMAT}"
gcloud alpha monitoring policies create --policy-from-file="arcadewithus.json"

# Completion Message
echo "${BG_GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_GREEN}${BOLD}         LAB COMPLETE!             ${RESET}"
echo "${BG_GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
