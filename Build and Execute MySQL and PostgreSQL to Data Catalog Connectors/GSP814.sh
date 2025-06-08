
#!/bin/bash

# Define color codes for formatting
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

pause_for_check() {
  echo
  echo "${YELLOW_TEXT}${BOLD_TEXT}Please click 'Check my progress' in the lab UI, then press Y to continue...${RESET_FORMAT}"
  read -p "Press Y to continue: " confirm
  while [[ "$confirm" != "Y" && "$confirm" != "y" ]]; do
    read -p "Press Y to continue: " confirm
  done
  echo
}

echo
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}             Starting Initialization          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

echo -n "${YELLOW_TEXT}${BOLD_TEXT}-> Enter the region: ${RESET_FORMAT}"
read REGION
export REGION

echo -n "${YELLOW_TEXT}${BOLD_TEXT}-> Enter the zone (e.g. ${REGION}-a): ${RESET_FORMAT}"
read ZONE
export ZONE

echo -n "${YELLOW_TEXT}${BOLD_TEXT}-> Enter your Project ID: ${RESET_FORMAT}"
read PROJECT_ID
export PROJECT_ID

echo "${MAGENTA_TEXT}${BOLD_TEXT}.. Enabling the Data Catalog API...${RESET_FORMAT}"
gcloud services enable datacatalog.googleapis.com --project=$PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 1 Completed: Enable the Data Catalog API${RESET_FORMAT}"
pause_for_check

# PostgreSQL Setup
echo "${MAGENTA_TEXT}${BOLD_TEXT}.. Setting up PostgreSQL Connector...${RESET_FORMAT}"
cd ~
gsutil cp gs://spls/gsp814/cloudsql-postgresql-tooling.zip .
unzip -o cloudsql-postgresql-tooling.zip
cd cloudsql-postgresql-tooling/infrastructure/terraform
sed -i "s/us-central1/$REGION/g" variables.tf
sed -i "s/$REGION-a/$ZONE/g" variables.tf
cd ~/cloudsql-postgresql-tooling
bash init-db.sh

echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 2 Completed: Create the PostgreSQL Database${RESET_FORMAT}"
pause_for_check

gcloud iam service-accounts create postgresql2dc-credentials \
  --display-name  "Service Account for PostgreSQL to Data Catalog connector" \
  --project $PROJECT_ID

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for service account to become available...${RESET_FORMAT}"
sleep 10

until gcloud iam service-accounts describe "postgresql2dc-credentials@$PROJECT_ID.iam.gserviceaccount.com" &>/dev/null; do
  echo "${YELLOW_TEXT}Waiting...${RESET_FORMAT}"
  sleep 5
done

gcloud iam service-accounts keys create "postgresql2dc-credentials.json" \
  --iam-account "postgresql2dc-credentials@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:postgresql2dc-credentials@$PROJECT_ID.iam.gserviceaccount.com" \
  --quiet \
  --role "roles/datacatalog.admin"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 3 Completed: Create Service Account for PostgreSQL${RESET_FORMAT}"
pause_for_check

cd infrastructure/terraform/
public_ip_address=$(terraform output -raw public_ip_address)
username=$(terraform output -raw username)
password=$(terraform output -raw password)
database=$(terraform output -raw db_name)
cd ~/cloudsql-postgresql-tooling

docker run --rm --tty -v "$PWD":/data mesmacosta/postgresql2datacatalog:stable \
  --datacatalog-project-id=$PROJECT_ID \
  --datacatalog-location-id=$REGION \
  --postgresql-host=$public_ip_address \
  --postgresql-user=$username \
  --postgresql-pass=$password \
  --postgresql-database=$database
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 4 Completed: Execute PostgreSQL to Data Catalog connector${RESET_FORMAT}"
pause_for_check

./cleanup-db.sh
docker run --rm --tty -v "$PWD":/data mesmacosta/postgresql-datacatalog-cleaner:stable \
  --datacatalog-project-ids=$PROJECT_ID \
  --rdbms-type=postgresql \
  --table-container-type=schema
./delete-db.sh

# MySQL Setup
echo "${MAGENTA_TEXT}${BOLD_TEXT}.. Setting up MySQL Connector...${RESET_FORMAT}"
cd ~
gsutil cp gs://spls/gsp814/cloudsql-mysql-tooling.zip .
unzip -o cloudsql-mysql-tooling.zip
cd cloudsql-mysql-tooling/infrastructure/terraform
sed -i "s/us-central1/$REGION/g" variables.tf
sed -i "s/$REGION-a/$ZONE/g" variables.tf
cd ~/cloudsql-mysql-tooling
bash init-db.sh
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 5 Completed: Create the MySQL Database${RESET_FORMAT}"
pause_for_check

gcloud iam service-accounts create mysql2dc-credentials \
  --display-name  "Service Account for MySQL to Data Catalog connector" \
  --project $PROJECT_ID

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for service account to become available...${RESET_FORMAT}"
sleep 10

until gcloud iam service-accounts describe "mysql2dc-credentials@$PROJECT_ID.iam.gserviceaccount.com" &>/dev/null; do
  echo "${YELLOW_TEXT}Waiting...${RESET_FORMAT}"
  sleep 5
done

gcloud iam service-accounts keys create "mysql2dc-credentials.json" \
  --iam-account "mysql2dc-credentials@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:mysql2dc-credentials@$PROJECT_ID.iam.gserviceaccount.com" \
  --quiet \
  --role "roles/datacatalog.admin"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 6 Completed: Create Service Account for MySQL${RESET_FORMAT}"
pause_for_check

cd infrastructure/terraform/
public_ip_address=$(terraform output -raw public_ip_address)
username=$(terraform output -raw username)
password=$(terraform output -raw password)
database=$(terraform output -raw db_name)
cd ~/cloudsql-mysql-tooling

docker run --rm --tty -v "$PWD":/data mesmacosta/mysql2datacatalog:stable \
  --datacatalog-project-id=$PROJECT_ID \
  --datacatalog-location-id=$REGION \
  --mysql-host=$public_ip_address \
  --mysql-user=$username \
  --mysql-pass=$password \
  --mysql-database=$database
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 7 Completed: Execute MySQL to Data Catalog connector${RESET_FORMAT}"

echo
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
