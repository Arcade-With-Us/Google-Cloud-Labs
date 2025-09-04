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

echo "${YELLOW_TEXT}Step 1:${RESET_FORMAT} ${BOLD_TEXT}Inserting data into the Portfolio table.${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo) VALUES (1, 'Banking', 'Bnkg', 'All Banking Business')"

echo "${YELLOW_TEXT}Step 2:${RESET_FORMAT} ${BOLD_TEXT}Inserting additional data into the Portfolio table.${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo) VALUES (2, 'Asset Growth', 'AsstGrwth', 'All Asset Focused Products')"

echo "${YELLOW_TEXT}Step 3:${RESET_FORMAT} ${BOLD_TEXT}Adding more entries to the Portfolio table.${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo) VALUES (3, 'Insurance', 'Ins', 'All Insurance Focused Products')"

echo "${YELLOW_TEXT}Step 4:${RESET_FORMAT} ${BOLD_TEXT}Inserting data into the Category table.${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES (1, 1, 'Cash')"

echo "${YELLOW_TEXT}Step 5:${RESET_FORMAT} ${BOLD_TEXT}Adding more entries to the Category table.${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES (2, 2, 'Investments - Short Return')"

echo "${YELLOW_TEXT}Step 6:${RESET_FORMAT} ${BOLD_TEXT}Continuing to populate the Category table.${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES (3, 2, 'Annuities')"

echo "${YELLOW_TEXT}Step 7:${RESET_FORMAT} ${BOLD_TEXT}Finalizing entries in the Category table.${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Category (CategoryId, PortfolioId, CategoryName) VALUES (4, 3, 'Life Insurance')"

echo "${YELLOW_TEXT}Step 8:${RESET_FORMAT} ${BOLD_TEXT}Inserting data into the Product table.${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (1, 1, 1, 'Checking Account', 'ChkAcct', 'Banking LOB')"

echo "${YELLOW_TEXT}Step 9:${RESET_FORMAT} ${BOLD_TEXT}Adding more entries to the Product table.${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (2, 2, 2, 'Mutual Fund Consumer Goods', 'MFundCG', 'Investment LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (3, 3, 2, 'Annuity Early Retirement', 'AnnuFixed', 'Investment LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (4, 4, 3, 'Term Life Insurance', 'TermLife', 'Insurance LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (5, 1, 1, 'Savings Account', 'SavAcct', 'Banking LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (6, 1, 1, 'Personal Loan', 'PersLn', 'Banking LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (7, 1, 1, 'Auto Loan', 'AutLn', 'Banking LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (8, 4, 3, 'Permanent Life Insurance', 'PermLife', 'Insurance LOB')"

gcloud spanner databases execute-sql banking-ops-db --instance=banking-ops-instance --sql="INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass) VALUES (9, 2, 2, 'US Savings Bonds', 'USSavBond', 'Investment LOB')"

# Additional instructions for remaining commands follow the same pattern
# ...

mkdir python-helper
cd python-helper

echo "${MAGENTA_TEXT}Downloading required Python files...${RESET_FORMAT}"
wget https://storage.googleapis.com/cloud-training/OCBL373/requirements.txt
wget https://storage.googleapis.com/cloud-training/OCBL373/snippets.py

echo "${CYAN_TEXT}Installing Python dependencies...${RESET_FORMAT}"
pip install -r requirements.txt
pip install setuptools

echo "${BLUE_TEXT}Executing Python scripts for database operations...${RESET_FORMAT}"
python snippets.py banking-ops-instance --database-id  banking-ops-db insert_data

python snippets.py banking-ops-instance --database-id  banking-ops-db query_data

python snippets.py banking-ops-instance --database-id  banking-ops-db add_column

python snippets.py banking-ops-instance --database-id  banking-ops-db update_data

python snippets.py banking-ops-instance --database-id  banking-ops-db query_data_with_new_column

python snippets.py banking-ops-instance --database-id  banking-ops-db add_index

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
