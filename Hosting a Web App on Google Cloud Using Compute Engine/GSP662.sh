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
echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Attempting to fetch the default GCP project zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items.google-compute-default-zone)" 2>/dev/null)

if [ -z "$ZONE" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Cloud Shell default zone not automatically found.${RESET_FORMAT}"
  while [ -z "$ZONE" ]; do
    read -p "${GREEN_TEXT}${BOLD_TEXT}✍️  Please enter your desired GCP zone: ${RESET_FORMAT}" ZONE
    if [ -z "$ZONE" ]; then
      echo "${RED_TEXT}${BOLD_TEXT}❌ Zone cannot be empty. Please provide a valid zone.${RESET_FORMAT}"
    fi
  done
  echo "${BLUE_TEXT}${BOLD_TEXT}🗺️  Using user-provided zone: $ZONE${RESET_FORMAT}"
fi

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Attempting to fetch the default GCP project region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items.google-compute-default-region)" 2>/dev/null)

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Cloud Shell default region not automatically found. Deriving from zone...${RESET_FORMAT}"
  REGION=${ZONE%-*}
  echo "${BLUE_TEXT}${BOLD_TEXT}🗺️  Derived region from zone: $REGION${RESET_FORMAT}"
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📍 Current Zone for Operations: ${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Current Region for Operations: ${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Setting the default compute zone in gcloud config...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Setting the default compute region in gcloud config...${RESET_FORMAT}"
gcloud config set compute/region $REGION

echo "${CYAN_TEXT}${BOLD_TEXT}🛠️  Enabling the Compute Engine API for your project...${RESET_FORMAT}"
gcloud services enable compute.googleapis.com

echo "${CYAN_TEXT}${BOLD_TEXT}🪣  Creating a Google Cloud Storage bucket named 'fancy-store-$DEVSHELL_PROJECT_ID'...${RESET_FORMAT}"
gsutil mb gs://fancy-store-$DEVSHELL_PROJECT_ID

echo "${CYAN_TEXT}${BOLD_TEXT}📥  Cloning the 'monolith-to-microservices' repository from GitHub...${RESET_FORMAT}"
git clone https://github.com/googlecodelabs/monolith-to-microservices.git

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Changing directory to '~/monolith-to-microservices'...${RESET_FORMAT}"
cd ~/monolith-to-microservices

echo "${CYAN_TEXT}${BOLD_TEXT}🚀 Running the setup script './setup.sh' from the repository...${RESET_FORMAT}"
./setup.sh

echo "${CYAN_TEXT}${BOLD_TEXT}📦 Installing the Long-Term Support (LTS) version of Node.js using nvm...${RESET_FORMAT}"
nvm install --lts

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Changing directory to 'monolith-to-microservices/' (likely a sub-directory, ensure path is correct if script was in root)...${RESET_FORMAT}"
cd monolith-to-microservices/ # Corrected to match original, assuming it's relative from previous cd

echo "${CYAN_TEXT}${BOLD_TEXT}📝 Creating the startup script (startup-script.sh) for Compute Engine instances...${RESET_FORMAT}"
cat > startup-script.sh <<EOF_START
#!/bin/bash
# Install logging monitor. The monitor will automatically pick up logs sent to syslog.
curl -s "https://storage.googleapis.com/signals-agents/logging/google-fluentd-install.sh" | bash
service google-fluentd restart &
# Install dependencies from apt
apt-get update
apt-get install -yq ca-certificates git build-essential supervisor psmisc
# Install nodejs
mkdir /opt/nodejs
curl https://nodejs.org/dist/v16.14.0/node-v16.14.0-linux-x64.tar.gz | tar xvzf - -C /opt/nodejs --strip-components=1
ln -s /opt/nodejs/bin/node /usr/bin/node
ln -s /opt/nodejs/bin/npm /usr/bin/npm
# Get the application source code from the Google Cloud Storage bucket.
mkdir /fancy-store
gsutil -m cp -r gs://fancy-store-$DEVSHELL_PROJECT_ID/monolith-to-microservices/microservices/* /fancy-store/
# Install app dependencies.
cd /fancy-store/
npm install
# Create a nodeapp user. The application will run as this user.
useradd -m -d /home/nodeapp nodeapp
chown -R nodeapp:nodeapp /opt/app
# Configure supervisor to run the node app.
cat >/etc/supervisor/conf.d/node-app.conf <<EOF_END
[program:nodeapp]
directory=/fancy-store
command=npm start
autostart=true
autorestart=true
user=nodeapp
environment=HOME="/home/nodeapp",USER="nodeapp",NODE_ENV="production"
stdout_logfile=syslog
stderr_logfile=syslog
EOF_END
supervisorctl reread
supervisorctl update
EOF_START

echo "${CYAN_TEXT}${BOLD_TEXT}🏠 Returning to the home directory...${RESET_FORMAT}"
cd ~

echo "${CYAN_TEXT}${BOLD_TEXT}📤 Uploading the 'startup-script.sh' to your GCS bucket...${RESET_FORMAT}"
gsutil cp ~/monolith-to-microservices/startup-script.sh gs://fancy-store-$DEVSHELL_PROJECT_ID

echo "${CYAN_TEXT}${BOLD_TEXT}🏠 Returning to the home directory again...${RESET_FORMAT}"
cd ~
echo "${CYAN_TEXT}${BOLD_TEXT}🧹 Cleaning up 'node_modules' directories before uploading source code...${RESET_FORMAT}"
rm -rf monolith-to-microservices/*/node_modules
echo "${CYAN_TEXT}${BOLD_TEXT}📤 Uploading the 'monolith-to-microservices' source code to your GCS bucket...${RESET_FORMAT}"
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

echo "${CYAN_TEXT}${BOLD_TEXT}🚀 Creating the 'backend' Compute Engine instance...${RESET_FORMAT}"
gcloud compute instances create backend \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --tags=backend \
   --metadata=startup-script-url=https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh

echo "${CYAN_TEXT}${BOLD_TEXT}📊 Listing all Compute Engine instances in the project...${RESET_FORMAT}"
gcloud compute instances list

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Fetching the external IP address of the 'backend' instance...${RESET_FORMAT}"
export EXTERNAL_IP_BACKEND=$(gcloud compute instances describe backend --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Changing directory to 'monolith-to-microservices/react-app'...${RESET_FORMAT}"
cd monolith-to-microservices/react-app

echo "${CYAN_TEXT}${BOLD_TEXT}📝 Creating the '.env' file for the React application with backend URLs...${RESET_FORMAT}"
cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_BACKEND:8081/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_BACKEND:8082/api/products
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}🏠 Returning to the home directory...${RESET_FORMAT}"
cd ~

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Changing directory to '~/monolith-to-microservices/react-app' for building...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
echo "${CYAN_TEXT}${BOLD_TEXT}📦 Installing dependencies and building the React application...${RESET_FORMAT}"
npm install && npm run-script build

echo "${CYAN_TEXT}${BOLD_TEXT}🏠 Returning to the home directory...${RESET_FORMAT}"
cd ~
echo "${CYAN_TEXT}${BOLD_TEXT}🧹 Cleaning up 'node_modules' directories again before uploading updated source code...${RESET_FORMAT}"
rm -rf monolith-to-microservices/*/node_modules

echo "${CYAN_TEXT}${BOLD_TEXT}📤 Uploading the updated 'monolith-to-microservices' source (with built React app) to GCS...${RESET_FORMAT}"
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

echo "${CYAN_TEXT}${BOLD_TEXT}🚀 Creating the 'frontend' Compute Engine instance...${RESET_FORMAT}"
gcloud compute instances create frontend \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --tags=frontend \
    --metadata=startup-script-url=https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Creating a firewall rule 'fw-fe' to allow TCP traffic on port 8080 for 'frontend' tagged instances...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-fe \
    --allow tcp:8080 \
    --target-tags=frontend

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Creating a firewall rule 'fw-be' to allow TCP traffic on ports 8081-8082 for 'backend' tagged instances...${RESET_FORMAT}"
gcloud compute firewall-rules create fw-be \
    --allow tcp:8081-8082 \
    --target-tags=backend

echo "${CYAN_TEXT}${BOLD_TEXT}📊 Listing all Compute Engine instances again...${RESET_FORMAT}"
gcloud compute instances list

echo "${CYAN_TEXT}${BOLD_TEXT}🛑 Stopping the 'frontend' instance (preparation for template creation)...${RESET_FORMAT}"
gcloud compute instances stop frontend --zone=$ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}🛑 Stopping the 'backend' instance (preparation for template creation)...${RESET_FORMAT}"
gcloud compute instances stop backend --zone=$ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}📄 Creating an instance template 'fancy-fe' from the 'frontend' instance...${RESET_FORMAT}"
gcloud compute instance-templates create fancy-fe \
    --source-instance-zone=$ZONE \
    --source-instance=frontend

echo "${CYAN_TEXT}${BOLD_TEXT}📄 Creating an instance template 'fancy-be' from the 'backend' instance...${RESET_FORMAT}"
gcloud compute instance-templates create fancy-be \
    --source-instance-zone=$ZONE \
    --source-instance=backend

echo "${CYAN_TEXT}${BOLD_TEXT}📊 Listing all instance templates...${RESET_FORMAT}"
gcloud compute instance-templates list

echo "${CYAN_TEXT}${BOLD_TEXT}🗑️  Deleting the standalone 'backend' instance as it will be managed by an instance group...${RESET_FORMAT}"
gcloud compute instances delete --quiet backend --zone=$ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}🏗️  Creating a managed instance group 'fancy-fe-mig' for the frontend...${RESET_FORMAT}"
gcloud compute instance-groups managed create fancy-fe-mig \
    --zone=$ZONE \
    --base-instance-name fancy-fe \
    --size 2 \
    --template fancy-fe

echo "${CYAN_TEXT}${BOLD_TEXT}🏗️  Creating a managed instance group 'fancy-be-mig' for the backend...${RESET_FORMAT}"
gcloud compute instance-groups managed create fancy-be-mig \
    --zone=$ZONE \
    --base-instance-name fancy-be \
    --size 2 \
    --template fancy-be

echo "${CYAN_TEXT}${BOLD_TEXT}🏷️  Setting named ports for 'fancy-fe-mig' (frontend:8080)...${RESET_FORMAT}"
gcloud compute instance-groups set-named-ports fancy-fe-mig \
    --zone=$ZONE \
    --named-ports frontend:8080

echo "${CYAN_TEXT}${BOLD_TEXT}🏷️  Setting named ports for 'fancy-be-mig' (orders:8081, products:8082)...${RESET_FORMAT}"
gcloud compute instance-groups set-named-ports fancy-be-mig \
    --zone=$ZONE \
    --named-ports orders:8081,products:8082

echo "${CYAN_TEXT}${BOLD_TEXT}❤️  Creating an HTTP health check 'fancy-fe-hc' for the frontend on port 8080...${RESET_FORMAT}"
gcloud compute health-checks create http fancy-fe-hc \
    --port 8080 \
    --check-interval 30s \
    --healthy-threshold 1 \
    --timeout 10s \
    --unhealthy-threshold 3

echo "${CYAN_TEXT}${BOLD_TEXT}❤️  Creating an HTTP health check 'fancy-be-hc' for the backend orders service on port 8081...${RESET_FORMAT}"
gcloud compute health-checks create http fancy-be-hc \
    --port 8081 \
    --request-path=/api/orders \
    --check-interval 30s \
    --healthy-threshold 1 \
    --timeout 10s \
    --unhealthy-threshold 3

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Creating a firewall rule 'allow-health-check' for Google Cloud health checkers...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-health-check \
    --allow tcp:8080-8081 \
    --source-ranges 130.211.0.0/22,35.191.0.0/16 \
    --network default

echo "${CYAN_TEXT}${BOLD_TEXT}🔄 Updating 'fancy-fe-mig' with the health check 'fancy-fe-hc' and initial delay...${RESET_FORMAT}"
gcloud compute instance-groups managed update fancy-fe-mig \
    --zone=$ZONE \
    --health-check fancy-fe-hc \
    --initial-delay 300

echo "${CYAN_TEXT}${BOLD_TEXT}🔄 Updating 'fancy-be-mig' with the health check 'fancy-be-hc' and initial delay...${RESET_FORMAT}"
gcloud compute instance-groups managed update fancy-be-mig \
    --zone=$ZONE \
    --health-check fancy-be-hc \
    --initial-delay 300

echo "${CYAN_TEXT}${BOLD_TEXT}❤️  Creating HTTP health check 'fancy-fe-frontend-hc' for the frontend service...${RESET_FORMAT}"
gcloud compute http-health-checks create fancy-fe-frontend-hc \
  --request-path / \
  --port 8080

echo "${CYAN_TEXT}${BOLD_TEXT}❤️  Creating HTTP health check 'fancy-be-orders-hc' for the orders backend service...${RESET_FORMAT}"
gcloud compute http-health-checks create fancy-be-orders-hc \
  --request-path /api/orders \
  --port 8081

echo "${CYAN_TEXT}${BOLD_TEXT}❤️  Creating HTTP health check 'fancy-be-products-hc' for the products backend service...${RESET_FORMAT}"
gcloud compute http-health-checks create fancy-be-products-hc \
  --request-path /api/products \
  --port 8082

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Creating backend service 'fancy-fe-frontend' for the frontend...${RESET_FORMAT}"
gcloud compute backend-services create fancy-fe-frontend \
  --http-health-checks fancy-fe-frontend-hc \
  --port-name frontend \
  --global

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Creating backend service 'fancy-be-orders' for the orders microservice...${RESET_FORMAT}"
gcloud compute backend-services create fancy-be-orders \
  --http-health-checks fancy-be-orders-hc \
  --port-name orders \
  --global

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Creating backend service 'fancy-be-products' for the products microservice...${RESET_FORMAT}"
gcloud compute backend-services create fancy-be-products \
  --http-health-checks fancy-be-products-hc \
  --port-name products \
  --global

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Adding 'fancy-fe-mig' as a backend to 'fancy-fe-frontend' service...${RESET_FORMAT}"
gcloud compute backend-services add-backend fancy-fe-frontend \
  --instance-group-zone=$ZONE \
  --instance-group fancy-fe-mig \
  --global

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Adding 'fancy-be-mig' as a backend to 'fancy-be-orders' service...${RESET_FORMAT}"
gcloud compute backend-services add-backend fancy-be-orders \
  --instance-group-zone=$ZONE \
  --instance-group fancy-be-mig \
  --global

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Adding 'fancy-be-mig' as a backend to 'fancy-be-products' service...${RESET_FORMAT}"
gcloud compute backend-services add-backend fancy-be-products \
  --instance-group-zone=$ZONE \
  --instance-group fancy-be-mig \
  --global

echo "${CYAN_TEXT}${BOLD_TEXT}🗺️  Creating URL map 'fancy-map' with default service 'fancy-fe-frontend'...${RESET_FORMAT}"
gcloud compute url-maps create fancy-map \
  --default-service fancy-fe-frontend

echo "${CYAN_TEXT}${BOLD_TEXT}🛣️  Adding path matchers to 'fancy-map' for orders and products APIs...${RESET_FORMAT}"
gcloud compute url-maps add-path-matcher fancy-map \
   --default-service fancy-fe-frontend \
   --path-matcher-name orders \
   --path-rules "/api/orders=fancy-be-orders,/api/products=fancy-be-products"


echo "${CYAN_TEXT}${BOLD_TEXT}🌐 Creating target HTTP proxy 'fancy-proxy' using 'fancy-map'...${RESET_FORMAT}"
gcloud compute target-http-proxies create fancy-proxy \
  --url-map fancy-map

echo "${CYAN_TEXT}${BOLD_TEXT}➡️  Creating global forwarding rule 'fancy-http-rule' to direct traffic to 'fancy-proxy'...${RESET_FORMAT}"
gcloud compute forwarding-rules create fancy-http-rule \
  --global \
  --target-http-proxy fancy-proxy \
  --ports 80

echo
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}✅     CHECK ALL PROGRESS TILL TASK 6     ✅${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}🤔 Have you checked all progress upto TASK 6? (Y/N): ${RESET_FORMAT}" CHECK_PROGRESS
if [[ $CHECK_PROGRESS == "Y" || $CHECK_PROGRESS == "y" ]]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}👍 Awesome! Continuing to the next set of configurations...${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}✋ Please review the progress up to Task 6 before continuing. Exiting for now.${RESET_FORMAT}"
fi

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Re-fetching the default GCP project zone (if changed or for confirmation)...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items.google-compute-default-zone)" 2>/dev/null)

if [ -z "$ZONE" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Cloud Shell default zone not automatically found post-checkpoint.${RESET_FORMAT}"
  while [ -z "$ZONE" ]; do
    read -p "${GREEN_TEXT}${BOLD_TEXT}✍️  Please re-enter your desired GCP zone (e.g., us-central1-a): ${RESET_FORMAT}" ZONE
    if [ -z "$ZONE" ]; then
      echo "${RED_TEXT}${BOLD_TEXT}❌ Zone cannot be empty. Please provide a valid zone.${RESET_FORMAT}"
    fi
  done
  echo "${BLUE_TEXT}${BOLD_TEXT}🗺️  Using user-provided zone for subsequent operations: $ZONE${RESET_FORMAT}"
fi

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Re-fetching the default GCP project region (if changed or for confirmation)...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items.google-compute-default-region)" 2>/dev/null)

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  Cloud Shell default region not automatically found post-checkpoint. Deriving from zone...${RESET_FORMAT}"
  REGION=${ZONE%-*}
  echo "${BLUE_TEXT}${BOLD_TEXT}🗺️  Derived region from zone for subsequent operations: $REGION${RESET_FORMAT}"
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📍 Confirming Zone for Operations: ${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Confirming Region for Operations: ${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Re-setting the default compute zone in gcloud config...${RESET_FORMAT}"
gcloud config set compute/zone $ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Re-setting the default compute region in gcloud config...${RESET_FORMAT}"
gcloud config set compute/region $REGION

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Changing directory to '~/monolith-to-microservices/react-app/'...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app/

echo "${CYAN_TEXT}${BOLD_TEXT}📊 Listing global forwarding rules to find the load balancer IP...${RESET_FORMAT}"
gcloud compute forwarding-rules list --global

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Fetching the external IP address of the 'fancy-http-rule' (Load Balancer IP)...${RESET_FORMAT}"
export EXTERNAL_IP_FANCY=$(gcloud compute forwarding-rules describe fancy-http-rule --global --format='get(IPAddress)')

echo "${CYAN_TEXT}${BOLD_TEXT}📝 Updating the '.env' file for React app to use the Load Balancer IP...${RESET_FORMAT}"
cat > .env <<EOF
REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_BACKEND:8081/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_BACKEND:8082/api/products

REACT_APP_ORDERS_URL=http://$EXTERNAL_IP_FANCY/api/orders
REACT_APP_PRODUCTS_URL=http://$EXTERNAL_IP_FANCY/api/products
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}🏠 Returning to the home directory...${RESET_FORMAT}"
cd ~

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Changing directory to '~/monolith-to-microservices/react-app' for rebuild...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
echo "${CYAN_TEXT}${BOLD_TEXT}📦 Installing dependencies and rebuilding the React application with new .env settings...${RESET_FORMAT}"
npm install && npm run-script build

echo "${CYAN_TEXT}${BOLD_TEXT}🏠 Returning to the home directory...${RESET_FORMAT}"
cd ~
echo "${CYAN_TEXT}${BOLD_TEXT}🧹 Cleaning up 'node_modules' directories before final source code upload...${RESET_FORMAT}"
rm -rf monolith-to-microservices/*/node_modules
echo "${CYAN_TEXT}${BOLD_TEXT}📤 Uploading the final 'monolith-to-microservices' source (with updated React app) to GCS...${RESET_FORMAT}"
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

echo "${CYAN_TEXT}${BOLD_TEXT}🔄 Performing a rolling replacement of instances in 'fancy-fe-mig' to apply updates...${RESET_FORMAT}"
gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
    --zone=$ZONE \
    --max-unavailable 100%

echo "${CYAN_TEXT}${BOLD_TEXT}⚖️  Configuring autoscaling for 'fancy-fe-mig' based on load balancing utilization...${RESET_FORMAT}"
gcloud compute instance-groups managed set-autoscaling \
  fancy-fe-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

echo "${CYAN_TEXT}${BOLD_TEXT}⚖️  Configuring autoscaling for 'fancy-be-mig' based on load balancing utilization...${RESET_FORMAT}"
gcloud compute instance-groups managed set-autoscaling \
  fancy-be-mig \
  --zone=$ZONE \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

echo "${CYAN_TEXT}${BOLD_TEXT}⚡ Enabling CDN for the 'fancy-fe-frontend' backend service...${RESET_FORMAT}"
gcloud compute backend-services update fancy-fe-frontend \
    --enable-cdn --global

echo "${CYAN_TEXT}${BOLD_TEXT}🔧 Changing the machine type of the 'frontend' instance to 'e2-small'...${RESET_FORMAT}"
gcloud compute instances set-machine-type frontend \
  --zone=$ZONE \
  --machine-type e2-small

echo "${CYAN_TEXT}${BOLD_TEXT}📄 Creating a new instance template 'fancy-fe-new' from the modified 'frontend' instance...${RESET_FORMAT}"
gcloud compute instance-templates create fancy-fe-new \
    --region=$REGION \
    --source-instance=frontend \
    --source-instance-zone=$ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}🔄 Starting a rolling update for 'fancy-fe-mig' to use the new 'fancy-fe-new' template...${RESET_FORMAT}"
gcloud compute instance-groups managed rolling-action start-update fancy-fe-mig \
  --zone=$ZONE \
  --version template=fancy-fe-new

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Changing directory to '~/monolith-to-microservices/react-app/src/pages/Home'...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app/src/pages/Home
echo "${CYAN_TEXT}${BOLD_TEXT}🔄 Renaming 'index.js.new' to 'index.js' to apply UI changes...${RESET_FORMAT}"
mv index.js.new index.js

echo "${CYAN_TEXT}${BOLD_TEXT}📄 Displaying the content of the updated 'index.js' for verification...${RESET_FORMAT}"
cat ~/monolith-to-microservices/react-app/src/pages/Home/index.js

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Changing directory to '~/monolith-to-microservices/react-app' for final build...${RESET_FORMAT}"
cd ~/monolith-to-microservices/react-app
echo "${CYAN_TEXT}${BOLD_TEXT}📦 Installing dependencies and rebuilding the React app with UI changes...${RESET_FORMAT}"
npm install && npm run-script build

echo "${CYAN_TEXT}${BOLD_TEXT}🏠 Returning to the home directory...${RESET_FORMAT}"
cd ~
echo "${CYAN_TEXT}${BOLD_TEXT}🧹 Final cleanup of 'node_modules' directories...${RESET_FORMAT}"
rm -rf monolith-to-microservices/*/node_modules
echo "${CYAN_TEXT}${BOLD_TEXT}📤 Uploading the very final 'monolith-to-microservices' source to GCS...${RESET_FORMAT}"
gsutil -m cp -r monolith-to-microservices gs://fancy-store-$DEVSHELL_PROJECT_ID/

echo "${CYAN_TEXT}${BOLD_TEXT}🔄 Performing a final rolling replacement of instances in 'fancy-fe-mig' to apply all changes...${RESET_FORMAT}"
gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
  --zone=$ZONE \
  --max-unavailable=100%

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
