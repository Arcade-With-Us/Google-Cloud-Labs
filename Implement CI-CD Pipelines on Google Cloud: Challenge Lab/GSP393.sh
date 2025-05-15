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

echo
clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔍 Attempting to automatically detect the default Google Cloud Zone...${RESET_FORMAT}"
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Default zone not detected automatically.${RESET_FORMAT}"
  while true; do
    read -p "${GREEN_TEXT}${BOLD_TEXT}Please enter the Zone (e.g., us-central1-a): ${RESET_FORMAT}" ZONE_INPUT
    if [ -z "$ZONE_INPUT" ]; then
      echo "${RED_TEXT}${BOLD_TEXT}Zone cannot be empty. Please try again. 🚫${RESET_FORMAT}"
    elif [[ "$ZONE_INPUT" =~ ^[a-z0-9]+-[a-z0-9]+-[a-z]$ ]]; then
      ZONE="$ZONE_INPUT"
      break
    else
      echo "${RED_TEXT}${BOLD_TEXT}Invalid zone format. Expected format like 'us-central1-a'. Please try again. ❌${RESET_FORMAT}"
    fi
  done
fi
echo "${CYAN_TEXT}${BOLD_TEXT}✅ Using Zone: ${WHITE_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🌍 Attempting to automatically detect the default Google Cloud Region...${RESET_FORMAT}"
REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Default region not detected automatically.${RESET_FORMAT}"
  if [ -n "$ZONE" ]; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}Deriving region from the previously set Zone '${ZONE}'.${RESET_FORMAT}"
    REGION="${ZONE%-*}"
  else
    echo "${RED_TEXT}${BOLD_TEXT}Cannot derive Region as Zone is not set. Please provide the region manually. 👇${RESET_FORMAT}"
    while true; do
        read -p "${GREEN_TEXT}${BOLD_TEXT}Please enter the Region (e.g., us-central1): ${RESET_FORMAT}" REGION_INPUT
        if [ -z "$REGION_INPUT" ]; then
            echo "${RED_TEXT}${BOLD_TEXT}Region cannot be empty. Please try again. 🚫${RESET_FORMAT}"
        elif [[ "$REGION_INPUT" =~ ^[a-z0-9]+-[a-z0-9]+$ ]]; then
            REGION="$REGION_INPUT"
            break
        else
            echo "${RED_TEXT}${BOLD_TEXT}Invalid region format. Expected format like 'us-central1'. Please try again. ❌${RESET_FORMAT}"
        fi
    done
  fi
fi
echo "${CYAN_TEXT}${BOLD_TEXT}✅ Using Region: ${WHITE_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🆔 Fetching your Google Cloud Project ID...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID
echo "${CYAN_TEXT}${BOLD_TEXT}✅ Using Project ID: ${WHITE_TEXT}${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔢 Fetching your Google Cloud Project Number...${RESET_FORMAT}"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo "${CYAN_TEXT}${BOLD_TEXT}✅ Using Project Number: ${WHITE_TEXT}${BOLD_TEXT}$PROJECT_NUMBER${RESET_FORMAT}"

export REGION

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Setting default compute region for gcloud commands to ${WHITE_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
gcloud config set compute/region $REGION

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🛠️ Enabling necessary Google Cloud services. This might take a moment...${RESET_FORMAT}"
gcloud services enable \
container.googleapis.com \
clouddeploy.googleapis.com \
artifactregistry.googleapis.com \
cloudbuild.googleapis.com \
clouddeploy.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT}⏳ Pausing to allow services to initialize fully...${RESET_FORMAT}"
for i in $(seq 20 -1 1); do
  echo -ne "${GREEN_TEXT}${BOLD_TEXT}   $i seconds remaining... \r${RESET_FORMAT}"
  sleep 1
done
echo -e "\n${GREEN_TEXT}${BOLD_TEXT}✅ Services initialization pause complete.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔐 Granting 'Cloud Deploy Job Runner' role to the Compute Engine default service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$(gcloud projects describe $PROJECT_ID \
--format="value(projectNumber)")-compute@developer.gserviceaccount.com \
--role="roles/clouddeploy.jobRunner"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔐 Granting 'Container Developer' role to the Compute Engine default service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$(gcloud projects describe $PROJECT_ID \
--format="value(projectNumber)")-compute@developer.gserviceaccount.com \
--role="roles/container.developer"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📦 Creating Artifact Registry repository 'cicd-challenge' for Docker images in ${WHITE_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
gcloud artifacts repositories create cicd-challenge \
--description="Image registry for tutorial web app" \
--repository-format=docker \
--location=$REGION

echo
echo "${BLUE_TEXT}${BOLD_TEXT}☸️ Creating GKE cluster 'cd-staging' in zone ${WHITE_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}${BLUE_TEXT} (asynchronously)...${RESET_FORMAT}"
gcloud container clusters create cd-staging --node-locations=$ZONE --num-nodes=1 --async
echo "${BLUE_TEXT}${BOLD_TEXT}☸️ Creating GKE cluster 'cd-production' in zone ${WHITE_TEXT}${BOLD_TEXT}$ZONE${RESET_FORMAT}${BLUE_TEXT} (asynchronously)...${RESET_FORMAT}"
gcloud container clusters create cd-production --node-locations=$ZONE --num-nodes=1 --async

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating to home directory...${RESET_FORMAT}"
cd ~/
echo "${BLUE_TEXT}${BOLD_TEXT}📥 Cloning 'cloud-deploy-tutorials' repository from GitHub...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Changing directory to 'cloud-deploy-tutorials'...${RESET_FORMAT}"
cd cloud-deploy-tutorials
echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Checking out a specific commit (c3cae80) silently...${RESET_FORMAT}"
git checkout c3cae80 --quiet
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Changing directory to 'tutorials/base'...${RESET_FORMAT}"
cd tutorials/base

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating Skaffold configuration (skaffold.yaml) from template...${RESET_FORMAT}"
envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Updating Skaffold configuration with Project ID: ${WHITE_TEXT}${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
sed -i "s/{{project-id}}/$PROJECT_ID/g" web/skaffold.yaml

echo
echo "${BLUE_TEXT}${BOLD_TEXT}☁️ Checking for Cloud Storage bucket ${WHITE_TEXT}${BOLD_TEXT}gs://${PROJECT_ID}_cloudbuild/${RESET_FORMAT}${BLUE_TEXT} and creating if it doesn't exist...${RESET_FORMAT}"
if ! gsutil ls "gs://${PROJECT_ID}_cloudbuild/" &>/dev/null; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}Bucket not found. Creating bucket in region ${WHITE_TEXT}${BOLD_TEXT}${REGION}${RESET_FORMAT}${YELLOW_TEXT}...${RESET_FORMAT}"
  gsutil mb -p "${PROJECT_ID}" -l "${REGION}" -b on "gs://${PROJECT_ID}_cloudbuild/"
  sleep 5
fi

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Changing directory to 'web'...${RESET_FORMAT}"
cd web
echo "${BLUE_TEXT}${BOLD_TEXT}🏗️ Building application using Skaffold and outputting artifacts to 'artifacts.json'...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}   Repository: ${WHITE_TEXT}${BOLD_TEXT}$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/cicd-challenge${RESET_FORMAT}"
skaffold build --interactive=false \
--default-repo $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/cicd-challenge \
--file-output artifacts.json
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating back to the parent directory...${RESET_FORMAT}"
cd ..

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📜 Copying delivery pipeline template...${RESET_FORMAT}"
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Modifying delivery pipeline: staging target to 'cd-staging'...${RESET_FORMAT}"
sed -i "s/targetId: staging/targetId: cd-staging/" clouddeploy-config/delivery-pipeline.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Modifying delivery pipeline: production target to 'cd-production'...${RESET_FORMAT}"
sed -i "s/targetId: prod/targetId: cd-production/" clouddeploy-config/delivery-pipeline.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Modifying delivery pipeline: removing 'test' target...${RESET_FORMAT}"
sed -i "/targetId: test/d" clouddeploy-config/delivery-pipeline.yaml

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📍 Setting default deploy region for gcloud to ${WHITE_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
gcloud config set deploy/region $REGION
echo "${BLUE_TEXT}${BOLD_TEXT}📜 Re-copying delivery pipeline template (ensure fresh state)...${RESET_FORMAT}"
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Modifying delivery pipeline again: staging target to 'cd-staging'...${RESET_FORMAT}"
sed -i "s/targetId: staging/targetId: cd-staging/" clouddeploy-config/delivery-pipeline.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Modifying delivery pipeline again: production target to 'cd-production'...${RESET_FORMAT}"
sed -i "s/targetId: prod/targetId: cd-production/" clouddeploy-config/delivery-pipeline.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Modifying delivery pipeline again: removing 'test' target...${RESET_FORMAT}"
sed -i "/targetId: test/d" clouddeploy-config/delivery-pipeline.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Applying the delivery pipeline configuration...${RESET_FORMAT}"
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔎 Describing the 'web-app' delivery pipeline to verify...${RESET_FORMAT}"
gcloud beta deploy delivery-pipelines describe web-app

CLUSTERS=("cd-production" "cd-staging")

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Checking status of GKE clusters: ${WHITE_TEXT}${BOLD_TEXT}${CLUSTERS[*]}${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
for cluster in "${CLUSTERS[@]}"; do
  status=$(gcloud container clusters describe "$cluster" --format="value(status)")
  
  while [ "$status" != "RUNNING" ]; do
    echo "${YELLOW_TEXT}⏳ Cluster ${BOLD_TEXT}$cluster${RESET_FORMAT}${YELLOW_TEXT} is currently ${BOLD_TEXT}$status${RESET_FORMAT}${YELLOW_TEXT}. Waiting for it to be 'RUNNING'...${RESET_FORMAT}"
    echo "${MAGENTA_TEXT}💡 Tip: While waiting, you can check out Arcade Crew for more awesome tutorials! [https://www.youtube.com/@Arcade61432]${RESET_FORMAT}"
    for i in $(seq 10 -1 1); do
      echo -ne "${YELLOW_TEXT}   Waiting... ${BOLD_TEXT}$i${RESET_FORMAT}${YELLOW_TEXT} seconds remaining. \r${RESET_FORMAT}"
      sleep 1
    done
    echo -ne "\033[K" # Clear the line after the countdown
    status=$(gcloud container clusters describe "$cluster" --format="value(status)")
  done
  
  echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cluster ${WHITE_TEXT}${BOLD_TEXT}$cluster${RESET_FORMAT}${GREEN_TEXT}${BOLD_TEXT} is now RUNNING! Proceeding...${RESET_FORMAT}"
done

CONTEXTS=("cd-staging" "cd-production" )
echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔗 Configuring kubectl contexts for clusters: ${WHITE_TEXT}${BOLD_TEXT}${CONTEXTS[*]}${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
for CONTEXT in ${CONTEXTS[@]}
do
    echo "${BLUE_TEXT}${BOLD_TEXT}   Getting credentials for cluster ${WHITE_TEXT}${BOLD_TEXT}$CONTEXT${RESET_FORMAT}${BLUE_TEXT} in region ${WHITE_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    echo "${BLUE_TEXT}${BOLD_TEXT}   Renaming context for ${WHITE_TEXT}${BOLD_TEXT}$CONTEXT${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🏷️ Applying Kubernetes namespace configuration to contexts: ${WHITE_TEXT}${BOLD_TEXT}${CONTEXTS[*]}${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
for CONTEXT in ${CONTEXTS[@]}
do
    echo "${BLUE_TEXT}${BOLD_TEXT}   Applying namespace to context ${WHITE_TEXT}${BOLD_TEXT}$CONTEXT${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating Cloud Deploy target configuration for 'cd-staging' from template...${RESET_FORMAT}"
envsubst < clouddeploy-config/target-staging.yaml.template > clouddeploy-config/target-cd-staging.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating Cloud Deploy target configuration for 'cd-production' from template...${RESET_FORMAT}"
envsubst < clouddeploy-config/target-prod.yaml.template > clouddeploy-config/target-cd-production.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Updating target configuration name for 'cd-staging'...${RESET_FORMAT}"
sed -i "s/staging/cd-staging/" clouddeploy-config/target-cd-staging.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Updating target configuration name for 'cd-production'...${RESET_FORMAT}"
sed -i "s/prod/cd-production/" clouddeploy-config/target-cd-production.yaml

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🎯 Applying Cloud Deploy target configurations for contexts: ${WHITE_TEXT}${BOLD_TEXT}${CONTEXTS[*]}${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
for CONTEXT in ${CONTEXTS[@]}
do
    echo "${BLUE_TEXT}${BOLD_TEXT}   Generating and applying target configuration for ${WHITE_TEXT}${BOLD_TEXT}$CONTEXT${RESET_FORMAT}${BLUE_TEXT}...${RESET_FORMAT}"
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}릴리스 Creating first release 'web-app-001' for delivery pipeline 'web-app'...${RESET_FORMAT}"
gcloud beta deploy releases create web-app-001 \
--delivery-pipeline web-app \
--build-artifacts web/artifacts.json \
--source web/

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📋 Listing rollouts for release 'web-app-001'...${RESET_FORMAT}"
gcloud beta deploy rollouts list \
--delivery-pipeline web-app \
--release web-app-001

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Monitoring initial rollout for 'web-app-001'. This may take some time...${RESET_FORMAT}"
while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  if [ "$status" == "SUCCEEDED" ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✅ Rollout to staging for 'web-app-001' SUCCEEDED!${RESET_FORMAT}"
    break
  fi
  echo "${YELLOW_TEXT}${BOLD_TEXT}   Current rollout status: ${WHITE_TEXT}${BOLD_TEXT}$status${RESET_FORMAT}${YELLOW_TEXT}. Waiting... (Check Arcade Crew for tips! [https://www.youtube.com/@Arcade61432])${RESET_FORMAT}"
  for i in $(seq 10 -1 1); do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}   Checking again in $i seconds... \r${RESET_FORMAT}"
    sleep 1
  done
  echo -ne "\033[K" # Clear the line after the countdown
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Promoting release 'web-app-001' to the next stage...${RESET_FORMAT}"
gcloud beta deploy releases promote \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for release 'web-app-001' to reach 'PENDING_APPROVAL' state for production...${RESET_FORMAT}"
while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  if [ "$status" == "PENDING_APPROVAL" ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✅ Rollout for 'web-app-001' is now PENDING_APPROVAL for production!${RESET_FORMAT}"
    break
  fi
  echo "${YELLOW_TEXT}${BOLD_TEXT}   Current rollout status: ${WHITE_TEXT}${BOLD_TEXT}$status${RESET_FORMAT}${YELLOW_TEXT}. Waiting... (Arcade Crew has great content! [https://www.youtube.com/@Arcade61432])${RESET_FORMAT}"
  for i in $(seq 10 -1 1); do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}   Checking again in $i seconds... \r${RESET_FORMAT}"
    sleep 1
  done
  echo -ne "\033[K" # Clear the line after the countdown
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}👍 Approving rollout 'web-app-001-to-cd-production-0001' for production...${RESET_FORMAT}"
gcloud beta deploy rollouts approve web-app-001-to-cd-production-0001 \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Monitoring production rollout for 'web-app-001'. This may take some time...${RESET_FORMAT}"
while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  if [ "$status" == "SUCCEEDED" ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✅ Production rollout for 'web-app-001' SUCCEEDED! 🎉${RESET_FORMAT}"
    break
  fi
  echo "${YELLOW_TEXT}${BOLD_TEXT}   Current rollout status: ${WHITE_TEXT}${BOLD_TEXT}$status${RESET_FORMAT}${YELLOW_TEXT}. Waiting... (Find more at Arcade Crew! [https://www.youtube.com/@Arcade61432])${RESET_FORMAT}"
  for i in $(seq 10 -1 1); do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}   Checking again in $i seconds... \r${RESET_FORMAT}"
    sleep 1
  done
  echo -ne "\033[K" # Clear the line after the countdown
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🛠️ Ensuring Cloud Build API (cloudbuild.googleapis.com) is enabled...${RESET_FORMAT}"
gcloud services enable cloudbuild.googleapis.com

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Resetting to tutorial base for the next steps...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating to home directory...${RESET_FORMAT}"
cd ~/
echo "${BLUE_TEXT}${BOLD_TEXT}📥 Cloning 'cloud-deploy-tutorials' repository again (or ensuring it's up-to-date)...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Changing directory to 'cloud-deploy-tutorials'...${RESET_FORMAT}"
cd cloud-deploy-tutorials
echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Checking out specific commit (c3cae80) silently again...${RESET_FORMAT}"
git checkout c3cae80 --quiet
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Changing directory to 'tutorials/base'...${RESET_FORMAT}"
cd tutorials/base

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating Skaffold configuration (skaffold.yaml) from template again...${RESET_FORMAT}"
envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}📄 Displaying the generated Skaffold configuration:${RESET_FORMAT}"
cat web/skaffold.yaml

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Changing directory to 'web'...${RESET_FORMAT}"
cd web
echo "${BLUE_TEXT}${BOLD_TEXT}🏗️ Building application again using Skaffold for a new release...${RESET_FORMAT}"
skaffold build --interactive=false \
--default-repo $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/cicd-challenge \
--file-output artifacts.json
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating back to the parent directory...${RESET_FORMAT}"
cd ..

echo
echo "${BLUE_TEXT}${BOLD_TEXT}릴리스 Creating second release 'web-app-002' for delivery pipeline 'web-app'...${RESET_FORMAT}"
gcloud beta deploy releases create web-app-002 \
--delivery-pipeline web-app \
--build-artifacts web/artifacts.json \
--source web/

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Monitoring rollout for 'web-app-002'. This may take some time...${RESET_FORMAT}"
while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-002 --format="value(state)" | head -n 1)
  if [ "$status" == "SUCCEEDED" ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✅ Rollout to staging for 'web-app-002' SUCCEEDED!${RESET_FORMAT}"
    break
  fi
  echo "${YELLOW_TEXT}${BOLD_TEXT}   Current rollout status: ${WHITE_TEXT}${BOLD_TEXT}$status${RESET_FORMAT}${YELLOW_TEXT}. Waiting... (Don't forget Arcade Crew! [https://www.youtube.com/@Arcade61432])${RESET_FORMAT}"
  for i in $(seq 10 -1 1); do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}   Checking again in $i seconds... \r${RESET_FORMAT}"
    sleep 1
  done
  echo -ne "\033[K" # Clear the line after the countdown
done

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏪ Rolling back target 'cd-staging' for delivery pipeline 'web-app'...${RESET_FORMAT}"
gcloud deploy targets rollback cd-staging \
   --delivery-pipeline=web-app \
   --quiet

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://youtube.com/@arcadewithus_we?${RESET_FORMAT}"
echo
