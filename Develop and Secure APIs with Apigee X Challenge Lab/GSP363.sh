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

echo -e "${C5}Initializing environment...${NC}"
sleep 1


# ==============================================================================
# PROJECT DETECTION
# ==============================================================================

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
    echo -e "${C6}"
    echo "ERROR: No active Google Cloud project found."
    echo -e "${NC}"
    exit 1
fi

echo
echo -e "${C2}✔ Project detected:${NC} ${C5}${PROJECT_ID}${NC}"
echo


# ==============================================================================
# SERVICE ACCOUNT + IAM
# ==============================================================================

echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 01  ${C1}▸${NC} API & IAM CONFIGURATION"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Enabling Translation API...${NC}"

gcloud services enable translate.googleapis.com --quiet

echo -e "${C2}✔ Translation API enabled${NC}"

echo
echo -e "${C3}→ Creating Apigee service account...${NC}"

gcloud iam service-accounts create apigee-proxy \
    --display-name="Apigee Proxy Service Access" \
    --quiet 2>/dev/null || true

echo -e "${C2}✔ Service account ready${NC}"

echo
echo -e "${C3}→ Assigning Logging Writer role...${NC}"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:apigee-proxy@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter" \
    --quiet

echo -e "${C2}✔ IAM role configured${NC}"


# ==============================================================================
# IAM PROPAGATION
# ==============================================================================

echo
echo -e "${C3}→ Waiting for IAM propagation...${NC}"

for i in {30..1}; do
    printf "\r   Remaining: %02d seconds " "$i"
    sleep 1
done

echo
echo -e "${C2}✔ IAM propagation completed${NC}"


# ==============================================================================
# APIGEE INSTANCE
# ==============================================================================

INSTANCE_NAME="eval-instance"
ENV_NAME="eval"

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 02  ${C1}▸${NC} APIGEE RUNTIME"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Waiting for Apigee instance...${NC}"
echo -e "${C3}  This process may take several minutes.${NC}"
echo

PREV_INSTANCE_STATE=""

while true; do

    ACCESS_TOKEN=$(gcloud auth print-access-token)

    INSTANCE_STATE=$(curl -s \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/instances/${INSTANCE_NAME}" \
        | jq -r '.state // empty')

    if [[ "$INSTANCE_STATE" != "$PREV_INSTANCE_STATE" ]]; then
        echo
        echo -e "   ${C3}Instance state:${NC} ${C5}${INSTANCE_STATE:-UNKNOWN}${NC}"
        PREV_INSTANCE_STATE="$INSTANCE_STATE"
    fi

    if [[ "$INSTANCE_STATE" == "ACTIVE" ]]; then
        break
    fi

    printf "."
    sleep 15
done

echo
echo -e "${C2}✔ Apigee instance is ACTIVE${NC}"


# ==============================================================================
# ENVIRONMENT ATTACHMENT
# ==============================================================================

echo
echo -e "${C3}→ Checking environment attachment...${NC}"

while true; do

    ACCESS_TOKEN=$(gcloud auth print-access-token)

    ATTACHMENT_DONE=$(curl -s \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/instances/${INSTANCE_NAME}/attachments" \
        | jq -r \
        "select(.attachments != null) |
         .attachments[] |
         select(.environment == \"${ENV_NAME}\") |
         .environment" \
        --join-output)

    if [[ "$ATTACHMENT_DONE" == "$ENV_NAME" ]]; then
        break
    fi

    printf "."
    sleep 15
done

echo
echo -e "${C2}✔ Environment attached successfully${NC}"


# ==============================================================================
# DOWNLOAD PROXY
# ==============================================================================

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 03  ${C1}▸${NC} API PROXY"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Downloading API proxy bundle...${NC}"

curl -L \
    "https://drive.google.com/uc?export=download&id=1IxJMjqAJ-FVKWOdg2HnJ79wY7BBlbjbJ" \
    -o translate-v1.zip \
    --silent \
    --show-error

if [[ ! -f "translate-v1.zip" ]]; then
    echo -e "${C6}✖ Proxy bundle download failed${NC}"
    exit 1
fi

echo -e "${C2}✔ Proxy bundle downloaded${NC}"


# ==============================================================================
# IMPORT PROXY
# ==============================================================================

echo
echo -e "${C3}→ Importing API proxy...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/apis?action=import&name=translate-v1" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @translate-v1.zip

echo
echo -e "${C2}✔ API proxy imported${NC}"


# ==============================================================================
# DEPLOY PROXY
# ==============================================================================

echo
echo -e "${C3}→ Deploying API proxy...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/environments/${ENV_NAME}/apis/translate-v1/revisions/1/deployments?serviceAccount=apigee-proxy@${PROJECT_ID}.iam.gserviceaccount.com" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"

echo
echo -e "${C2}✔ API proxy deployed${NC}"


# ==============================================================================
# API PRODUCT
# ==============================================================================

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 04  ${C1}▸${NC} API PRODUCT"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cat > translate-product.json <<EOF
{
  "name": "translate-product",
  "displayName": "translate-product",
  "approvalType": "auto",
  "attributes": [
    {
      "name": "access",
      "value": "public"
    }
  ],
  "environments": [
    "eval"
  ],
  "operationGroup": {
    "operationConfigs": [
      {
        "apiSource": "translate-v1",
        "operations": [
          {
            "resource": "/",
            "methods": [
              "GET",
              "POST"
            ]
          }
        ],
        "quota": {
          "limit": "10",
          "interval": "1",
          "timeUnit": "minute"
        }
      }
    ],
    "operationConfigType": "proxy"
  }
}
EOF

echo -e "${C3}→ Creating API product...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/apiproducts" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d @translate-product.json

echo
echo -e "${C2}✔ API product created${NC}"


# ==============================================================================
# DEVELOPER
# ==============================================================================

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 05  ${C1}▸${NC} DEVELOPER ACCOUNT"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Creating developer account...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/developers" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "email": "joe@example.com",
      "firstName": "Joe",
      "lastName": "Developer",
      "userName": "joe"
    }'

echo
echo -e "${C2}✔ Developer account configured${NC}"


# ==============================================================================
# DEVELOPER APP
# ==============================================================================

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 06  ${C1}▸${NC} DEVELOPER APPLICATION"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Creating translate-app...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/developers/joe@example.com/apps" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "translate-app",
      "apiProducts": [
        "translate-product"
      ]
    }'

echo
echo -e "${C2}✔ Developer application created${NC}"


# ==============================================================================
# CLEANUP
# ==============================================================================

rm -f translate-v1.zip
rm -f translate-product.json

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab! Keep up the great work!${RESET}"
        "${CYAN}Well done! Your hard work and effort have paid off!${RESET}"
        "${YELLOW}Amazing job! You’ve successfully completed the lab!${RESET}"
        "${BLUE}Outstanding! Your dedication has brought you success!${RESET}"
        "${MAGENTA}Great work! You’re one step closer to mastering this!${RESET}"
        "${RED}Fantastic effort! You’ve earned this achievement!${RESET}"
        "${CYAN}Congratulations! Your persistence has paid off brilliantly!${RESET}"
        "${GREEN}Bravo! You’ve completed the lab with flying colors!${RESET}"
        "${YELLOW}Excellent job! Your commitment is inspiring!${RESET}"
        "${BLUE}You did it! Keep striving for more successes like this!${RESET}"
        "${MAGENTA}Kudos! Your hard work has turned into a great accomplishment!${RESET}"
        "${RED}You’ve smashed it! Completing this lab shows your dedication!${RESET}"
        "${CYAN}Impressive work! You’re making great strides!${RESET}"
        "${GREEN}Well done! This is a big step towards mastering the topic!${RESET}"
        "${YELLOW}You nailed it! Every step you took led you to success!${RESET}"
        "${BLUE}Exceptional work! Keep this momentum going!${RESET}"
        "${MAGENTA}Fantastic! You’ve achieved something great today!${RESET}"
        "${RED}Incredible job! Your determination is truly inspiring!${RESET}"
        "${CYAN}Well deserved! Your effort has truly paid off!${RESET}"
        "${GREEN}You’ve got this! Every step was a success!${RESET}"
        "${YELLOW}Nice work! Your focus and effort are shining through!${RESET}"
        "${BLUE}Superb performance! You’re truly making progress!${RESET}"
        "${MAGENTA}Top-notch! Your skill and dedication are paying off!${RESET}"
        "${RED}Mission accomplished! This success is a reflection of your hard work!${RESET}"
        "${CYAN}You crushed it! Keep pushing towards your goals!${RESET}"
        "${GREEN}You did a great job! Stay motivated and keep learning!${RESET}"
        "${YELLOW}Well executed! You’ve made excellent progress today!${RESET}"
        "${BLUE}Remarkable! You’re on your way to becoming an expert!${RESET}"
        "${MAGENTA}Keep it up! Your persistence is showing impressive results!${RESET}"
        "${RED}This is just the beginning! Your hard work will take you far!${RESET}"
        "${CYAN}Terrific work! Your efforts are paying off in a big way!${RESET}"
        "${GREEN}You’ve made it! This achievement is a testament to your effort!${RESET}"
        "${YELLOW}Excellent execution! You’re well on your way to mastering the subject!${RESET}"
        "${BLUE}Wonderful job! Your hard work has definitely paid off!${RESET}"
        "${MAGENTA}You’re amazing! Keep up the awesome work!${RESET}"
        "${RED}What an achievement! Your perseverance is truly admirable!${RESET}"
        "${CYAN}Incredible effort! This is a huge milestone for you!${RESET}"
        "${GREEN}Awesome! You’ve done something incredible today!${RESET}"
        "${YELLOW}Great job! Keep up the excellent work and aim higher!${RESET}"
        "${BLUE}You’ve succeeded! Your dedication is your superpower!${RESET}"
        "${MAGENTA}Congratulations! Your hard work has brought great results!${RESET}"
        "${RED}Fantastic work! You’ve taken a huge leap forward today!${RESET}"
        "${CYAN}You’re on fire! Keep up the great work!${RESET}"
        "${GREEN}Well deserved! Your efforts have led to success!${RESET}"
        "${YELLOW}Incredible! You’ve achieved something special!${RESET}"
        "${BLUE}Outstanding performance! You’re truly excelling!${RESET}"
        "${MAGENTA}Terrific achievement! Keep building on this success!${RESET}"
        "${RED}Bravo! You’ve completed the lab with excellence!${RESET}"
        "${CYAN}Superb job! You’ve shown remarkable focus and effort!${RESET}"
        "${GREEN}Amazing work! You’re making impressive progress!${RESET}"
        "${YELLOW}You nailed it again! Your consistency is paying off!${RESET}"
        "${BLUE}Incredible dedication! Keep pushing forward!${RESET}"
        "${MAGENTA}Excellent work! Your success today is well earned!${RESET}"
        "${RED}You’ve made it! This is a well-deserved victory!${RESET}"
        "${CYAN}Wonderful job! Your passion and hard work are shining through!${RESET}"
        "${GREEN}You’ve done it! Keep up the hard work and success will follow!${RESET}"
        "${YELLOW}Great execution! You’re truly mastering this!${RESET}"
        "${BLUE}Impressive! This is just the beginning of your journey!${RESET}"
        "${MAGENTA}You’ve achieved something great today! Keep it up!${RESET}"
        "${RED}You’ve made remarkable progress! This is just the start!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

echo -e "\n"  # Adding one blank line

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files

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
