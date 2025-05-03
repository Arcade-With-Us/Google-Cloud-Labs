#!/bin/bash
# Define text formatting variables
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

# Clear the terminal screen for a fresh start
clear

# Display initial header
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

# Prompt user for the GCP region
echo "${YELLOW_TEXT}${BOLD_TEXT}❓ Please enter the GCP region:${RESET_FORMAT}"
read REGION
export REGION
echo "${GREEN_TEXT}✅ Using region: ${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo

# Instruction before enabling IAP API
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Enabling the Identity-Aware Proxy (IAP) API...${RESET_FORMAT}"
gcloud services enable iap.googleapis.com
echo "${GREEN_TEXT}✅ IAP API enabled.${RESET_FORMAT}"
echo

# Instruction before countdown
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for 15 seconds to allow services to propagate...${RESET_FORMAT}"
for i in $(seq 15 -1 1); do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT}$i seconds remaining...${RESET_FORMAT}\r"
  sleep 1
done
echo -ne "\n" 
echo "${GREEN_TEXT}✅ Wait complete.${RESET_FORMAT}"
echo

# Instruction before cloning repository
echo "${BLUE_TEXT}${BOLD_TEXT}📥 Cloning the required GitHub repository...${RESET_FORMAT}"
git clone https://github.com/googlecodelabs/user-authentication-with-iap.git
echo "${GREEN_TEXT}✅ Repository cloned.${RESET_FORMAT}"
echo

# Instruction before changing directory
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating into the cloned repository directory...${RESET_FORMAT}"
cd user-authentication-with-iap
echo "${GREEN_TEXT}✅ Changed directory to 'user-authentication-with-iap'.${RESET_FORMAT}"
echo

# Instruction before changing directory to 1-HelloWorld
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating into the '1-HelloWorld' directory...${RESET_FORMAT}"
cd 1-HelloWorld
echo "${GREEN_TEXT}✅ Changed directory to '1-HelloWorld'.${RESET_FORMAT}"
echo

# Instruction before displaying main.py
echo "${BLUE_TEXT}${BOLD_TEXT}📄 Displaying the content of 'main.py'...${RESET_FORMAT}"
cat main.py
echo "${GREEN_TEXT}✅ 'main.py' content displayed.${RESET_FORMAT}"
echo

# Instruction before creating App Engine app
echo "${BLUE_TEXT}${BOLD_TEXT}🏗️ Creating the Google App Engine application in region ${BOLD_TEXT}$REGION...${RESET_FORMAT}"
gcloud app create --project=$(gcloud config get-value project) --region=$REGION
echo "${GREEN_TEXT}✅ App Engine application creation initiated.${RESET_FORMAT}"
echo

# Instruction before creating app.yaml for HelloWorld
echo "${BLUE_TEXT}${BOLD_TEXT}📝 Creating 'app.yaml' configuration file for the HelloWorld app...${RESET_FORMAT}"
cat > app.yaml <<'EOF_END'
runtime: python39
EOF_END
echo "${GREEN_TEXT}✅ 'app.yaml' for HelloWorld created.${RESET_FORMAT}"
echo

# Instruction before deploying HelloWorld app
echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Deploying the HelloWorld application to App Engine...${RESET_FORMAT}"
yes | gcloud app deploy
echo "${GREEN_TEXT}✅ HelloWorld application deployment initiated.${RESET_FORMAT}"
echo

# Instruction before changing directory to 2-HelloUser
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Navigating back to the parent and into the '2-HelloUser' directory...${RESET_FORMAT}"
cd ~/user-authentication-with-iap/2-HelloUser
echo "${GREEN_TEXT}✅ Changed directory to '2-HelloUser'.${RESET_FORMAT}"
echo

# Instruction before creating app.yaml for HelloUser
echo "${BLUE_TEXT}${BOLD_TEXT}📝 Creating 'app.yaml' configuration file for the HelloUser app...${RESET_FORMAT}"
cat > app.yaml <<'EOF_END'
runtime: python39
EOF_END
echo "${GREEN_TEXT}✅ 'app.yaml' for HelloUser created.${RESET_FORMAT}"
echo

# Instruction before deploying HelloUser app
echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Deploying the HelloUser application to App Engine...${RESET_FORMAT}"
yes | gcloud app deploy
echo "${GREEN_TEXT}✅ HelloUser application deployment initiated.${RESET_FORMAT}"
echo

# Instruction before getting user email
echo "${BLUE_TEXT}${BOLD_TEXT}📧 Retrieving the current logged-in gcloud user email...${RESET_FORMAT}"
EMAIL="$(gcloud config get-value core/account)"
echo "${GREEN_TEXT}✅ Email retrieved: ${BOLD_TEXT}$EMAIL${RESET_FORMAT}"
echo

# Instruction before getting app URL
echo "${BLUE_TEXT}${BOLD_TEXT}🔗 Fetching the URL of the deployed application...${RESET_FORMAT}"
LINK=$(gcloud app browse)
echo "${GREEN_TEXT}✅ Application URL: ${BOLD_TEXT}$LINK${RESET_FORMAT}"
echo

# Instruction before extracting domain
echo "${BLUE_TEXT}${BOLD_TEXT}✂️ Extracting the domain name from the URL...${RESET_FORMAT}"
LINKU=${LINK#https://}
echo "${GREEN_TEXT}✅ Domain extracted: ${BOLD_TEXT}$LINKU${RESET_FORMAT}"
echo

# Instruction before creating details.json
echo "${BLUE_TEXT}${BOLD_TEXT}💾 Creating 'details.json' with application information...${RESET_FORMAT}"
cat > details.json << EOF
{
  "App name": "IAP Example",
  "Authorized domains": "$LINKU",
  "Developer contact email": "$EMAIL"
}
EOF
echo "${GREEN_TEXT}✅ 'details.json' created.${RESET_FORMAT}"
echo

# Instruction before displaying details.json
echo "${BLUE_TEXT}${BOLD_TEXT}📄 Displaying the content of 'details.json'...${RESET_FORMAT}"
cat details.json
echo "${GREEN_TEXT}✅ 'details.json' content displayed.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)

echo
echo "${BLUE_TEXT}${BOLD_TEXT} OPEN OAuth CONSENT SCREEN FROM HERE: ${UNDERLINE_TEXT} https://console.cloud.google.com/auth/overview?project=$PROJECT_ID ${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT} OPEN IDENTITY-AWARE PROXY FROM HERE: ${UNDERLINE_TEXT} https://console.cloud.google.com/security/iap?project=$PROJECT_ID ${RESET_FORMAT}"


# Final message
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 If you found this helpful, please subscribe to Arcade With Us! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
