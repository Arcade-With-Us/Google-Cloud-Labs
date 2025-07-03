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

# Function to display a progress bar for sleep
function show_progress {
  local duration=$1
  local message=${2:-"⏳ Waiting"}
  local width=40
  local delay=0.1
  local spinstr='⠏⠧⠹⠼'
  local cur=0
  # Calculate total steps accurately using awk
  local steps=$(awk "BEGIN {print int($duration / $delay)}")
  # Ensure steps is at least 1 to avoid division by zero
  steps=$(( steps > 0 ? steps : 1 ))

  echo -n "${CYAN_TEXT}${BOLD_TEXT}${message}: ${RESET_FORMAT}"
  # Draw the initial bar structure
  printf "["
  printf "%${width}s" "" # Print empty bar background
  printf "] 0%% %c" "${spinstr:0:1}"
  # Move cursor back to the beginning of the progress bar line
  printf "\r"

  # Start the progress loop
  echo -n "${CYAN_TEXT}${BOLD_TEXT}${message}: ${RESET_FORMAT}["
  while [ $cur -lt $steps ]; do
    # Calculate current progress width
    local current_width=$(awk "BEGIN {print int($cur * $width / $steps)}")
    # Calculate percentage
    local percent=$(awk "BEGIN {print int($cur * 100 / $steps)}")
    # Get the spinner character
    local spinchar=${spinstr:$(($cur % ${#spinstr})):1}

    # Print the filled part of the bar
    printf "%${current_width}s" '' | tr ' ' '█'
    # Print the empty part of the bar
    printf "%-$((width - current_width))s" ''
    # Print the closing bracket, percentage, and spinner
    printf "] %d%% %c" $percent $spinchar
    # Move cursor back to the beginning of the line for the next update
    printf "\r"
    # Print the bar prefix again for the next iteration (overwrites previous percentage/spinner)
    echo -n "${CYAN_TEXT}${BOLD_TEXT}${message}: ${RESET_FORMAT}["


    sleep $delay
    cur=$((cur + 1))
  done

  # Print the final completed bar
  printf "%${width}s" '' | tr ' ' '█'
  printf "] 100%% ✅\n"
  echo "${GREEN_TEXT}${BOLD_TEXT}Completed.${RESET_FORMAT}"
}


clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

# Step 1: Display contents of installhugo.sh
echo "${GREEN_TEXT}${BOLD_TEXT}📄 Step 1: Displaying the content of the Hugo installation script...${RESET_FORMAT}"
cat /tmp/installhugo.sh
echo

# Step 2: Move to home directory and execute installhugo.sh
echo "${YELLOW_TEXT}${BOLD_TEXT}🏠 Step 2: Navigating to your home directory and running the Hugo installer...${RESET_FORMAT}"
cd ~
/tmp/installhugo.sh
echo

# Step 3: Set project environment variables
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Step 3: Configuring essential Google Cloud project environment variables...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${BLUE_TEXT}${BOLD_TEXT}✅ Environment variables set: PROJECT_ID, PROJECT_NUMBER, REGION.${RESET_FORMAT}"
echo

# Step 4: Update and install required packages
echo "${MAGENTA_TEXT}${BOLD_TEXT}📦 Step 4: Updating package lists and installing Git & GitHub CLI...${RESET_FORMAT}"
sudo apt-get update
sudo apt-get install git
sudo apt-get install gh
echo

# Step 5: Install GitHub CLI using webi.sh
echo "${CYAN_TEXT}${BOLD_TEXT}🌐 Step 5: Installing the latest GitHub CLI using the webi.sh installer...${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh
echo

# Step 6: Authenticate GitHub CLI
echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Step 6: Authenticating with GitHub. Please follow the prompts...${RESET_FORMAT}"
gh auth login
echo "${YELLOW_TEXT}${BOLD_TEXT}👤 Verifying GitHub authentication...${RESET_FORMAT}"
gh api user -q ".login"
echo

# Step 7: Configure GitHub user details
echo "${GREEN_TEXT}${BOLD_TEXT}⚙️ Step 7: Setting up your Git configuration with your GitHub username and email...${RESET_FORMAT}"
GITHUB_USERNAME=$(gh api user -q ".login")
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo ${GITHUB_USERNAME}
echo ${USER_EMAIL}

echo

# Step 8: Create and clone Hugo site repository
echo "${YELLOW_TEXT}${BOLD_TEXT}📁 Step 8: Creating a new private GitHub repository named 'my_hugo_site' and cloning it locally...${RESET_FORMAT}"
cd ~
gh repo create  my_hugo_site --private 
gh repo clone  my_hugo_site 
echo

# Step 9: Initialize Hugo site
echo "${BLUE_TEXT}${BOLD_TEXT}✨ Step 9: Initializing a new Hugo site within the cloned repository directory...${RESET_FORMAT}"
cd ~
/tmp/hugo new site my_hugo_site --force
echo

# Step 10: Clone Hugo theme
echo "${MAGENTA_TEXT}${BOLD_TEXT}🎨 Step 10: Adding a cool Hugo theme ('hello-friend-ng') to your site...${RESET_FORMAT}"
cd ~/my_hugo_site
git clone \
  https://github.com/rhazdon/hugo-theme-hello-friend-ng.git themes/hello-friend-ng
echo 'theme = "hello-friend-ng"' >> config.toml
echo

# Step 11: Remove unnecessary Git files from theme (Not needed if using submodules)
echo "${CYAN_TEXT}${BOLD_TEXT}🧹 Step 11: Cleaning up unnecessary Git files from the theme directory...${RESET_FORMAT}"
sudo rm -r themes/hello-friend-ng/.git
sudo rm themes/hello-friend-ng/.gitignore
echo

# Step 12: Start Hugo server in the background
echo "${RED_TEXT}${BOLD_TEXT}🚀 Step 12: Launching the Hugo development server in the background. Access it at port 8080...${RESET_FORMAT}"
nohup /tmp/hugo server -D --bind 0.0.0.0 --port 8080 > hugo.log 2>&1 &
HUGO_PID=$!
echo "${RED_TEXT}${BOLD_TEXT}💡 Hugo server is running in the background with PID: ${HUGO_PID}${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}   To view logs: tail -f hugo.log${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}   To stop it, run: kill ${HUGO_PID}${RESET_FORMAT}"
echo

# Function to prompt user to check their progress
function check_progress_task1 {
    while true; do
        echo
        echo -n "${YELLOW_TEXT}${BOLD_TEXT}🤔 Have you checked your progress for TASK 1? (Y/N): ${RESET_FORMAT}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${GREEN_TEXT}${BOLD_TEXT}👍 Awesome! Moving on to Firebase setup...${RESET_FORMAT}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${RED_TEXT}${BOLD_TEXT}✋ Please check your Hugo site preview (usually via Web Preview on port 8080) and complete Task 1 steps, then enter Y.${RESET_FORMAT}"
        else
            echo
            echo "${MAGENTA_TEXT}${BOLD_TEXT}❓ Invalid input. Please enter Y or N.${RESET_FORMAT}"
        fi
    done
}

echo
echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}     CHECK PROGRESS TILL TASK 1 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
echo

# Call function to check progress before proceeding
check_progress_task1

# Step 13: Install Firebase CLI
echo "${GREEN_TEXT}${BOLD_TEXT}🔥 Step 13: Installing the Firebase Command Line Interface...${RESET_FORMAT}"
curl -sL https://firebase.tools | bash
echo

# Step 14: Initialize Firebase project
echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Step 14: Initializing Firebase within your Hugo project directory. Follow the prompts...${RESET_FORMAT}"
cd ~/my_hugo_site
firebase init
echo

# Step 15: Deploy Hugo site to Firebase
echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Step 15: Building your Hugo site and deploying it to Firebase Hosting...${RESET_FORMAT}"
cd ~/my_hugo_site # Ensure we are in the correct directory
/tmp/hugo && firebase deploy
echo

# Step 16: Configure Git user details for commits (Using generic details for build process)
echo "${MAGENTA_TEXT}${BOLD_TEXT}👤 Step 16: Configuring temporary Git user details for automated commits...${RESET_FORMAT}"
git config --global user.name "hugo"
git config --global user.email "hugo@blogger.com"
echo

# Step 17: Ignore resources directory and push to GitHub
echo "${CYAN_TEXT}${BOLD_TEXT}💾 Step 17: Adding Firebase config and other changes to Git, ignoring the 'resources' directory, and pushing to GitHub...${RESET_FORMAT}"
cd ~/my_hugo_site
echo "resources" >> .gitignore

git add .
git commit -m "Add app to GitHub Repository"
git push -u origin master
echo

# Step 18: Copy cloudbuild.yaml and display its content
echo "${RED_TEXT}${BOLD_TEXT}📄 Step 18: Copying the Cloud Build configuration file (cloudbuild.yaml) into your project and displaying its contents...${RESET_FORMAT}"
cd ~/my_hugo_site
cp /tmp/cloudbuild.yaml .
echo "${RED_TEXT}${BOLD_TEXT}🔍 Contents of cloudbuild.yaml:${RESET_FORMAT}"
cat cloudbuild.yaml
echo

# Step 19: Create Cloud Build GitHub connection
echo "${GREEN_TEXT}${BOLD_TEXT}🔗 Step 19: Creating a connection between Google Cloud Build and GitHub...${RESET_FORMAT}"
gcloud builds connections create github cloud-build-connection --project=$PROJECT_ID  --region=$REGION
echo

# Step 20: Display Cloud Build Repositories Console Link
echo "${BLUE_TEXT}${BOLD_TEXT}🌐 Step 20: Please open the following link in your browser to authorize the GitHub App for Cloud Build:${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/cloud-build/repositories/2nd-gen?project=$PROJECT_ID${RESET_FORMAT}"
echo

# Function to prompt user to check their progress
function check_progress_github_app {
    while true; do
        echo
        echo -n "${YELLOW_TEXT}${BOLD_TEXT}🤔 Have you installed and authorized the Cloud Build GitHub App for your repository? (Y/N): ${RESET_FORMAT}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${GREEN_TEXT}${BOLD_TEXT}✅ Great! Proceeding with repository connection...${RESET_FORMAT}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${RED_TEXT}${BOLD_TEXT}✋ Please complete the GitHub App installation/authorization using the link above, then enter Y.${RESET_FORMAT}"
        else
            echo
            echo "${MAGENTA_TEXT}${BOLD_TEXT}❓ Invalid input. Please enter Y or N.${RESET_FORMAT}"
        fi
    done
}

echo
echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}       NOW FOLLOW VIDEO STEPS ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
echo

# Call function to check progress before proceeding
check_progress_github_app

# Step 21: Describe Cloud Build connection
echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Step 21: Verifying the status of the Cloud Build GitHub connection...${RESET_FORMAT}"
gcloud builds connections describe cloud-build-connection --region=$REGION
echo

# Step 22: Create a Cloud Build repository connection
echo "${MAGENTA_TEXT}${BOLD_TEXT}🔗 Step 22: Linking your specific GitHub repository ('my_hugo_site') to the Cloud Build connection...${RESET_FORMAT}"
gcloud builds repositories create hugo-website-build-repository \
  --remote-uri="https://github.com/${GITHUB_USERNAME}/my_hugo_site.git" \
  --connection="cloud-build-connection" --region=$REGION
echo

# Step 23: Create Cloud Build trigger
echo "${CYAN_TEXT}${BOLD_TEXT}🚀 Step 23: Creating a Cloud Build trigger to automatically build and deploy your site on pushes to the main branch...${RESET_FORMAT}"
gcloud builds triggers create github --name="commit-to-master-branch1" \
   --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/hugo-website-build-repository \
   --build-config='cloudbuild.yaml' \
   --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
   --region=$REGION \
   --branch-pattern='^master$'
echo

# Step 24: Update the site title in config.toml
echo "${RED_TEXT}${BOLD_TEXT}✏️ Step 24: Making a small change to your site configuration (updating the title)...${RESET_FORMAT}"
cd ~/my_hugo_site
sed -i "s/^title = .*/title = 'Blogging with Hugo and Cloud Build'/" config.toml
echo "${RED_TEXT}${BOLD_TEXT}   Site title updated in config.toml.${RESET_FORMAT}"
echo

# Step 25: Add, commit, and push changes to Git
echo "${GREEN_TEXT}${BOLD_TEXT}💾 Step 25: Committing the title change and pushing it to GitHub to trigger the Cloud Build pipeline...${RESET_FORMAT}"
git add .
git commit -m "I updated the site title"
git push -u origin master
echo "${GREEN_TEXT}${BOLD_TEXT}   Changes pushed! Check Cloud Build history in the GCP console.${RESET_FORMAT}"
echo

# Step 26: Wait for build to likely start and list builds
echo "${YELLOW_TEXT}${BOLD_TEXT}⏱️ Step 26: Waiting a moment for the build to trigger, then listing recent Cloud Builds...${RESET_FORMAT}"
show_progress 15 "Waiting for build to initiate"
gcloud builds list --region=$REGION
echo

# Step 27: Fetch and display logs for the latest build triggered by the last commit
echo "${BLUE_TEXT}${BOLD_TEXT}📜 Step 27: Checking for Cloud Build logs...${RESET_FORMAT}"
# First check if any builds exist
BUILD_COUNT=$(gcloud builds list --region=$REGION --limit=5 | grep -c "SUCCESS\|WORKING\|FAILURE\|QUEUED" || echo "0")

if [ "$BUILD_COUNT" -gt 0 ]; then
  LATEST_BUILD_ID=$(gcloud builds list --limit=1 --format="value(id)" --region=$REGION)
  echo "${BLUE_TEXT}Found build with ID: $LATEST_BUILD_ID${RESET_FORMAT}"
  gcloud builds log "$LATEST_BUILD_ID" --region=$REGION
else
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ No builds found yet. This is normal if the trigger was just created.${RESET_FORMAT}"
  echo "${YELLOW_TEXT}It may take a few minutes for the build to start after pushing changes.${RESET_FORMAT}"
  echo "${BLUE_TEXT}${BOLD_TEXT}You can check builds manually at:${RESET_FORMAT}"
  echo "${WHITE_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID${RESET_FORMAT}"
  echo
  echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}       NOW FOLLOW VIDEO STEPS ${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
  echo
fi
echo

Step 28: Sleep for 15 seconds to allow build logs to update further
echo "${MAGENTA_TEXT}${BOLD_TEXT}⏱️ Step 28: Pausing briefly again to allow build logs to fully populate...${RESET_FORMAT}"
show_progress 15 "Allowing logs to update"
echo
Step 29: Extract and display the Hosting URL from Cloud Build logs (if build found)
echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Step 29: Attempting to extract the Firebase Hosting URL from the build logs...${RESET_FORMAT}"
gcloud builds log "$(gcloud builds list --format='value(ID)' --filter=$(git rev-parse HEAD) --region=$REGION)" --region=$REGION | grep "Hosting URL"
echo
echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀  LAB COMPLETED SUCCESSFULLY  🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the setup? Consider subscribing to Arcade With Us! 👇${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
