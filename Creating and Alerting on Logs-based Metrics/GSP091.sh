#!/bin/bash
# Define text formatting variables
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

echo "${GREEN_TEXT}${BOLD_TEXT}🔧 Setting up essential GCP project details...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}   ➡️ Fetching and exporting the current Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud info --format='value(config.project)')

echo "${BLUE_TEXT}${BOLD_TEXT}   ➡️ Determining and exporting the default Compute Zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo "${BLUE_TEXT}${BOLD_TEXT}   ➡️ Determining and exporting the default Compute Region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${BLUE_TEXT}${BOLD_TEXT}   ➡️ Configuring gcloud to use the default Compute Zone: ${ZONE}...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}🛠️  Creating a new Google Kubernetes Engine cluster named 'gmp-cluster'...${RESET_FORMAT}"
gcloud container clusters create gmp-cluster --num-nodes=1 --zone $ZONE

echo "${RED_TEXT}${BOLD_TEXT}📊 Creating a logs-based metric to track stopped VM instances...${RESET_FORMAT}"
gcloud logging metrics create stopped-vm \
  --description="Metric for stopped VMs" \
  --log-filter='resource.type="gce_instance" protoPayload.methodName="v1.compute.instances.stop"'

echo "${GREEN_TEXT}${BOLD_TEXT}📄 Generating configuration file 'pubsub-channel.json' for the Pub/Sub notification channel...${RESET_FORMAT}"
cat > pubsub-channel.json <<EOF_END
{
  "type": "pubsub",
  "displayName": "arcadewithus",
  "description": "Hiiii There !!",
  "labels": {
  "topic": "projects/$DEVSHELL_PROJECT_ID/topics/notificationTopic"
  }
}
EOF_END

echo "${YELLOW_TEXT}${BOLD_TEXT}🔔 Creating the Pub/Sub notification channel using the generated config file...${RESET_FORMAT}"
gcloud beta monitoring channels create --channel-content-from-file=pubsub-channel.json

echo "${BLUE_TEXT}${BOLD_TEXT}🆔 Retrieving the ID of the newly created notification channel...${RESET_FORMAT}"
email_channel_info=$(gcloud beta monitoring channels list)
email_channel_id=$(echo "$email_channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)
echo "${BLUE_TEXT}${BOLD_TEXT}   ✅ Notification Channel ID retrieved: ${email_channel_id}${RESET_FORMAT}"

echo "${MAGENTA_TEXT}${BOLD_TEXT}📝 Preparing the alert policy configuration file 'stopped-vm-alert-policy.json' for stopped VMs...${RESET_FORMAT}"
cat > stopped-vm-alert-policy.json <<EOF_END
{
  "displayName": "stopped vm",
  "documentation": {
  "content": "Documentation content for the stopped vm alert policy",
  "mime_type": "text/markdown"
  },
  "userLabels": {},
  "conditions": [
  {
    "displayName": "Log match condition",
    "conditionMatchedLog": {
    "filter": "resource.type=\"gce_instance\" protoPayload.methodName=\"v1.compute.instances.stop\""
    }
  }
  ],
  "alertStrategy": {
  "notificationRateLimit": {
    "period": "300s"
  },
  "autoClose": "3600s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
  "$email_channel_id"
  ]
}


EOF_END

echo "${CYAN_TEXT}${BOLD_TEXT}🚨 Deploying the alert policy for stopped VMs using the configuration file...${RESET_FORMAT}"
gcloud alpha monitoring policies create --policy-from-file=stopped-vm-alert-policy.json

echo "${RED_TEXT}${BOLD_TEXT}📦 Creating a Docker Artifact Registry repository named 'docker-repo' in region ${REGION}...${RESET_FORMAT}"
gcloud artifacts repositories create docker-repo --repository-format=docker \
  --location=$REGION --description="Docker repository" \
  --project=$DEVSHELL_PROJECT_ID

echo "${GREEN_TEXT}${BOLD_TEXT}📥 Downloading the Flask application archive...${RESET_FORMAT}"
wget https://storage.googleapis.com/spls/gsp1024/flask_telemetry.zip
echo "${GREEN_TEXT}${BOLD_TEXT}   🔓 Unzipping the downloaded archive...${RESET_FORMAT}"
unzip flask_telemetry.zip
echo "${GREEN_TEXT}${BOLD_TEXT}   🐳 Loading the Docker image from the extracted tar file...${RESET_FORMAT}"
docker load -i flask_telemetry.tar

echo "${YELLOW_TEXT}${BOLD_TEXT}🏷️  Tagging the Docker image for the Artifact Registry...${RESET_FORMAT}"
docker tag gcr.io/ops-demo-330920/flask_telemetry:61a2a7aabc7077ef474eb24f4b69faeab47deed9 \
$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1

echo "${YELLOW_TEXT}${BOLD_TEXT}   ⬆️ Pushing the tagged Docker image to the Artifact Registry...${RESET_FORMAT}"
docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1

echo "${WHITE_TEXT}${BOLD_TEXT}📋 Listing available GKE clusters...${RESET_FORMAT}"
gcloud container clusters list

echo "${BLUE_TEXT}${BOLD_TEXT}🔑 Getting credentials for the 'gmp-cluster' Kubernetes cluster...${RESET_FORMAT}"
gcloud container clusters get-credentials gmp-cluster

echo "${MAGENTA_TEXT}${BOLD_TEXT}🏷️  Creating a new Kubernetes namespace 'gmp-test'...${RESET_FORMAT}"
kubectl create ns gmp-test

echo "${CYAN_TEXT}${BOLD_TEXT}📥 Downloading Prometheus setup files...${RESET_FORMAT}"
wget https://storage.googleapis.com/spls/gsp1024/gmp_prom_setup.zip
echo "${CYAN_TEXT}${BOLD_TEXT}   🔓 Unpacking the Prometheus setup archive...${RESET_FORMAT}"
unzip gmp_prom_setup.zip
echo "${CYAN_TEXT}${BOLD_TEXT}   📁 Changing directory to 'gmp_prom_setup'...${RESET_FORMAT}"
cd gmp_prom_setup

echo "${RED_TEXT}${BOLD_TEXT}🔄 Updating the deployment manifest 'flask_deployment.yaml' with the correct Docker image URL...${RESET_FORMAT}"
sed -i "s|<ARTIFACT REGISTRY IMAGE NAME>|$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1|g" flask_deployment.yaml

echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Applying the Kubernetes deployment configuration from 'flask_deployment.yaml'...${RESET_FORMAT}"
kubectl -n gmp-test apply -f flask_deployment.yaml

echo "${GREEN_TEXT}${BOLD_TEXT}   🌐 Applying the Kubernetes service configuration from 'flask_service.yaml'...${RESET_FORMAT}"
kubectl -n gmp-test apply -f flask_service.yaml

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Checking the status of services in the 'gmp-test' namespace...${RESET_FORMAT}"
kubectl get services -n gmp-test

echo "${BLUE_TEXT}${BOLD_TEXT}📊 Creating another logs-based metric 'hello-app-error' to track errors in the 'hello-app' container...${RESET_FORMAT}"
gcloud logging metrics create hello-app-error \
  --description="Metric for hello-app errors" \
  --log-filter='severity=ERROR
resource.labels.container_name="hello-app"
textPayload: "ERROR: 404 Error page not found"'

echo -n "${WHITE_TEXT}${BOLD_TEXT}⏳ Waiting 30s for metric availability: [${RESET_FORMAT}"
# Display a simple progress indicator
for i in {1..30}; do
  echo -n "${WHITE_TEXT}${BOLD_TEXT}.${RESET_FORMAT}"
  sleep 1
done
echo "${WHITE_TEXT}${BOLD_TEXT}]${RESET_FORMAT}" # Close the indicator bracket and add newline
echo "${GREEN_TEXT}${BOLD_TEXT}   ✅ Metric should now be available.${RESET_FORMAT}"

echo "${MAGENTA_TEXT}${BOLD_TEXT}📝 Generating the alert policy configuration file 'arcadewithus.json' for 'hello-app' errors...${RESET_FORMAT}"
cat > arcadewithus.json <<'EOF_END'
{
  "displayName": "log based metric alert",
  "userLabels": {},
  "conditions": [
  {
    "displayName": "New condition",
    "conditionThreshold": {
    "filter": 'metric.type="logging.googleapis.com/user/hello-app-error" AND resource.type="global"',
    "aggregations": [
      {
      "alignmentPeriod": "120s",
      "crossSeriesReducer": "REDUCE_SUM",
      "perSeriesAligner": "ALIGN_DELTA"
      }
    ],
    "comparison": "COMPARISON_GT",
    "duration": "0s",
    "trigger": {
      "count": 1
    }
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

echo "${CYAN_TEXT}${BOLD_TEXT}🚨 Deploying the alert policy for 'hello-app' errors using 'arcadewithus.json'...${RESET_FORMAT}"
gcloud alpha monitoring policies create --policy-from-file=arcadewithus.json

echo "${RED_TEXT}${BOLD_TEXT}💥 Triggering errors in the 'hello-app' for 120 seconds to generate logs and test the alert...${RESET_FORMAT}"
timeout 120 bash -c -- 'while true; do curl $(kubectl get services -n gmp-test -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}')/error; sleep $((RANDOM % 4)) ; done'

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade With Us! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
