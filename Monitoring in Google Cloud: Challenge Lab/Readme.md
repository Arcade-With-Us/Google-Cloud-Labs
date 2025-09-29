<h1 align="center">
✨🌐  Monitoring in Google Cloud: Challenge Lab || ARC115  ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/63855?parent=catalog" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

---

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are intended <em>solely for educational purposes</em> to help you understand Google Cloud monitoring services and advance your cloud skills. Before using, please review it carefully to become familiar with the services involved.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience—<em>not</em> to circumvent it.
</blockquote>

---

## ⚙️ <ins>Lab Environment Setup</ins>

> ✅ **NOTE:** *Watch Full Video to get Full Scores on Check My Progress.*

<div style="padding: 15px; margin: 10px 0;">
<p><strong>☁️ Run in Cloud Shell:</strong></p>

## 💻 **Execute in Cloud Shell**  
Run the following commands in **Cloud Shell**:
```bash
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Monitoring%20in%20Google%20Cloud%3A%20Challenge%20Lab/ARC115.sh

sudo chmod +x ARC115.sh

./ARC115.sh
```

</div>

</details>

---

<details>
<summary><h3>📊 Task 1: Set Up Monitoring Dashboards</h3></summary>

<div style="padding: 15px; margin: 10px 0;">

1. Navigate to the [Monitoring Dashboards Console](https://console.cloud.google.com/monitoring/dashboards)

2. Create a new custom dashboard with the following charts:

   | Chart Type | Metric | Filter |
   |------------|--------|--------|
   | 📈 Line Chart | CPU Load (1m) | VM Resource Metric |
   | 📉 Line Chart | Requests | Apache Web Server metrics |

</div>
</details>

---

<details>
<summary><h3>📝 Task 2: Create a Log-Based Metric</h3></summary>

<div style="padding: 15px; margin: 10px 0;">

1. Navigate to the [Log-Based Metrics Console](https://console.cloud.google.com/logs/metrics/edit)

2. Create a new user-defined metric with these specifications:
   - **Metric Name:** `arcadewithus`

3. Configure the log filter:
   ```bash
   resource.type="gce_instance"
   logName="projects/PROJECT_ID/logs/apache-access"
   textPayload:"200"
   ```
   > ⚠️ **Important:** Replace `PROJECT_ID` with your actual project ID

4. Configure field extraction:
   - **Regular Expression:**
   ```bash
   execution took (\d+)
   ```

5. Verify and create the metric

</div>
</details>


---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

<div align="center" style="padding: 5px;">
  <h3>📱 Join the Arcade With Us Community</h3>
  
  <a href="https://chat.whatsapp.com/KN3NvYNTJvU5xMCVTORJtS">
    <img src="https://img.shields.io/badge/Join_WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" alt="Join WhatsApp">
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
    <em>Last updated: April 2025</em>
  </p>
</div>
