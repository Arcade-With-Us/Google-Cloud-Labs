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

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️  Step 1: Configuring Google Cloud Compute Zone & Region${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Fetching the default compute zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo "${WHITE_TEXT}   Default zone set to: ${YELLOW_TEXT}${BOLD_TEXT}${ZONE}${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}   Fetching the default compute region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${WHITE_TEXT}   Default region set to: ${YELLOW_TEXT}${BOLD_TEXT}${REGION}${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📦 Step 2: Creating Docker Artifact Registry${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Executing command to create 'docker-repo' in region ${YELLOW_TEXT}${REGION}${CYAN_TEXT}...${RESET_FORMAT}"
gcloud artifacts repositories create docker-repo --repository-format=docker \
  --location=$REGION --description="Docker repository" \
  --project=$DEVSHELL_PROJECT_ID
echo

echo "${CYAN_TEXT}${BOLD_TEXT}📥 Step 3: Downloading Flask Telemetry App Source${RESET_FORMAT}"
wget https://storage.googleapis.com/spls/gsp1024/flask_telemetry.zip
echo "${YELLOW_TEXT}${BOLD_TEXT}   Extracting files from flask_telemetry.zip...${RESET_FORMAT}"
unzip flask_telemetry.zip
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🐳 Step 4: Loading Docker Image into Local Docker Daemon${RESET_FORMAT}"
docker load -i flask_telemetry.tar
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🏷️  Step 5: Tagging the Docker Image for Artifact Registry${RESET_FORMAT}"
docker tag gcr.io/ops-demo-330920/flask_telemetry:61a2a7aabc7077ef474eb24f4b69faeab47deed9 \
$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1
echo

echo "${RED_TEXT}${BOLD_TEXT}📤 Step 6: Pushing Docker Image to Artifact Registry${RESET_FORMAT}"
docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1
echo

echo "${GREEN_TEXT}${BOLD_TEXT}☸️  Step 7: Creating GKE Cluster with Managed Prometheus${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Creating 'gmp-cluster' in zone ${YELLOW_TEXT}${ZONE}${CYAN_TEXT}. This can take several minutes, please be patient...${RESET_FORMAT}"
gcloud beta container clusters create gmp-cluster --num-nodes=1 --zone $ZONE --enable-managed-prometheus
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Step 8: Getting GKE Cluster Credentials${RESET_FORMAT}"
gcloud container clusters get-credentials gmp-cluster --zone $ZONE
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🏷️  Step 9: Creating Kubernetes Namespace${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Creating namespace 'gmp-test'...${RESET_FORMAT}"
kubectl create ns gmp-test
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}📄 Step 10: Downloading Prometheus Setup Files for GKE${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Downloading Prometheus setup archive...${RESET_FORMAT}"
wget https://storage.googleapis.com/spls/gsp1024/gmp_prom_setup.zip
echo "${CYAN_TEXT}${BOLD_TEXT}   Extracting 'gmp_prom_setup.zip'...${RESET_FORMAT}"
unzip gmp_prom_setup.zip
echo "${CYAN_TEXT}${BOLD_TEXT}   Changing directory to 'gmp_prom_setup'...${RESET_FORMAT}"
cd gmp_prom_setup
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Step 11: Updating Deployment YAML with Artifact Registry Image Path${RESET_FORMAT}"
sed -i "s|<ARTIFACT REGISTRY IMAGE NAME>|$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1|g" flask_deployment.yaml
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Step 12: Applying Flask Application Deployment to GKE${RESET_FORMAT}"
kubectl -n gmp-test apply -f flask_deployment.yaml
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🌐 Step 13: Applying Flask Service to Expose Application${RESET_FORMAT}"
kubectl -n gmp-test apply -f flask_service.yaml
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔗 Step 14: Retrieving External IP of the LoadBalancer${RESET_FORMAT}"
url=$(kubectl get services -n gmp-test -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}')
echo "${GREEN_TEXT}${BOLD_TEXT}   Application should be accessible at: ${WHITE_TEXT}http://${url}${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}📊 Step 15: Verifying Application Metrics Endpoint${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Curling http://${YELLOW_TEXT}${url}/metrics ${CYAN_TEXT}to see the metrics...${RESET_FORMAT}"
curl $url/metrics
echo
echo

echo "${RED_TEXT}${BOLD_TEXT}📈 Step 16: Deploying Prometheus Configuration to GKE${RESET_FORMAT}"
kubectl -n gmp-test apply -f prom_deploy.yaml
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🚦 Step 17: Generating Random Traffic to the Application${RESET_FORMAT}"
timeout 120 bash -c -- 'while true; do curl -s $(kubectl get services -n gmp-test -o jsonpath="{.items[*].status.loadBalancer.ingress[0].ip}"); sleep $((RANDOM % 4)) ; done'
echo
echo "${GREEN_TEXT}${BOLD_TEXT}   Traffic generation complete!${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📊 Step 18: Creating Google Cloud Monitoring Dashboard${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Creating dashboard named 'Prometheus Dashboard Example'...${RESET_FORMAT}"
gcloud monitoring dashboards create --config='''
{
  "category": "CUSTOM",
  "displayName": "Prometheus Dashboard Example",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "height": 4,
        "widget": {
          "title": "prometheus/flask_http_request_total/counter [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"prometheus.googleapis.com/flask_http_request_total/counter\" resource.type=\"prometheus_target\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": [
                        "metric.label.\"status\""
                      ],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 0
      }
    ]
  }
}
'''

echo
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
