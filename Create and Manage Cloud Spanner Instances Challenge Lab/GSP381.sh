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

gcloud spanner instances create banking-ops-instance --config=regional-$REGION --description="cloudwalabanda" --nodes=1

gcloud spanner databases create banking-ops-db --instance=banking-ops-instance

gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance --ddl="CREATE TABLE Portfolio (
    PortfolioId INT64 NOT NULL,
    Name STRING(MAX),
    ShortName STRING(MAX),
    PortfolioInfo STRING(MAX))
    PRIMARY KEY (PortfolioId)"

gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance --ddl="CREATE TABLE Category (
    CategoryId INT64 NOT NULL,
    PortfolioId INT64 NOT NULL,
    CategoryName STRING(MAX),
    PortfolioInfo STRING(MAX))
    PRIMARY KEY (CategoryId)"

gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance --ddl="CREATE TABLE Product (
    ProductId INT64 NOT NULL,
    CategoryId INT64 NOT NULL,
    PortfolioId INT64 NOT NULL,
    ProductName STRING(MAX),
    ProductAssetCode STRING(25),
    ProductClass STRING(25))
    PRIMARY KEY (ProductId)"

gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance --ddl="CREATE TABLE Customer (
    CustomerId STRING(36) NOT NULL,
    Name STRING(MAX) NOT NULL,
    Location STRING(MAX) NOT NULL)
    PRIMARY KEY (CustomerId)"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql='INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo)
VALUES 
  (1, "Banking", "Bnkg", "All Banking Business"),
  (2, "Asset Growth", "AsstGrwth", "All Asset Focused Products"),
  (3, "Insurance", "Insurance", "All Insurance Focused Products")'

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql='INSERT INTO Category (CategoryId, PortfolioId, CategoryName)
VALUES 
  (1, 1, "Cash"),
  (2, 2, "Investments - Short Return"),
  (3, 2, "Annuities"),
  (4, 3, "Life Insurance")'

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql='INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass)
VALUES 
  (1, 1, 1, "Checking Account", "ChkAcct", "Banking LOB"),
  (2, 2, 2, "Mutual Fund Consumer Goods", "MFundCG", "Investment LOB"),
  (3, 3, 2, "Annuity Early Retirement", "AnnuFixed", "Investment LOB"),
  (4, 4, 3, "Term Life Insurance", "TermLife", "Insurance LOB"),
  (5, 1, 1, "Savings Account", "SavAcct", "Banking LOB"),
  (6, 1, 1, "Personal Loan", "PersLn", "Banking LOB"),
  (7, 1, 1, "Auto Loan", "AutLn", "Banking LOB"),
  (8, 4, 3, "Permanent Life Insurance", "PermLife", "Insurance LOB"),
  (9, 2, 2, "US Savings Bonds", "USSavBond", "Investment LOB")'

curl -LO https://raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/raw/refs/heads/main/Create%20and%20Manage%20Cloud%20Spanner%20Instances%20Challenge%20Lab/Customer_List_500.csv

gcloud services disable dataflow.googleapis.com --force
gcloud services enable dataflow.googleapis.com

cat > manifest.json << EOF_CP
{
  "tables": [
    {
      "table_name": "Customer",
      "file_patterns": [
        "gs://$DEVSHELL_PROJECT_ID/Customer_List_500.csv"
      ],
      "columns": [
        {"column_name" : "CustomerId", "type_name" : "STRING" },
        {"column_name" : "Name", "type_name" : "STRING" },
        {"column_name" : "Location", "type_name" : "STRING" }
      ]
    }
  ]
}
EOF_CP

gsutil mb gs://$DEVSHELL_PROJECT_ID

touch cloudwalabanda

gsutil cp emptyfile gs://$DEVSHELL_PROJECT_ID/tmp/cloudwalabanda

gsutil cp Customer_List_500.csv gs://$DEVSHELL_PROJECT_ID

gsutil cp manifest.json gs://$DEVSHELL_PROJECT_ID

sleep 100

gcloud dataflow jobs run cloudwalabanda --gcs-location gs://dataflow-templates-"$REGION"/latest/GCS_Text_to_Cloud_Spanner --region="$REGION" --staging-location gs://$DEVSHELL_PROJECT_ID/tmp/ --parameters instanceId=banking-ops-instance,databaseId=banking-ops-db,importManifest=gs://$DEVSHELL_PROJECT_ID/manifest.json

gcloud spanner databases ddl update banking-ops-db --instance=banking-ops-instance --ddl='ALTER TABLE Category ADD COLUMN MarketingBudget INT64;'

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
