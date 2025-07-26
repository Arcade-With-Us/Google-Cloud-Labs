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

export REGION=${ZONE::-2}
gcloud compute networks create ca-lab-vpc --subnet-mode custom

gcloud compute networks subnets create ca-lab-subnet \
        --network ca-lab-vpc --range 10.0.0.0/24 --region $REGION

gcloud compute firewall-rules create allow-js-site --allow tcp:3000 --network ca-lab-vpc

gcloud compute firewall-rules create allow-health-check \
    --network=ca-lab-vpc \
    --action=allow \
    --direction=ingress \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=allow-healthcheck \
    --rules=tcp

gcloud compute instances create-with-container owasp-juice-shop-app --container-image bkimminich/juice-shop \
     --network ca-lab-vpc \
     --subnet ca-lab-subnet \
     --private-network-ip=10.0.0.3 \
     --machine-type n1-standard-2 \
     --zone $ZONE \
     --tags allow-healthcheck

gcloud compute instance-groups unmanaged create juice-shop-group \
    --zone=$ZONE

gcloud compute instance-groups unmanaged add-instances juice-shop-group \
    --zone=$ZONE \
    --instances=owasp-juice-shop-app

gcloud compute instance-groups unmanaged set-named-ports \
juice-shop-group \
   --named-ports=http:3000 \
   --zone=$ZONE

gcloud compute health-checks create tcp tcp-port-3000 \
        --port 3000

gcloud compute backend-services create juice-shop-backend \
        --protocol HTTP \
        --port-name http \
        --health-checks tcp-port-3000 \
        --enable-logging \
        --global

 gcloud compute backend-services add-backend juice-shop-backend \
        --instance-group=juice-shop-group \
        --instance-group-zone=$ZONE \
        --global

gcloud compute url-maps create juice-shop-loadbalancer \
        --default-service juice-shop-backend

gcloud compute target-http-proxies create juice-shop-proxy \
        --url-map juice-shop-loadbalancer

gcloud compute forwarding-rules create juice-shop-rule \
        --global \
        --target-http-proxy=juice-shop-proxy \
        --ports=80

PUBLIC_SVC_IP="$(gcloud compute forwarding-rules describe juice-shop-rule  --global --format="value(IPAddress)")"
echo $PUBLIC_SVC_IP

while true; do
    cloud=$(curl -Ii http://$PUBLIC_SVC_IP)
    if [[ "$cloud" == *"HTTP/1.1 200 OK"* ]]; then
        echo "Server is serving requests."
        break  
    else
        echo "Subscribe to Arcade Helper"
        sleep 7
    fi
done
gcloud compute security-policies list-preconfigured-expression-sets

gcloud compute security-policies create block-with-modsec-crs \
    --description "Block with OWASP ModSecurity CRS"

gcloud compute security-policies rules update 2147483647 \
    --security-policy block-with-modsec-crs \
    --action "deny-403"
MY_IP=$(curl ifconfig.me)

gcloud compute security-policies rules create 10000 \
    --security-policy block-with-modsec-crs  \
    --description "allow traffic from my IP" \
    --src-ip-ranges "$MY_IP/32" \
    --action "allow"

gcloud compute security-policies rules create 9000 \
    --security-policy block-with-modsec-crs  \
    --description "block local file inclusion" \
     --expression "evaluatePreconfiguredExpr('lfi-stable')" \
    --action deny-403

gcloud compute security-policies rules create 9001 \
    --security-policy block-with-modsec-crs  \
    --description "block rce attacks" \
     --expression "evaluatePreconfiguredExpr('rce-stable')" \
    --action deny-403

gcloud compute security-policies rules create 9002 \
    --security-policy block-with-modsec-crs  \
    --description "block scanners" \
     --expression "evaluatePreconfiguredExpr('scannerdetection-stable')" \
    --action deny-403

gcloud compute security-policies rules create 9003 \
    --security-policy block-with-modsec-crs  \
    --description "block protocol attacks" \
     --expression "evaluatePreconfiguredExpr('protocolattack-stable')" \
    --action deny-403

gcloud compute security-policies rules create 9004 \
    --security-policy block-with-modsec-crs \
    --description "block session fixation attacks" \
     --expression "evaluatePreconfiguredExpr('sessionfixation-stable')" \
    --action deny-403

gcloud compute backend-services update juice-shop-backend \
    --security-policy block-with-modsec-crs \
    --global

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
