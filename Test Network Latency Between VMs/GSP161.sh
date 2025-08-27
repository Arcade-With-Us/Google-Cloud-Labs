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

# Step 1: Get default zone & region
echo "${BOLD}${BLUE}Getting default zone & region${RESET}"
export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone $ZONE_1
gcloud config set compute/region $REGION_1

get_and_export_zones() {
  echo
  echo "${YELLOW}${BOLD}Please enter values for the following:${RESET}"

  echo
  read -p "$(echo -e "${CYAN}${BOLD}Enter ZONE_2 (e.g., us-central1-a): ${RESET}")" ZONE_2
  export ZONE_2=$ZONE_2
  REGION_2=$(echo "$ZONE_2" | sed 's/-[a-z]$//')
  export REGION_2=$REGION_2

  echo

  read -p "$(echo -e "${CYAN}${BOLD}Enter ZONE_3 (e.g., us-central1-b): ${RESET}")" ZONE_3
  export ZONE_3=$ZONE_3
  REGION_3=$(echo "$ZONE_3" | sed 's/-[a-z]$//')
  export REGION_3=$REGION_3
  echo
}

get_and_export_zones

# Step 2: Create VM us-test-01
echo "${BOLD}${BLUE}Creating instance us-test-01${RESET}"
gcloud compute instances create us-test-01 \
--subnet subnet-$REGION_1 \
--zone $ZONE_1 \
--machine-type e2-standard-2 \
--tags ssh,http,rules

# Step 3: Create VM us-test-02
echo "${BOLD}${GREEN}Creating instance us-test-02${RESET}"
gcloud compute instances create us-test-02 \
--subnet subnet-$REGION_2 \
--zone $ZONE_2 \
--machine-type e2-standard-2 \
--tags ssh,http,rules

# Step 4: Create VM us-test-03
echo "${BOLD}${CYAN}Creating instance us-test-03${RESET}"
gcloud compute instances create us-test-03 \
--subnet subnet-$REGION_3 \
--zone $ZONE_3 \
--machine-type e2-standard-2 \
--tags ssh,http,rules

# Step 5: Create VM us-test-04
echo "${BOLD}${YELLOW}Creating instance us-test-04${RESET}"
gcloud compute instances create us-test-04 \
--subnet subnet-$REGION_1 \
--zone $ZONE_1 \
--tags ssh,http

# Step 6: Install tools on us-test-01
echo "${BOLD}${RED}Installing tools on us-test-01${RESET}"
cat > prepare_disk.sh <<'EOF_END'
sudo apt-get update
sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege

timeout 10 traceroute -m 8 www.icann.org
EOF_END

gcloud compute scp prepare_disk.sh us-test-01:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet
gcloud compute ssh us-test-01 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet --command="bash /tmp/prepare_disk.sh"

# Step 7: Install tools on us-test-02
echo "${BOLD}${BLUE}Installing tools on us-test-02${RESET}"
cat > prepare_disk.sh <<'EOF_END'
sudo apt-get update
sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege

timeout 10 traceroute -m 8 www.icann.org
EOF_END

gcloud compute scp prepare_disk.sh us-test-02:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet
gcloud compute ssh us-test-02 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet --command="bash /tmp/prepare_disk.sh"

# Step 8: Start iperf server on us-test-01
echo "${BOLD}${GREEN}Starting iperf server on us-test-01${RESET}"
cat > prepare_disk.sh <<'EOF_END'
nohup iperf -s > iperf-server.log 2>&1 &
EOF_END

gcloud compute scp prepare_disk.sh us-test-01:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet
gcloud compute ssh us-test-01 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet --command="bash /tmp/prepare_disk.sh"

# Step 9: Run iperf client from us-test-02 to us-test-01
echo "${BOLD}${CYAN}Running iperf client on us-test-02${RESET}"
cat > prepare_disk.sh <<EOF_END
sudo apt-get update

sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege

iperf -c us-test-01.$ZONE_1 #run in client mode
EOF_END

gcloud compute scp prepare_disk.sh us-test-02:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet
gcloud compute ssh us-test-02 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet --command="bash /tmp/prepare_disk.sh"

# Step 10: Install tools on us-test-04
echo "${BOLD}${MAGENTA}Installing tools on us-test-04${RESET}"
cat > prepare_disk.sh <<'EOF_END'
sudo apt-get update

sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege
EOF_END

gcloud compute scp prepare_disk.sh us-test-04:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet
gcloud compute ssh us-test-04 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet --command="bash /tmp/prepare_disk.sh"

echo

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
