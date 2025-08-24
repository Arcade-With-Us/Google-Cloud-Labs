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

#!/bin/bash
set -e

# =========================
# 1. INSTALL VAULT
# =========================
echo "Installing Vault..."
sudo apt update && sudo apt install -y curl gnupg lsb-release jq

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install vault -y

echo "Vault installed:"
vault --version

# =========================
# 2. START VAULT DEV SERVER
# =========================
echo "Starting Vault dev server..."
pkill vault || true
vault server -dev -dev-root-token-id="root-token" > vault.log 2>&1 &
sleep 3

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="root-token"

echo "Vault server started with:"
echo "VAULT_ADDR=$VAULT_ADDR"
echo "VAULT_TOKEN=$VAULT_TOKEN"

vault status

# =========================
# 3. KV SECRETS: CREATE, READ, DELETE
# =========================
echo "Working with KV secrets..."
vault kv get secret/hello || true
vault kv put secret/hello foo=world
vault kv put secret/hello foo=world excited=yes
vault kv get secret/hello
vault kv get -field=excited secret/hello > secret.txt

PROJECT_ID=$(gcloud config get-value project)
gsutil cp secret.txt gs://$PROJECT_ID

vault kv delete secret/hello

# Create multiple versions and manage them
vault kv put secret/example test=version01
vault kv put secret/example test=version02
vault kv put secret/example test=version03
vault kv get -version=2 secret/example
vault kv delete -versions=2 secret/example
vault kv undelete -versions=2 secret/example
vault kv destroy -versions=2 secret/example || true

# =========================
# 4. ENABLE ANOTHER SECRETS ENGINE
# =========================
vault secrets enable -path=kv kv || true
vault secrets list

vault kv put kv/hello target=world
vault kv get kv/hello

vault kv put kv/my-secret value="s3c(eT"
vault kv get kv/my-secret
vault kv get -format=json kv/my-secret | jq -r .data.value > my-secret.txt
gsutil cp my-secret.txt gs://$PROJECT_ID
vault kv delete kv/my-secret
vault kv list kv/

vault secrets disable kv/ || true

# =========================
# 5. TOKEN AUTHENTICATION
# =========================
TOKEN1=$(vault token create -format=json | jq -r .auth.client_token)
vault login $TOKEN1
TOKEN2=$(vault token create -format=json | jq -r .auth.client_token)
vault token revoke $TOKEN1 || true

# =========================
# 6. AUTH METHODS - USERPASS
# =========================
vault auth enable userpass || true
vault write auth/userpass/users/admin password=password! policies=admin
vault login -method=userpass username=admin password=password!

# =========================
# 7. TRANSIT SECRETS ENGINE
# =========================
vault secrets enable transit || true
vault write -f transit/keys/my-key

# Encrypt data
PLAINTEXT="Learn Vault!"
ENC=$(echo -n "$PLAINTEXT" | base64 | vault write -format=json transit/encrypt/my-key plaintext=- | jq -r .data.ciphertext)

# Decrypt data
DECRYPTED_BASE64=$(vault write -format=json transit/decrypt/my-key ciphertext="$ENC" | jq -r .data.plaintext)
echo "$DECRYPTED_BASE64" | base64 --decode > decrypted-string.txt

cat decrypted-string.txt
gsutil cp decrypted-string.txt gs://$PROJECT_ID

echo "All tasks completed successfully!"

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
