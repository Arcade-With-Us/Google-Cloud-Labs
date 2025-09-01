
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

# Instruction for user input
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE:${RESET_FORMAT} " ZONE

# Instruction for authentication
echo "${CYAN_TEXT}${BOLD_TEXT}Authenticating with Google Cloud...${RESET_FORMAT}"
gcloud auth list

# Instruction for setting project ID
echo "${MAGENTA_TEXT}${BOLD_TEXT}Fetching the current project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)

export PROJECT_ID=$DEVSHELL_PROJECT_ID

# Instruction for setting the compute zone
echo "${GREEN_TEXT}${BOLD_TEXT}Setting the compute zone to the user-provided value...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

# Instruction for creating a VM instance
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a VM instance and configuring firewall rules...${RESET_FORMAT}"
gcloud compute instances create quickstart-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-small --image-family=debian-11 --image-project=debian-cloud --tags=http-server,https-server && gcloud compute firewall-rules create default-allow-http --target-tags=http-server --allow tcp:80 --description="Allow HTTP traffic" && gcloud compute firewall-rules create default-allow-https --target-tags=https-server --allow tcp:443 --description="Allow HTTPS traffic"

# Instruction for configuring the VM
echo "${CYAN_TEXT}${BOLD_TEXT}Configuring the VM with Apache and Google Cloud Ops Agent...${RESET_FORMAT}"
cat > cp_disk.sh <<'EOF_CP'

sudo apt-get update && sudo apt-get install apache2 php

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Configures Ops Agent to collect telemetry from the app and restart Ops Agent.

set -e

# Create a back up of the existing file so existing configurations are not lost.
sudo cp /etc/google-cloud-ops-agent/config.yaml /etc/google-cloud-ops-agent/config.yaml.bak

# Configure the Ops Agent.
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << EOF
metrics:
  receivers:
    apache:
      type: apache
  service:
    pipelines:
      apache:
        receivers:
          - apache
logging:
  receivers:
    apache_access:
      type: apache_access
    apache_error:
      type: apache_error
  service:
    pipelines:
      apache:
        receivers:
          - apache_access
          - apache_error
EOF

sudo service google-cloud-ops-agent restart
sleep 60

EOF_CP

# Instruction for copying the script to the VM
echo "${MAGENTA_TEXT}${BOLD_TEXT}Copying the configuration script to the VM...${RESET_FORMAT}"
gcloud compute scp cp_disk.sh quickstart-vm:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

# Instruction for executing the script on the VM
echo "${YELLOW_TEXT}${BOLD_TEXT}Executing the configuration script on the VM...${RESET_FORMAT}"
gcloud compute ssh quickstart-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/cp_disk.sh"

# Instruction for creating a notification channel
echo "${CYAN_TEXT}${BOLD_TEXT}Creating a notification channel for monitoring...${RESET_FORMAT}"
cat > cp-channel.json <<EOF_CP
{
  "type": "pubsub",
  "displayName": "arcadecrew",
  "description": "subscribe to arcadecrew",
  "labels": {
    "topic": "projects/$DEVSHELL_PROJECT_ID/topics/notificationTopic"
  }
}
EOF_CP

gcloud beta monitoring channels create --channel-content-from-file=cp-channel.json

# Instruction for fetching the channel ID
echo "${GREEN_TEXT}${BOLD_TEXT}Fetching the notification channel ID...${RESET_FORMAT}"
email_channel=$(gcloud beta monitoring channels list)
channel_id=$(echo "$email_channel" | grep -oP 'name: \K[^ ]+' | head -n 1)

# Instruction for creating an alert policy
echo "${BLUE_TEXT}${BOLD_TEXT}Creating an alert policy for Apache traffic monitoring...${RESET_FORMAT}"
cat > stopped-vm-alert-policy.json <<EOF_CP
{
  "displayName": "Apache traffic above threshold",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - workload/apache.traffic",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"workload.googleapis.com/apache.traffic\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 4000
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "1800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_CP

gcloud alpha monitoring policies create --policy-from-file=stopped-vm-alert-policy.json

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
