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

echo "${GREEN_TEXT}${BOLD_TEXT}📋 PHASE 1: Environment Configuration${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Setting up essential project variables and environment parameters...${RESET_FORMAT}"
echo
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
export CLUSTER=hello-cluster
export REPO=my-repository

echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 PHASE 2: Service Activation${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Activating necessary Google Cloud Platform APIs for container, build, and source repository services...${RESET_FORMAT}"
echo
gcloud services enable container.googleapis.com \
  cloudbuild.googleapis.com \
  sourcerepo.googleapis.com

echo "${CYAN_TEXT}${BOLD_TEXT}📦 PHASE 3: Artifact Repository Setup${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Creating Docker artifact repository for storing container images...${RESET_FORMAT}"
echo
gcloud artifacts repositories create $REPO \
  --repository-format=docker \
  --location=$REGION \
  --description="Dr Abhishek"

spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

echo "${WHITE_TEXT}${BOLD_TEXT}Setting up repository...${RESET_FORMAT}"
(gcloud artifacts repositories list --location=$REGION > /dev/null 2>&1) & spinner
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Repository setup completed!${RESET_FORMAT}"

echo "${MAGENTA_TEXT}${BOLD_TEXT}🔐 PHASE 4: IAM Configuration${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Configuring Cloud Build service account permissions for container development...${RESET_FORMAT}"
echo
msg=$(echo "U3Vic2NyaWJlIHRvIERyIEFiaGlzaGVr" | base64 --decode)
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$(gcloud projects describe $PROJECT_ID \
--format="value(projectNumber)")@cloudbuild.gserviceaccount.com --role="roles/container.developer"

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ PHASE 5: GitHub Integration${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Installing GitHub CLI and setting up Git configuration for repository management...${RESET_FORMAT}"
echo
(echo "Installing GitHub CLI..." && curl -sS https://webi.sh/gh | sh) & spinner
gh auth login
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT} $msg ${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}☸️ PHASE 6: Kubernetes Cluster Deployment${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Creating Google Kubernetes Engine cluster with optimized settings for development and production...${RESET_FORMAT}"
echo
(gcloud beta container --project "$PROJECT_ID" clusters create "$CLUSTER" --zone "$ZONE" --no-enable-basic-auth --cluster-version latest --release-channel "regular" --machine-type "e2-medium" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true  --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" --subnetwork "projects/$PROJECT_ID/regions/$REGION/subnetworks/default" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --enable-autoscaling --min-nodes "2" --max-nodes "6" --location-policy "BALANCED" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --enable-shielded-nodes --node-locations "$ZONE") & spinner

echo "${CYAN_TEXT}${BOLD_TEXT}🎛️ PHASE 7: Kubernetes Environment Setup${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Configuring cluster credentials and creating development and production namespaces...${RESET_FORMAT}"
echo
(gcloud container clusters get-credentials hello-cluster --zone=$ZONE > /dev/null 2>&1) & spinner
kubectl create namespace prod
kubectl create namespace dev

echo "${MAGENTA_TEXT}${BOLD_TEXT}📁 PHASE 8: Repository Initialization${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Creating GitHub repository and cloning sample application code for DevOps workflow...${RESET_FORMAT}"
echo
(gh repo create sample-app --private > /dev/null 2>&1) & spinner
git clone https://github.com/${GITHUB_USERNAME}/sample-app.git
cd ~
(gsutil cp -r gs://spls/gsp330/sample-app/* sample-app > /dev/null 2>&1) & spinner
for file in sample-app/cloudbuild-dev.yaml sample-app/cloudbuild.yaml; do
  sed -i "s/<your-region>/${REGION}/g" "$file"
  sed -i "s/<your-zone>/${ZONE}/g" "$file"
done

echo
echo "${CYAN_TEXT}${BOLD_TEXT} $msg ${RESET_FORMAT}"
echo

git init
cd sample-app/
git checkout -b master
git add .
git commit -m "Dr Abhishek" 
git push -u origin master

git add .
git commit -m "Initial commit with sample code"
git push origin master
git checkout -b dev
git commit -m "Initial commit for dev branch"
git push origin dev

echo
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔗 Cloud Build Trigger Configuration${RESET_FORMAT}"
echo "https://console.cloud.google.com/cloud-build/triggers;region=global/add?project=$PROJECT_ID"

echo

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Have you completed the video steps and created the Cloud Build trigger?${RESET_FORMAT}"
read -p " (y/n): " answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
  echo "${GREEN_TEXT}${BOLD_TEXT}🎉 Excellent! Proceeding with application deployment...${RESET_FORMAT}"
else
  echo "${RED_TEXT}${BOLD_TEXT}⚠️ Please complete the video steps to create the Cloud Build trigger before continuing.${RESET_FORMAT}"
fi

echo "${GREEN_TEXT}${BOLD_TEXT}🔄 Re-initializing Environment Variables${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Refreshing project configuration to ensure consistency...${RESET_FORMAT}"
echo
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
export CLUSTER=hello-cluster
export REPO=my-repository

echo "${BLUE_TEXT}${BOLD_TEXT}📂 PHASE 9: Application Directory Navigation${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Moving to sample application directory for build operations...${RESET_FORMAT}"
echo
cd sample-app

echo "${YELLOW_TEXT}${BOLD_TEXT}🏗️ PHASE 10: Container Image Build & Push${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Building Docker image and pushing to Artifact Registry using Cloud Build...${RESET_FORMAT}"
echo
msg=$(echo "U3Vic2NyaWJlIHRvIERyIEFiaGlzaGVr" | base64 --decode)
COMMIT_ID="$(git rev-parse --short=7 HEAD)"
(gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/$REPO/hello-cloudbuild:${COMMIT_ID}" .) & spinner

EXPORTED_IMAGE="$(gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/$REPO/hello-cloudbuild:${COMMIT_ID}" . | grep IMAGES | awk '{print $2}')"

echo "${CYAN_TEXT}${BOLD_TEXT}🔀 PHASE 11: Development Branch Configuration${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Switching to development branch and updating Cloud Build configuration files...${RESET_FORMAT}"
echo
git checkout dev

sed -i "9c\    args: ['build', '-t', '$REGION-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild-dev:v1.0', '.']" cloudbuild-dev.yaml

sed -i "13c\    args: ['push', '$REGION-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild-dev:v1.0']" cloudbuild-dev.yaml

sed -i "17s|        image: <todo>|        image: $REGION-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild-dev:v1.0|" dev/deployment.yaml

git add .
git commit -m "Dr Abhishek" 
git push -u origin dev

echo "${WHITE_TEXT}${BOLD_TEXT}Deploying development version..."
(gcloud builds submit --config=cloudbuild-dev.yaml . > /dev/null 2>&1) & spinner
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Development deployment completed!${RESET_FORMAT}"

echo "${MAGENTA_TEXT}${BOLD_TEXT}🚀 PHASE 12: Production Branch Setup${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Switching to master branch and exposing development deployment service...${RESET_FORMAT}"
echo
git checkout master

(kubectl expose deployment development-deployment -n dev --name=dev-deployment-service --type=LoadBalancer --port 8080 --target-port 8080 > /dev/null 2>&1) & spinner

sed -i "11c\    args: ['build', '-t', '$REGION-docker.pkg.dev/\$PROJECT_ID/my-repository/hello-cloudbuild:v1.0', '.']" cloudbuild.yaml

sed -i "16c\    args: ['push', '$REGION-docker.pkg.dev/\$PROJECT_ID/my-repository/hello-cloudbuild:v1.0']" cloudbuild.yaml

sed -i "17c\        image:  $REGION-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild:v1.0" prod/deployment.yaml

git add .
git commit -m "Dr Abhishek" 
git push -u origin master

echo "${WHITE_TEXT}${BOLD_TEXT}Deploying production version..."
(gcloud builds submit --config=cloudbuild.yaml . > /dev/null 2>&1) & spinner
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Production deployment completed!${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}🌐 PHASE 13: Production Service Exposure${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Creating LoadBalancer service for production deployment accessibility...${RESET_FORMAT}"
echo
(kubectl expose deployment production-deployment -n prod --name=prod-deployment-service --type=LoadBalancer --port 8080 --target-port 8080 > /dev/null 2>&1) & spinner

echo
echo "${CYAN_TEXT}${BOLD_TEXT} $msg ${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 PHASE 14: Development v2.0 Enhancement${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Implementing new features in development branch with red handler functionality...${RESET_FORMAT}"
echo
git checkout dev

sed -i '28a\	http.HandleFunc("/red", redHandler)' main.go

sed -i '32a\
func redHandler(w http.ResponseWriter, r *http.Request) { \
  img := image.NewRGBA(image.Rect(0, 0, 100, 100)) \
  draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{255, 0, 0, 255}}, image.ZP, draw.Src) \
  w.Header().Set("Content-Type", "image/png") \
  png.Encode(w, img) \
}' main.go

sed -i "9c\    args: ['build', '-t', '$REGION-docker.pkg.dev/\$PROJECT_ID/my-repository/hello-cloudbuild-dev:v2.0', '.']" cloudbuild-dev.yaml

sed -i "13c\    args: ['push', '$REGION-docker.pkg.dev/\$PROJECT_ID/my-repository/hello-cloudbuild-dev:v2.0']" cloudbuild-dev.yaml

sed -i "17c\        image: $REGION-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild:v2.0" dev/deployment.yaml

git add .
git commit -m "Dr Abhishek" 
git push -u origin dev

echo "${WHITE_TEXT}${BOLD_TEXT}Deploying development v2.0..."
(gcloud builds submit --config=cloudbuild-dev.yaml . > /dev/null 2>&1) & spinner
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Development v2.0 deployment completed!${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT} $msg ${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🎯 PHASE 15: Production v2.0 Deployment${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Merging new features to production branch and updating deployment configurations...${RESET_FORMAT}"
echo
git checkout master

sed -i '28a\	http.HandleFunc("/red", redHandler)' main.go

sed -i '32a\
func redHandler(w http.ResponseWriter, r *http.Request) { \
  img := image.NewRGBA(image.Rect(0, 0, 100, 100)) \
  draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{255, 0, 0, 255}}, image.ZP, draw.Src) \
  w.Header().Set("Content-Type", "image/png") \
  png.Encode(w, img) \
}' main.go


sed -i "11c\    args: ['build', '-t', '$REGION-docker.pkg.dev/\$PROJECT_ID/my-repository/hello-cloudbuild:v2.0', '.']" cloudbuild.yaml

sed -i "16c\    args: ['push', '$REGION-docker.pkg.dev/\$PROJECT_ID/my-repository/hello-cloudbuild:v2.0']" cloudbuild.yaml

sed -i "17c\        image: $REGION-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild:v2.0" prod/deployment.yaml

git add .
git commit -m "Dr Abhishek" 
git push -u origin master

echo "${WHITE_TEXT}${BOLD_TEXT}Deploying production v2.0..."
(gcloud builds submit --config=cloudbuild.yaml . > /dev/null 2>&1) & spinner
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Production v2.0 deployment completed!${RESET_FORMAT}"

echo "${GREEN_TEXT}${BOLD_TEXT}⏪ PHASE 16: Rollback & Validation${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Performing deployment rollback and validating container image versions...${RESET_FORMAT}"
echo
(kubectl -n prod rollout undo deployment/production-deployment > /dev/null 2>&1) & spinner

kubectl -n prod get pods -o jsonpath --template='{range .items[*]}{.metadata.name}{"\t"}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

cd

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
