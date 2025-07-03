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

echo "${BLUE_TEXT}${BOLD_TEXT}🔍 Attempting to automatically detect your default GCP compute zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Could not automatically detect the default compute zone.${RESET_FORMAT}"
  echo "${YELLOW_TEXT}${BOLD_TEXT}Please provide your desired GCP compute zone below.${RESET_FORMAT}"
  read -p "${GREEN_TEXT}${BOLD_TEXT}➡️ Enter your GCP zone: ${RESET_FORMAT}" ZONE
  if [ -z "$ZONE" ]; then
    echo "${RED_TEXT}${BOLD_TEXT}🛑 Zone not provided. The script will continue, but might fail if a zone is required.${RESET_FORMAT}"
  fi
fi

if [ -n "$ZONE" ]; then
  echo "${GREEN_TEXT}${BOLD_TEXT}✅ Using GCP zone: ${ZONE}${RESET_FORMAT}"
else
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ No GCP zone specified. Subsequent commands requiring a zone may fail.${RESET_FORMAT}"
fi
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Setting the default compute zone to '${ZONE}' for gcloud commands (if zone is set)...${RESET_FORMAT}"
if [ -n "$ZONE" ]; then
  gcloud config set compute/zone $ZONE
else
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Skipping gcloud config set compute/zone as no zone is defined.${RESET_FORMAT}"
fi
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🆔 Fetching your GCP Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud info --format='value(config.project)')
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Project ID set to: ${PROJECT_ID}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔑 Getting credentials for the GKE cluster 'central' in zone '${ZONE}' (if zone is set)...${RESET_FORMAT}"
if [ -n "$ZONE" ]; then
  gcloud container clusters get-credentials central --zone $ZONE
else
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Skipping get-credentials as no zone is defined. This might cause issues.${RESET_FORMAT}"
fi
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📥 Cloning the microservices demo repository from GitHub...${RESET_FORMAT}"
git clone https://github.com/xiangshen-dk/microservices-demo.git
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating into the 'microservices-demo' directory...${RESET_FORMAT}"
cd microservices-demo
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Applying Kubernetes manifests to deploy the application...${RESET_FORMAT}"
kubectl apply -f release/kubernetes-manifests.yaml
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Allowing resources to initialize...${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ $i seconds remaining... ${RESET_FORMAT}"
  sleep 1
done
echo -e "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ 0 seconds remaining... Done!${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📊 Creating a Cloud Logging metric named 'Error_Rate_SLI' for 'recommendationservice' errors...${RESET_FORMAT}"
gcloud logging metrics create Error_Rate_SLI \
  --description="Subscribe to Arcade Crew" \
  --log-filter="resource.type=\"k8s_container\" severity=ERROR labels.\"k8s-pod/app\": \"recommendationservice\""
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Pausing for the new metric to become available...${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ $i seconds remaining... ${RESET_FORMAT}"
  sleep 1
done
echo -e "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ 0 seconds remaining... Done!${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating the 'arcadewithus.json' monitoring policy configuration file...${RESET_FORMAT}"
cat > arcadewithus.json <<EOF_END
{
  "displayName": "Error Rate SLI",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "Kubernetes Container - logging/user/Error_Rate_SLI",
      "conditionThreshold": {
        "filter": "resource.type = \"k8s_container\" AND metric.type = \"logging.googleapis.com/user/Error_Rate_SLI\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 0.5
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "604800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END
echo "${GREEN_TEXT}${BOLD_TEXT}✅ 'arcadewithus.json' file has been successfully created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛡️ Creating the Cloud Monitoring alert policy using the 'arcadewithus.json' file...${RESET_FORMAT}"
gcloud alpha monitoring policies create --policy-from-file="arcadewithus.json"
echo

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
