<h1 align="center">
✨ Exploring Cost-optimization for GKE Virtual Machines || GSP767✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/15577?parent=catalog" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

---

## 🔑 Solution [here]()

---

## ⚠️ Disclaimer ⚠️

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

## ⚙️ Lab Environment Setup:

**🌐Launch Cloud Shell:**
Start your Google CloudShell session by [clicking here](https://console.cloud.google.com/home/dashboard?project=&pli=1&cloudshell=true).

## 💻 **Execute in Cloud Shell** 
```
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Exploring%20Cost-optimization%20for%20GKE%20Virtual%20Machines/GSP767.sh

sudo chmod +x GSP767.sh

./GSP767.sh
```

### After opening the link please follow these steps:
1. In the Cloud Console, open the **Navigation Menu** and select **VPC Network** in the **Networking** section.
2. Click on the default network. Under Subnets tab locate the default subnet in the **Region** defined in terminal and click on it.
3. Click Edit at the top of the screen.
4. Select Click Edit at the top of the screen.
5. Select **Flow Logs** to be **On**. Then, click Save.
6. Next, click **`View Flow Logs in Logs Explorer`**.
[Check](https://cdn.qwiklabs.com/xFI8yhMOxwEucp1R5py3R6jDFuUkR%2FP5XmZQ9bdJfgs%3D)
7. Click on **Actions** > **Create Sink**.
[Check](https://cdn.qwiklabs.com/cSR9%2FGXOiDMFUvOBLXf9YlCW4r9TMdJKE%2BS%2BVi0cTu4%3D)
8. Name your sink **`FlowLogsSample`**. Click Next.
9. For your Sink Service, select `BigQuery Dataset`.
10. For your BigQuery Dataset, select `Create new BigQuery dataset`.
11. Name your dataset as '**`us_flow_logs`**', and click **CREATE DATASET**.
12. Everything else can be left as-is. Click **Create Sink**.
13. Now, inspect your newly created dataset. In the Cloud Console, from the Navigation Menu in the Analytics section, click **BigQuery**.
14. Select your project name, and then select the `us_flow_logs` to see the newly created table.
#### **`If no table is there, you may need to refresh until it has been created`**.
15. Click on the `compute_googleapis_com_vpc_flows_xxx` table under your `us_flow_logs` dataset.
[Check](https://cdn.qwiklabs.com/uwtUC8ICO7mh8nZe3m%2B13Ekzf8nOyqcOVZRPp3Arf%2Bk%3D)
16. Click on Query > In new tab.
17. In the BigQuery Editor, paste this in between `SELECT` and `FROM`:
```
jsonPayload.src_instance.zone AS src_zone, jsonPayload.src_instance.vm_name AS src_vm, jsonPayload.dest_instance.zone AS dest_zone, jsonPayload.dest_instance.vm_name
```
18. Click **Run**.
19. Back to Cloud Shell and Run this command to edit the pod-2 manifest:
```
sed -i 's/podAntiAffinity/podAffinity/g' pod-2.yaml
```
20. Delete the current running pod-2:
```
kubectl delete pod pod-2
```
21. With pod-2 deleted, recreate it using the newly edited manifest:
```
kubectl create -f pod-2.yaml
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
    <em>Last updated: April 2025</em>
  </p>
</div>
