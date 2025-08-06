<h1 align="center">
✨ Running a Dedicated Ethereum RPC Node in Google Cloud || GSP1116 ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/61475?parent=catalog"_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

---

## 🔑 Solution [here]()

---

##⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are intended <em>solely for educational purposes</em> to help you understand Google Cloud monitoring services and advance your cloud skills. Before using, please review it carefully to become familiar with the services involved.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience—<em>not</em> to circumvent it.
</blockquote>

### ©Credit
- **DM for credit or removal request (no copyright intended) ©All rights and credits for the original content belong to Google Cloud [Google Cloud Skill Boost website](https://www.cloudskillsboost.google/)** 🙏

---

## ⚙️ <ins>Lab Environment Setup</ins>

> ✅ **NOTE:** *Watch Full Video to get Full Scores on Check My Progress.*

**🌐Launch Cloud Shell:**
Start your Google CloudShell session by [clicking here](https://console.cloud.google.com/home/dashboard?project=&pli=1&cloudshell=true).

## 💻 **Execute in Cloud Shell** 

```
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Running%20a%20Dedicated%20Ethereum%20RPC%20Node%20in%20Google%20Cloud/GSP1116-1.sh

sudo chmod +x GSP1116-1.sh

./GSP1116-1.sh
```
```
sudo su ethereum
```
```
bash
```
```
cd ~
sudo apt update -y
sudo apt-get update -y
sudo apt install -y dstat jq
```
```
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
rm add-google-cloud-ops-agent-repo.sh
```
```
mkdir /mnt/disks/chaindata-disk/ethereum/
mkdir /mnt/disks/chaindata-disk/ethereum/geth
mkdir /mnt/disks/chaindata-disk/ethereum/geth/chaindata
mkdir /mnt/disks/chaindata-disk/ethereum/geth/logs
mkdir /mnt/disks/chaindata-disk/ethereum/lighthouse
mkdir /mnt/disks/chaindata-disk/ethereum/lighthouse/chaindata
mkdir /mnt/disks/chaindata-disk/ethereum/lighthouse/logs

sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get -y install Ethereum
geth version

RELEASE_URL="https://api.github.com/repos/sigp/lighthouse/releases/latest"
LATEST_VERSION=$(curl -s $RELEASE_URL | jq -r '.tag_name')

DOWNLOAD_URL=$(curl -s $RELEASE_URL | jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-gnu.tar.gz")) | .browser_download_url')

curl -L "$DOWNLOAD_URL" -o "lighthouse-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

tar -xvf "lighthouse-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

rm "lighthouse-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

sudo mv lighthouse /usr/bin

lighthouse --version

cd ~
mkdir ~/.secret
openssl rand -hex 32 > ~/.secret/jwtsecret
chmod 440 ~/.secret/jwtsecret
```
```
export CHAIN=eth
export NETWORK=mainnet
export EXT_IP_ADDRESS_NAME=$CHAIN-$NETWORK-rpc-ip
export EXT_IP_ADDRESS=$(gcloud compute addresses list --filter=$EXT_IP_ADDRESS_NAME --format="value(address_range())")

nohup geth --datadir "/mnt/disks/chaindata-disk/ethereum/geth/chaindata" \
--http.corsdomain "*" \
--http \
--http.addr 0.0.0.0 \
--http.port 8545 \
--http.corsdomain "*" \
--http.api admin,debug,web3,eth,txpool,net \
--http.vhosts "*" \
--gcmode full \
--cache 2048 \
--mainnet \
--metrics \
--metrics.addr 127.0.0.1 \
--syncmode snap \
--authrpc.vhosts="localhost" \
--authrpc.port 8551 \
--authrpc.jwtsecret=/home/ethereum/.secret/jwtsecret \
--txpool.accountslots 32 \
--txpool.globalslots 8192 \
--txpool.accountqueue 128 \
--txpool.globalqueue 2048 \
--nat extip:$EXT_IP_ADDRESS \
&> "/mnt/disks/chaindata-disk/ethereum/geth/logs/geth.log" &
```
```
sudo chmod 666 /etc/google-cloud-ops-agent/config.yaml

sudo cat << EOF >> /etc/google-cloud-ops-agent/config.yaml
logging:
  receivers:
    syslog:
      type: files
      include_paths:
      - /var/log/messages
      - /var/log/syslog

    ethGethLog:
      type: files
      include_paths: ["/mnt/disks/chaindata-disk/ethereum/geth/logs/geth.log"]
      record_log_file_path: true

    ethLighthouseLog:
      type: files
      include_paths: ["/mnt/disks/chaindata-disk/ethereum/lighthouse/logs/lighthouse.log"]
      record_log_file_path: true

    journalLog:
      type: systemd_journald

  service:
    pipelines:
      logging_pipeline:
        receivers:
        - syslog
        - journalLog
        - ethGethLog
        - ethLighthouseLog
EOF

sudo systemctl stop google-cloud-ops-agent
sudo systemctl start google-cloud-ops-agent

sudo journalctl -xe | grep "google_cloud_ops_agent_engine"
```
```
sudo cat << EOF >> /etc/google-cloud-ops-agent/config.yaml
metrics:
  receivers:
    prometheus:
        type: prometheus
        config:
          scrape_configs:
            - job_name: 'geth_exporter'
              scrape_interval: 10s
              metrics_path: /debug/metrics/prometheus
              static_configs:
                - targets: ['localhost:6060']
            - job_name: 'lighthouse_exporter'
              scrape_interval: 10s
              metrics_path: /metrics
              static_configs:
                - targets: ['localhost:5054']

  service:
    pipelines:
      prometheus_pipeline:
        receivers:
        - prometheus
EOF

sudo systemctl stop google-cloud-ops-agent
sudo systemctl start google-cloud-ops-agent

sudo journalctl -xe | grep "google_cloud_ops_agent_engine"
```
```
exit
```
```
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Running%20a%20Dedicated%20Ethereum%20RPC%20Node%20in%20Google%20Cloud/GSP1116-2.sh

sudo chmod +x GSP1116-2.sh

./GSP1116-2.sh
```
---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

Your hard work and determination paid off! 💻
You've successfully completed the lab. **Way to go!** 🚀


<div align="center" style="padding: 5px;">
  <h3>📱 Join the Arcade With Us Community</h3>
  
  <a href="https://chat.whatsapp.com/KN3NvYNTJvU5xMCVTORJtS">
    <img src="https://img.shields.io/badge/Join_WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" alt="Join WhatsApp 👥">
  </a>
  &nbsp;
  <a href="https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l">
    <img src="https://img.shields.io/badge/Subscribe-Arcade%20With%20Us-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube Channel">
  </a>
  &nbsp;
  <a href="https://www.linkedin.com/in/tripti-gupta-a28a6832b/">
    <img src="https://img.shields.io/badge/LINKEDIN-Tripti%20Gupta-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn">
</a>


</div>

---

<div align="center">
  <p style="font-size: 12px; color: #586069;">
    <em>This guide is provided for educational purposes. Always follow Qwiklabs terms of service and YouTube's community guidelines.</em>
  </p>
  <p style="font-size: 12px; color: #586069;">
    <em>Last updated: August 2025</em>
  </p>
</div>
