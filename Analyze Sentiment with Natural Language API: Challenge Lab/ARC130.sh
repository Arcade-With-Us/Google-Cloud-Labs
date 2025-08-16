#!/bin/bash

# Bright Foreground Colors
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

clear

echo "${BLUE_TEXT}${BOLD_TEXT}=================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                Starting Initialization          ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=================================================${RESET_FORMAT}"
echo
# Start of the script
echo "${CYAN_TEXT}${BOLD_TEXT}Starting Natural Language API analysis...${RESET_FORMAT}"

# Create English text analysis request
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating English text analysis request...${RESET_FORMAT}"
cat > analyze-request.json <<EOF_END
{
  "document":{
    "type":"PLAIN_TEXT",
    "content": "Google, headquartered in Mountain View, unveiled the new Android phone at the Consumer Electronic Show. Sundar Pichai said in his keynote that users love their new Android phones."
  },
  "encodingType": "UTF8"
}
EOF_END

# Execute English text analysis
echo "${MAGENTA_TEXT}${BOLD_TEXT}Analyzing English text...${RESET_FORMAT}"
curl -s -H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://language.googleapis.com/v1/documents:analyzeSyntax" \
-d @analyze-request.json > analyze-response.txt

# Create multilingual text analysis request
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating multilingual text analysis request...${RESET_FORMAT}"
cat > multi-nl-request.json <<EOF_END
{
  "document":{
    "type":"PLAIN_TEXT",
    "content":"Le bureau japonais de Google est situé à Roppongi Hills, Tokyo."
  }
}
EOF_END

# Execute multilingual text analysis
echo "${MAGENTA_TEXT}${BOLD_TEXT}Analyzing multilingual text...${RESET_FORMAT}"
curl -s -H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://language.googleapis.com/v1/documents:analyzeEntities" \
-d @multi-nl-request.json > multi-response.txt

# Completion message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}       Lab COMPLETED SUCCESSFULLY      ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Results saved to:${RESET_FORMAT}"
echo "- analyze-response.txt (English syntax analysis)"
echo "- multi-response.txt (Multilingual entity analysis)"
echo

echo
# Completion message
echo -e "${GREEN_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
