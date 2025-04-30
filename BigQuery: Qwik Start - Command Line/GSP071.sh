#!/bin/bash

# Enhanced Color Definitions
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bold Colors
BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_MAGENTA='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

# Background Colors
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_MAGENTA='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# Special Formats
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'

RESET='\033[0m'

#----------------------------------------------------start--------------------------------------------------#

echo -e "${BOLD_CYAN}╔════════════════════════════════════════╗${RESET}"
echo -e "${BOLD_CYAN}║                                        ║${RESET}"
echo -e "${BOLD_CYAN}║   ${BOLD_YELLOW}Welcome to Arcade With Us${BOLD_GREEN} Tutorials ${BOLD_CYAN}                ║${RESET}"
echo -e "${BOLD_CYAN}║                                        ║${RESET}"
echo -e "${BOLD_CYAN}╚════════════════════════════════════════╝${RESET}"
echo ""

# BigQuery operations
echo -e "${BOLD_BLUE}→ Querying Shakespeare dataset...${RESET}"
bq show bigquery-public-data:samples.shakespeare
echo ""

echo -e "${BOLD_BLUE}→ Searching for 'raisin' words...${RESET}"
bq query --use_legacy_sql=false \
'SELECT
   word,
   SUM(word_count) AS count
 FROM
   `bigquery-public-data`.samples.shakespeare
 WHERE
   word LIKE "%raisin%"
 GROUP BY
   word'
echo ""

echo -e "${BOLD_BLUE}→ Searching for 'huzzah'...${RESET}"
bq query --use_legacy_sql=false \
'SELECT
   word
 FROM
   `bigquery-public-data`.samples.shakespeare
 WHERE
   word = "huzzah"'
echo ""

# Create and load babynames dataset
echo -e "${BOLD_MAGENTA}→ Creating babynames dataset...${RESET}"
bq mk babynames
echo ""

echo -e "${BOLD_MAGENTA}→ Downloading and extracting baby names data...${RESET}"

wget https://github.com/Itsabhishek7py/GoogleCloudSkillsboost/raw/refs/heads/main/BigQuery:%20Qwik%20Start%20-%20Command%20Line/names.zip

unzip names.zip
echo ""

echo -e "${BOLD_MAGENTA}→ Loading 2010 baby names data...${RESET}"
bq load babynames.names2010 yob2010.txt name:string,gender:string,count:integer
echo ""

# Query examples
echo -e "${BOLD_GREEN}→ Top 5 female names in 2010...${RESET}"
bq query "SELECT name,count FROM babynames.names2010 WHERE gender = 'F' ORDER BY count DESC LIMIT 5"
echo ""

echo -e "${BOLD_GREEN}→ Top 5 least common male names in 2010...${RESET}"
bq query "SELECT name,count FROM babynames.names2010 WHERE gender = 'M' ORDER BY count ASC LIMIT 5"
echo ""

# Cleanup
echo -e "${BOLD_RED}→ Cleaning up...${RESET}"
bq rm -r babynames
rm -f names.zip yob2010.txt
echo ""

echo -e "${BOLD_WHITE}${BG_BLUE}════════════════════════════════════════${RESET}"
echo -e "${BOLD_WHITE}${BG_BLUE}                                        ${RESET}"
echo -e "${BOLD_WHITE}${BG_BLUE}   ${BOLD_YELLOW}Congratulations ${BOLD_WHITE}for ${BOLD_GREEN}Completing the Lab! ${BOLD_WHITE}${BG_BLUE}  ${RESET}"
echo -e "${BOLD_WHITE}${BG_BLUE}                                        ${RESET}"
echo -e "${BOLD_WHITE}${BG_BLUE}════════════════════════════════════════${RESET}"
echo "" 
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
#-----------------------------------------------------end----------------------------------------------------------#
