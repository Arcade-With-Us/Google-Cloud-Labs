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

# Step 1: Set ZONE and REGION variables
echo "${BOLD}${YELLOW}Setting compute zone and region variables...${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Set compute region
echo "${BOLD}${BLUE}Configuring compute region...${RESET}"
gcloud config set compute/region $REGION

# Step 3: Enable Cloud Scheduler API
echo "${BOLD}${MAGENTA}Enabling Cloud Scheduler API...${RESET}"
gcloud services enable cloudscheduler.googleapis.com

# Step 4: Copy required files and navigate to the working directory
echo "${BOLD}${CYAN}Copying required files and changing to the working directory...${RESET}"
gsutil cp -r gs://spls/gsp648 . && cd gsp648

export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
WORKDIR=$(pwd)
cd $WORKDIR/unattached-pd

# Step 5: Modify main.py with project ID
echo "${BOLD}${RED}Updating main.py with the project ID...${RESET}"
sed -i "s/'automating-cost-optimization'/'$(echo $DEVSHELL_PROJECT_ID)'/" main.py

# Step 6: Define orphaned and unused disk names
echo "${BOLD}${GREEN}Setting disk names...${RESET}"
export ORPHANED_DISK=orphaned-disk
export UNUSED_DISK=unused-disk

# Step 7: Create orphaned and unused disks
echo "${BOLD}${YELLOW}Creating orphaned and unused disks...${RESET}"
gcloud compute disks create $ORPHANED_DISK --project=$PROJECT_ID --type=pd-standard --size=500GB --zone=$ZONE

gcloud compute disks create $UNUSED_DISK --project=$PROJECT_ID --type=pd-standard --size=500GB --zone=$ZONE

# Step 8: List all disks
echo "${BOLD}${BLUE}Listing all disks...${RESET}"
gcloud compute disks list

# Step 9: Create an instance and attach the orphaned disk
echo "${BOLD}${MAGENTA}Creating an instance and attaching the orphaned disk...${RESET}"
gcloud compute instances create disk-instance \
--zone=$ZONE \
--machine-type=e2-medium \
--disk=name=$ORPHANED_DISK,device-name=$ORPHANED_DISK,mode=rw,boot=no

# Step 10: Describe the orphaned disk
echo "${BOLD}${CYAN}Describing the orphaned disk...${RESET}"
gcloud compute disks describe $ORPHANED_DISK --zone=$ZONE --format=json | jq

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you checked your progress upto Task 3 ? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please check your progress upto Task 3 and then press Y to continue.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 11: Detach the orphaned disk
echo "${BOLD}${RED}Detaching the orphaned disk...${RESET}"
gcloud compute instances detach-disk disk-instance --device-name=$ORPHANED_DISK --zone=$ZONE

# Step 12: Describe the orphaned disk again
echo "${BOLD}${GREEN}Describing the orphaned disk after detachment...${RESET}"
gcloud compute disks describe $ORPHANED_DISK --zone=$ZONE --format=json | jq

# Step 13: Disable and re-enable Cloud Functions API
echo "${BOLD}${YELLOW}Disabling and re-enabling Cloud Functions API...${RESET}"
gcloud services disable cloudfunctions.googleapis.com

sleep 5

gcloud services enable cloudfunctions.googleapis.com

sleep 30

# Step 14: Add IAM policy binding for Artifact Registry reader role
echo "${BOLD}${BLUE}Adding IAM policy binding for Artifact Registry reader...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:qwiklabs-gcp-01-7864202acea1@appspot.gserviceaccount.com" \
--role="roles/artifactregistry.reader"

# Step 15: Enable Cloud Run API
echo "${BOLD}${MAGENTA}Enabling Cloud Run API...${RESET}"
gcloud services enable run.googleapis.com

sleep 30

# Step 16: Deploy the Cloud Function
echo "${BOLD}${CYAN}Deploying the Cloud Function...${RESET}"
cd ~/gsp648/unattached-pd
gcloud functions deploy delete_unattached_pds --gen2 --trigger-http --runtime=python39 --region $REGION --allow-unauthenticated

# Step 17: Get the Cloud Function URL
echo "${BOLD}${RED}Fetching the Cloud Function URL...${RESET}"
export FUNCTION_URL=$(gcloud functions describe delete_unattached_pds --format=json --region $REGION | jq -r '.url')

# Step 18: Create an App Engine application
echo "${BOLD}${GREEN}Creating an App Engine application...${RESET}"
gcloud app create --region=$REGION

# Step 29: Create a Cloud Scheduler job
echo "${BOLD}${YELLOW}Creating a Cloud Scheduler job...${RESET}"
gcloud scheduler jobs create http unattached-pd-job \
--schedule="* 2 * * *" \
--uri=$FUNCTION_URL \
--location=$REGION

sleep 60

# Step 20: Run the Cloud Scheduler job
echo "${BOLD}${BLUE}Running the Cloud Scheduler job...${RESET}"
gcloud scheduler jobs run unattached-pd-job \
--location=$REGION

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab! Keep up the great work!${RESET}"
        "${CYAN}Well done! Your hard work and effort have paid off!${RESET}"
        "${YELLOW}Amazing job! You've successfully completed the lab!${RESET}"
        "${BLUE}Outstanding! Your dedication has brought you success!${RESET}"
        "${MAGENTA}Great work! You're one step closer to mastering this!${RESET}"
        "${RED}Fantastic effort! You've earned this achievement!${RESET}"
        "${CYAN}Congratulations! Your persistence has paid off brilliantly!${RESET}"
        "${GREEN}Bravo! You've completed the lab with flying colors!${RESET}"
        "${YELLOW}Excellent job! Your commitment is inspiring!${RESET}"
        "${BLUE}You did it! Keep striving for more successes like this!${RESET}"
        "${MAGENTA}Kudos! Your hard work has turned into a great accomplishment!${RESET}"
        "${RED}You've smashed it! Completing this lab shows your dedication!${RESET}"
        "${CYAN}Impressive work! You're making great strides!${RESET}"
        "${GREEN}Well done! This is a big step towards mastering the topic!${RESET}"
        "${YELLOW}You nailed it! Every step you took led you to success!${RESET}"
        "${BLUE}Exceptional work! Keep this momentum going!${RESET}"
        "${MAGENTA}Fantastic! You've achieved something great today!${RESET}"
        "${RED}Incredible job! Your determination is truly inspiring!${RESET}"
        "${CYAN}Well deserved! Your effort has truly paid off!${RESET}"
        "${GREEN}You've got this! Every step was a success!${RESET}"
        "${YELLOW}Nice work! Your focus and effort are shining through!${RESET}"
        "${BLUE}Superb performance! You're truly making progress!${RESET}"
        "${MAGENTA}Top-notch! Your skill and dedication are paying off!${RESET}"
        "${RED}Mission accomplished! This success is a reflection of your hard work!${RESET}"
        "${CYAN}You crushed it! Keep pushing towards your goals!${RESET}"
        "${GREEN}You did a great job! Stay motivated and keep learning!${RESET}"
        "${YELLOW}Well executed! You've made excellent progress today!${RESET}"
        "${BLUE}Remarkable! You're on your way to becoming an expert!${RESET}"
        "${MAGENTA}Keep it up! Your persistence is showing impressive results!${RESET}"
        "${RED}This is just the beginning! Your hard work will take you far!${RESET}"
        "${CYAN}Terrific work! Your efforts are paying off in a big way!${RESET}"
        "${GREEN}You've made it! This achievement is a testament to your effort!${RESET}"
        "${YELLOW}Excellent execution! You're well on your way to mastering the subject!${RESET}"
        "${BLUE}Wonderful job! Your hard work has definitely paid off!${RESET}"
        "${MAGENTA}You're amazing! Keep up the awesome work!${RESET}"
        "${RED}What an achievement! Your perseverance is truly admirable!${RESET}"
        "${CYAN}Incredible effort! This is a huge milestone for you!${RESET}"
        "${GREEN}Awesome! You've done something incredible today!${RESET}"
        "${YELLOW}Great job! Keep up the excellent work and aim higher!${RESET}"
        "${BLUE}You've succeeded! Your dedication is your superpower!${RESET}"
        "${MAGENTA}Congratulations! Your hard work has brought great results!${RESET}"
        "${RED}Fantastic work! You've taken a huge leap forward today!${RESET}"
        "${CYAN}You're on fire! Keep up the great work!${RESET}"
        "${GREEN}Well deserved! Your efforts have led to success!${RESET}"
        "${YELLOW}Incredible! You've achieved something special!${RESET}"
        "${BLUE}Outstanding performance! You're truly excelling!${RESET}"
        "${MAGENTA}Terrific achievement! Keep building on this success!${RESET}"
        "${RED}Bravo! You've completed the lab with excellence!${RESET}"
        "${CYAN}Superb job! You've shown remarkable focus and effort!${RESET}"
        "${GREEN}Amazing work! You're making impressive progress!${RESET}"
        "${YELLOW}You nailed it again! Your consistency is paying off!${RESET}"
        "${BLUE}Incredible dedication! Keep pushing forward!${RESET}"
        "${MAGENTA}Excellent work! Your success today is well earned!${RESET}"
        "${RED}You've made it! This is a well-deserved victory!${RESET}"
        "${CYAN}Wonderful job! Your passion and hard work are shining through!${RESET}"
        "${GREEN}You've done it! Keep up the hard work and success will follow!${RESET}"
        "${YELLOW}Great execution! You're truly mastering this!${RESET}"
        "${BLUE}Impressive! This is just the beginning of your journey!${RESET}"
        "${MAGENTA}You've achieved something great today! Keep it up!${RESET}"
        "${RED}You've made remarkable progress! This is just the start!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Function to display a random thank-you message
function random_thank_you() {
    MESSAGES=(
        "${GREEN}Thanks for your support! You're awesome!${RESET}"
        "${CYAN}Thank you! Your subscription means a lot!${RESET}"
        "${YELLOW}Much appreciated! Keep enjoying the content!${RESET}"
        "${BLUE}Thanks a ton! Your support makes us better!${RESET}"
        "${MAGENTA}Grateful for your support! You're amazing!${RESET}"
        "${RED}Thank you for subscribing! We're thrilled to have you!${RESET}"
        "${CYAN}Thanks for being part of our community! You're valued!${RESET}"
        "${GREEN}You rock! Thanks for subscribing and supporting us!${RESET}"
        "${YELLOW}Thanks for helping us grow! Your support matters!${RESET}"
        "${BLUE}Big thanks to you! Keep enjoying our content!${RESET}"
        "${MAGENTA}Your subscription means the world to us. Thank you!${RESET}"
        "${RED}You're the best! Thanks for supporting our channel!${RESET}"
        "${CYAN}Thank you! Your subscription helps us create more content!${RESET}"
        "${GREEN}We're so grateful for your subscription! Thank you!${RESET}"
        "${YELLOW}Huge thanks! You make a big difference by subscribing!${RESET}"
        "${BLUE}Thanks for joining us! Your support is truly appreciated!${RESET}"
    )
    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Function to display a random question
function random_question() {
    QUESTIONS=(
        "Have you subscribed to Arcade With Us's YouTube channel yet? [Y/N]"
        "Did you hit the subscribe button on Arcade With Us's YouTube channel? [Y/N]"
        "Are you part of Arcade With Us's growing community on YouTube? [Y/N]"
        "Did you join the learning journey by subscribing to Arcade With Us? [Y/N]"
        "Have you clicked the subscribe button for Arcade With Us's tutorials? [Y/N]"
        "Are you a subscriber to Arcade With Us's YouTube channel? [Y/N]"
        "Want to stay updated with Arcade With Us's latest content? Subscribe now! [Y/N]"
        "Ready to dive deeper into cloud computing with Arcade With Us? Subscribe! [Y/N]"
        "Would you like to keep learning with Arcade With Us? Hit subscribe! [Y/N]"
        "Do you enjoy Arcade With Us's content? Subscribe to stay updated! [Y/N]"
        "Do you want to see more labs and tutorials from Arcade With Us? Subscribe to the channel! [Y/N]"
    )
    RANDOM_INDEX=$((RANDOM % ${#QUESTIONS[@]}))
    echo -e "${BOLD}${WHITE}${QUESTIONS[$RANDOM_INDEX]}${RESET}"
}

# Function to display the "Please Subscribe" message with variety
function random_subscribe_message() {
    MESSAGES=(
        "${BOLD}${RED}Please ${GREEN}Subscribe ${YELLOW}to ${BLUE}Arcade ${MAGENTA}With Us ${CYAN}Cloud Tutorial!${RESET}"
        "${BOLD}${CYAN}Don't miss out! Subscribe to ${MAGENTA}Arcade ${GREEN}With Us ${BLUE}Cloud Tutorial!${RESET}"
        "${BOLD}${RED}Hit that subscribe button for more amazing content from ${CYAN}Arcade ${GREEN}With Us ${MAGENTA}Cloud Tutorial!${RESET}"
        "${BOLD}${YELLOW}Join the ${GREEN}Arcade ${CYAN}With Us ${MAGENTA}Cloud Tutorial community! Subscribe now!${RESET}"
        "${BOLD}${BLUE}Want more tutorials? ${MAGENTA}SUBSCRIBE ${YELLOW}to ${CYAN}Arcade ${GREEN}With Us ${BLUE}Cloud Tutorial!${RESET}"
        "${BOLD}${RED}Your subscription helps us bring more tutorials to you! Please ${CYAN}subscribe to ${MAGENTA}Arcade ${GREEN}With Us ${BLUE}Cloud Tutorial!${RESET}"
        "${BOLD}${YELLOW}Subscribe to ${CYAN}Arcade ${MAGENTA}With Us ${GREEN}Cloud Tutorial to stay updated on all our tutorials!${RESET}"
        "${BOLD}${CYAN}Keep learning with us! ${GREEN}Subscribe to ${MAGENTA}Arcade ${YELLOW}With Us ${RED}Cloud Tutorial!${RESET}"
        "${BOLD}${MAGENTA}Support us and get access to exclusive tutorials by subscribing to ${CYAN}Arcade ${GREEN}With Us ${BLUE}Cloud Tutorial!${RESET}"
        "${BOLD}${BLUE}Love the content? Subscribe to ${MAGENTA}Arcade ${CYAN}With Us ${GREEN}Cloud Tutorial!${RESET}"
        "${BOLD}${RED}Help us grow by subscribing to ${CYAN}Arcade ${MAGENTA}With Us ${YELLOW}Cloud Tutorial! Your support is crucial!${RESET}"
        "${BOLD}${GREEN}Don't forget to hit subscribe to stay up to date with ${CYAN}Arcade ${MAGENTA}With Us ${BLUE}Cloud Tutorial!${RESET}"
        "${BOLD}${YELLOW}Want to join the ${BLUE}Arcade ${MAGENTA}With Us ${CYAN}Cloud Tutorial family? Hit subscribe!${RESET}"
        "${BOLD}${MAGENTA}We appreciate your support! Please ${CYAN}subscribe to ${GREEN}Arcade ${RED}With Us ${BLUE}Cloud Tutorial!${RESET}"
        "${BOLD}${CYAN}Your subscription makes a difference! Help us grow by subscribing to ${MAGENTA}Arcade ${YELLOW}With Us ${GREEN}Cloud Tutorial!${RESET}"
        "${BOLD}${RED}Every click counts! Please subscribe to ${BLUE}Arcade ${MAGENTA}With Us ${CYAN}Cloud Tutorial!${RESET}"
    )
    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

# Add a single blank line between congratulatory message and the prompt
echo -e "\n"  # Adding one blank line

# Display a random question
random_question

# Read the user input
read -p "Enter your choice: " CHOICE

echo -e "\n"  # Adding one blank line

# Handle user input
case "${CHOICE^^}" in
    Y)
        random_thank_you
        ;;
    N)
        random_subscribe_message
        echo -e "${BOLD}${CYAN}YouTube Channel: https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET}"
        echo -e "${BOLD}${GREEN}Check out all videos at: https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l/videos${RESET}"
        ;;
    *)
        echo -e "${BOLD}${RED}Invalid choice! Please enter Y or N.${RESET}"
        ;;
esac

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
