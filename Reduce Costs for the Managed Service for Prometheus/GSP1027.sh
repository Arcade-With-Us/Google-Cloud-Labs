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

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Initializing Setup: Identifying Your GCP Project and Zone 🚀${RESET_FORMAT}"
export PROJECT=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🛠️  Creating Your Kubernetes Cluster with Managed Prometheus 🛠️${RESET_FORMAT}"
gcloud beta container clusters create gmp-cluster --num-nodes=1 --zone $ZONE --enable-managed-prometheus

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🔑 Accessing Your New Cluster: Retrieving Credentials 🔑${RESET_FORMAT}"
gcloud container clusters get-credentials gmp-cluster --zone=$ZONE

echo
echo "${CYAN_TEXT}${BOLD_TEXT}📊 Applying Self Pod Monitoring Configuration 📊${RESET_FORMAT}"
kubectl -n gmp-system apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/main/examples/self-pod-monitoring.yaml

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 Deploying an Example Application for Monitoring 🚀${RESET_FORMAT}"
kubectl -n gmp-system apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/main/examples/example-app.yaml

echo
echo "${RED_TEXT}${BOLD_TEXT}⚙️  Fine-tuning Monitoring: Patching Operator Configuration ⚙️${RESET_FORMAT}"
kubectl patch operatorconfig config -n gmp-public --type='json' -p='[
  {"op": "add", "path": "/collection", "value": {"filter": {"matchOneOf": ["{job=\"prom-example\"}", "{__name__=~\"job:.+\"}"]}}}
]'

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📄 Generating Operator Configuration File (op-config.yaml) 📄${RESET_FORMAT}"
cat > op-config.yaml <<'EOF_END'
apiVersion: monitoring.googleapis.com/v1alpha1
collection:
  filter:
    matchOneOf:
    - '{job="prom-example"}'
    - '{__name__=~"job:.+"}'
kind: OperatorConfig
metadata:
  annotations:
    components.gke.io/layer: addon
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"monitoring.googleapis.com/v1alpha1","kind":"OperatorConfig","metadata":{"annotations":{"components.gke.io/layer":"addon"},"labels":{"addonmanager.kubernetes.io/mode":"Reconcile"},"name":"config","namespace":"gmp-public"}}
  creationTimestamp: "2022-03-14T22:34:23Z"
  generation: 1
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
  name: config
  namespace: gmp-public
  resourceVersion: "2882"
  uid: 4ad23359-efeb-42bb-b689-045bd704f295
EOF_END

echo
echo "${BLUE_TEXT}${BOLD_TEXT}☁️  Storing Configuration in Google Cloud Storage ☁️${RESET_FORMAT}"
gsutil mb -p $PROJECT gs://$PROJECT
gsutil cp op-config.yaml gs://$PROJECT
gsutil -m acl set -R -a public-read gs://$PROJECT

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}📄 Generating Pod Monitoring Configuration File (prom-example-config.yaml) 📄${RESET_FORMAT}"
cat > prom-example-config.yaml <<EOF
apiVersion: monitoring.googleapis.com/v1alpha1
kind: PodMonitoring
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"monitoring.googleapis.com/v1alpha1","kind":"PodMonitoring","metadata":{"annotations":{},"labels":{"app.kubernetes.io/name":"prom-example"},"name":"prom-example","namespace":"gmp-test"},"spec":{"endpoints":[{"interval":"30s","port":"metrics"}],"selector":{"matchLabels":{"app":"prom-example"}}}}
  creationTimestamp: "2022-03-14T22:33:55Z"
  generation: 1
  labels:
    app.kubernetes.io/name: prom-example
  name: prom-example
  namespace: gmp-test
  resourceVersion: "2648"
  uid: c10a8507-429e-4f69-8993-0c562f9c730f
spec:
  endpoints:
  - interval: 60s
    port: metrics
  selector:
    matchLabels:
      app: prom-example
status:
  conditions:
  - lastTransitionTime: "2022-03-14T22:33:55Z"
    lastUpdateTime: "2022-03-14T22:33:55Z"
    status: "True"
    type: ConfigurationCreateSuccess
  observedGeneration: 1
EOF

echo
echo "${CYAN_TEXT}${BOLD_TEXT}📤 Uploading Pod Monitoring Configuration to Cloud Storage 📤${RESET_FORMAT}"
gsutil cp prom-example-config.yaml gs://$PROJECT
echo
echo "${WHITE_TEXT}${BOLD_TEXT}🔐 Re-applying Public Read Access (if necessary) 🔐${RESET_FORMAT}"
gsutil -m acl set -R -a public-read gs://$PROJECT

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
