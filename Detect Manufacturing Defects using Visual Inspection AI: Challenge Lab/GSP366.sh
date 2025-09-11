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

# Get container name from user
echo "Enter the container name:"
read CONTAINER

# Get defective result filename from user
echo "Enter the filename for defective result:"
read FILE_1

# Get non-defective result filename from user
echo "Enter the filename for non-defective result:"
read FILE_2

# Display the entered values
echo "Using container name: $CONTAINER"
echo "Using defective result filename: $FILE_1"
echo "Using non-defective result filename: $FILE_2"
echo

# Auto-detect the first running VM name and zone
echo "Detecting active VM instance..."
VM_INFO=$(gcloud compute instances list --filter="status=RUNNING" --format="value(name,zone)" --project="$DEVSHELL_PROJECT_ID" | head -n 1)

if [[ -z "$VM_INFO" ]]; then
  echo "ERROR: No running VM found in project $DEVSHELL_PROJECT_ID"
  exit 1
fi

INSTANCE_NAME=$(echo "$VM_INFO" | awk '{print $1}')
ZONE=$(echo "$VM_INFO" | awk '{print $2}')

echo "Using VM: $INSTANCE_NAME in Zone: $ZONE"
echo

# Save environment variables
echo "Saving environment variables..."
echo "export CONTAINER_NAME=$CONTAINER" > env_vars.sh
echo "export TASK_3_FILE_NAME=$FILE_1" >> env_vars.sh
echo "export TASK_4_FILE_NAME=$FILE_2" >> env_vars.sh
echo "Environment variables saved successfully!"

# Generate prepare_disk.sh
echo "Generating prepare_disk.sh script..."

source env_vars.sh

cat > prepare_disk.sh <<'EOF_END'
# Source the environment variables
source /tmp/env_vars.sh

export mobile_inspection=gcr.io/ql-shared-resources-test/defect_solution@sha256:776fd8c65304ac017f5b9a986a1b8189695b7abbff6aa0e4ef693c46c7122f4c

export VISERVING_CPU_DOCKER_WITH_MODEL=${mobile_inspection}
export HTTP_PORT=8602
export LOCAL_METRIC_PORT=8603

docker pull ${VISERVING_CPU_DOCKER_WITH_MODEL}

docker run -v /secrets:/secrets --rm -d --name "$CONTAINER_NAME" \
--network="host" \
-p ${HTTP_PORT}:8602 \
-p ${LOCAL_METRIC_PORT}:8603 \
-t ${VISERVING_CPU_DOCKER_WITH_MODEL} \
--use_default_credentials=false \
--service_account_credentials_json=/secrets/assembly-usage-reporter.json

# Task 2
gsutil cp gs://cloud-training/gsp895/prediction_script.py .

export PROJECT_ID=$(gcloud config get-value core/project)
gsutil mb gs://${PROJECT_ID}
gsutil -m cp gs://cloud-training/gsp897/cosmetic-test-data/*.png gs://${PROJECT_ID}/cosmetic-test-data/
gsutil cp gs://${PROJECT_ID}/cosmetic-test-data/IMG_07703.png .

# Task 3
sudo apt install python3 -y
sudo apt install python3-pip -y
sudo apt install python3.11-venv -y 
python3 -m venv myvenv
source myvenv/bin/activate
pip install absl-py  
pip install numpy 
pip install requests

python3 ./prediction_script.py --input_image_file=./IMG_07703.png  --port=8602 --output_result_file=${TASK_3_FILE_NAME}

# Task 4
export PROJECT_ID=$(gcloud config get-value core/project)
gsutil cp gs://${PROJECT_ID}/cosmetic-test-data/IMG_0769.png .

python3 ./prediction_script.py --input_image_file=./IMG_0769.png  --port=8602 --output_result_file=${TASK_4_FILE_NAME}
EOF_END

echo "prepare_disk.sh script generated successfully!"

# Copy scripts to VM
echo "Copying scripts to the VM..."
gcloud compute scp env_vars.sh $INSTANCE_NAME:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
gcloud compute scp prepare_disk.sh $INSTANCE_NAME:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
echo "Scripts copied successfully!"

# Execute script on VM
echo "Executing script on VM..."
gcloud compute ssh $INSTANCE_NAME --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

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
