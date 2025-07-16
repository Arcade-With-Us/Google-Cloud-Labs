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

# Header with branding
clear
echo -e "${BOX_TOP}"
echo -e "${BLUE}║   🚀 Cloud API Key & NLP Analysis Setup   ║${NC}"
echo -e "${BOX_BOT}"
echo -e "${CYAN}📺 YouTube: ${WHITE}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${NC}"
echo -e "${CYAN}⭐ Subscribe for more Cloud tutorials! ⭐${NC}"
echo

# Step 1: Authentication Check
echo -e "${YELLOW}🔐 Step 1: Verifying Authentication${NC}"
gcloud auth list
echo

# Step 2: Enable API Keys Service
echo -e "${YELLOW}⚙️ Step 2: Enabling API Keys Service${NC}"
gcloud services enable apikeys.googleapis.com
echo

# Step 3: Get Instance Zone
echo -e "${YELLOW}🌍 Step 3: Configuring Instance Zone${NC}"
export ZONE=$(gcloud compute instances list --filter="name=('linux-instance')" --format="value(zone)")
echo -e "${GREEN}Instance Zone: ${WHITE}$ZONE${NC}"
echo

# Step 4: Create API Key
echo -e "${YELLOW}🔑 Step 4: Creating API Key${NC}"
gcloud alpha services api-keys create --display-name="nlp-analysis-key"
echo -e "${GREEN}✅ API Key created successfully${NC}"
echo

# Get Key Information
echo -e "${YELLOW}📋 Step 5: Retrieving Key Information${NC}"
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter="displayName=nlp-analysis-key")
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
echo -e "${GREEN}API Key ready for use${NC}"
echo

# Step 6: Prepare Analysis Script
echo -e "${YELLOW}📝 Step 6: Preparing NLP Analysis Script${NC}"
cat > nlp_analysis.sh <<'EOL'
#!/bin/bash

# Retrieve API Key
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter="displayName=nlp-analysis-key")
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

echo -e "\n${GREEN}ℹ️ Using API Key: ${WHITE}$API_KEY${NC}"

# Create NLP Request
cat > request.json <<EOF
{
  "document":{
    "type":"PLAIN_TEXT",
    "content":"Joanne Rowling, who writes under the pen names J. K. Rowling and Robert Galbraith, is a British novelist and screenwriter who wrote the Harry Potter fantasy series."
  },
  "encodingType":"UTF8"
}
EOF

echo -e "${YELLOW}📄 Sample Text Prepared for Analysis${NC}"

# Make API Request
echo -e "${YELLOW}🔍 Analyzing Text with Natural Language API...${NC}"
curl "https://language.googleapis.com/v1/documents:analyzeEntities?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @request.json > result.json

# Display Results
echo -e "\n${GREEN}📊 Analysis Results:${NC}"
cat result.json
EOL

# Step 7: Transfer Script
echo -e "${YELLOW}📤 Step 7: Transferring Script to Instance${NC}"
gcloud compute scp nlp_analysis.sh linux-instance:/tmp \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --quiet
echo -e "${GREEN}✅ Script transferred successfully${NC}"
echo

# Step 8: Execute Script
echo -e "${YELLOW}🚀 Step 8: Running NLP Analysis${NC}"
gcloud compute ssh linux-instance \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="chmod +x /tmp/nlp_analysis.sh && /tmp/nlp_analysis.sh"


echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
