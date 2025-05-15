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

echo "${YELLOW_TEXT}${BOLD_TEXT}👉 Please enter the Region.${RESET_FORMAT}"
read -p "${MAGENTA_TEXT}REGION: ${RESET_FORMAT}" REGION
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🛠️  Setting up the project workspace...${RESET_FORMAT}"
mkdir ~/hello-go && cd ~/hello-go

echo "${BLUE_TEXT}${BOLD_TEXT}📝 Creating the Go source file for our HTTP function...${RESET_FORMAT}"
cat > main.go <<EOF_END
package function

import (
    "fmt"
    "net/http"
)

// HelloGo is the entry point
func HelloGo(w http.ResponseWriter, r *http.Request) {
    fmt.Fprint(w, "Hello from Cloud Functions (Go 2nd Gen)!")
}
EOF_END

echo "${BLUE_TEXT}${BOLD_TEXT}📦 Initializing the Go module...${RESET_FORMAT}"
cat > go.mod <<EOF_END
module example.com/hellogo

go 1.21
EOF_END

echo "${MAGENTA_TEXT}${BOLD_TEXT}🚀 Deploying the HTTP-triggered Go Cloud Function...${RESET_FORMAT}"
gcloud functions deploy cf-go \
  --gen2 \
  --runtime=go121 \
  --region=$REGION \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point=HelloGo \
  --source=. \
  --min-instances=5


echo "${MAGENTA_TEXT}${BOLD_TEXT}📨 Deploying the Pub/Sub-triggered Go Cloud Function...${RESET_FORMAT}"
echo "n" | gcloud functions deploy cf-pubsub \
  --gen2 \
  --region=$REGION \
  --runtime=go121 \
  --trigger-topic=cf-pubsub \
  --min-instances=5 \
  --entry-point=helloWorld \
  --source=. \
  --allow-unauthenticated

echo
echo "${CYAN_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}🔴          IGNORE ERRORS IF ANY          🔴 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE WITH US! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
