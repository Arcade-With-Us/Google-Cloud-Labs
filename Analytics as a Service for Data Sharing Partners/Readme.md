<h1 align="center">
✨  Analytics as a Service for Data Sharing Partners || GSP1042 ✨
</h1>

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/42014?parent=catalog" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

---
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

**🌐Launch Cloud Shell:**
Start your Google CloudShell session by [clicking here](https://console.cloud.google.com/home/dashboard?project=&pli=1&cloudshell=true).

## 💻 **Execute in Cloud Shell** 
```bash
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Analytics%20as%20a%20Service%20for%20Data%20Sharing%20Partners/GSP1042-1.sh

sudo chmod +x GSP1042-1.sh

./GSP1042-1.sh
```

### 2. 🔑 Store Your Main Project ID

After running the commands above, **copy the `PROJECT ID`** displayed in the last line of your Cloud Shell output (e.g., `PROJECT ID=qwiklabs-gcp-xxxx`). You'll need this ID for subsequent steps.

### 3. 👁️ BigQuery: Authorize Views

Follow these steps in the Google Cloud Console for your Main Lab Project:

1.  Navigate to **☰ Menu > BigQuery**.
2.  In the Explorer panel, find your project, then expand `demo_dataset`.
3.  Click on **Sharing**, then select **Authorize Views**.
4.  In the "Authorize views" panel:
  *   Select `authorized_view_a` from the list.
  *   Click **ADD AUTHORIZATION**.
5.  Repeat for the other view:
  *   Select `authorized_view_b` from the list.
  *   Click **ADD AUTHORIZATION**.
6.  Click **CLOSE**.

### 4. 🤝 Share Authorized Views

Now, share these views with the user accounts specified in the lab:

#### For `authorized_view_a`:
1.  In BigQuery, under `demo_dataset`, find `authorized_view_a`.
2.  Click the three dots (⋮) next to it (or select it) and choose **SHARE**.
3.  In the "Share `authorized_view_a`" panel, click **ADD PRINCIPAL**.
4.  In the "New principals" field, paste **Username A** (from the lab instructions).
5.  Assign the Role: `BigQuery Data Viewer`.
6.  Click **SAVE**.

#### For `authorized_view_b`:
1.  Similarly, find `authorized_view_b` under `demo_dataset`.
2.  Click the three dots (⋮) next to it (or select it) and choose **SHARE**.
3.  Click **ADD PRINCIPAL**.
4.  Paste **Username B** (from the lab instructions).
5.  Assign the Role: `BigQuery Data Viewer`.
6.  Click **SAVE**.

### 5. 🚪 Close Incognito Window (If Open)

If you have any incognito windows open from previous lab activity, close them.

---

## 🚀 Project A: Configuration

### 1. 💻 Access Project A

*   Log in to the Google Cloud Console using the credentials provided for **Project A**.
*   Open a new **Cloud Shell** session within Project A.

### 2. 🛠️ Create View in Project A

In the Project A Cloud Shell, first set an environment variable for your **Main Lab Project ID** (the one you copied in step 1.2):

```bash
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Analytics%20as%20a%20Service%20for%20Data%20Sharing%20Partners/GSP1042-2.sh

sudo chmod +x GSP1042-2.sh

./GSP1042-2.sh
```

### 3. 📊 Connect Looker Studio (for Project A)

1.  Open a **new Incognito window**.
2.  Navigate to [Looker Studio](https://lookerstudio.google.com/).
3.  Click on **Blank Report**.
4.  If prompted for account setup (country/company):
  *   Country: Select **India** (or your preferred country).
  *   Company: Enter **ArcadeCrew** (or any name).
  *   Agree to the terms and click **Continue**. Answer any subsequent prompts (e.g., "Yes to all" for email preferences).
5.  In the "Add data to report" window, select the **BigQuery** connector.
6.  Click **AUTHORIZE** if prompted, and allow access.
7.  Under "Project", select **Project A's ID**.
8.  Under "Dataset", select `customer_a_dataset`.
9.  Under "Table", select `customer_a_table`.
10. Click **ADD** (bottom right), then confirm by clicking **ADD TO REPORT**.

### 4. 🚪 Close Incognito Window

Close the Incognito window used for Project A's Looker Studio.

---

## 🚀 Project B: Configuration

### 1. 💻 Access Project B

*   Log in to the Google Cloud Console using the credentials provided for **Project B**.
*   Open a new **Cloud Shell** session within Project B.

### 2. 🛠️ Create View in Project B

In the Project B Cloud Shell, set the environment variable for your **Main Lab Project ID** again:

```bash
curl -LO raw.githubusercontent.com/Arcade-With-Us/Google-Cloud-Labs/refs/heads/main/Analytics%20as%20a%20Service%20for%20Data%20Sharing%20Partners/GSP1042-2.sh

sudo chmod +x GSP1042-2.sh

./GSP1042-2.sh
```

### 3. 📊 Connect Looker Studio (for Project B)

1.  Open a **new Incognito window**.
2.  Navigate to [Looker Studio](https://lookerstudio.google.com/).
3.  Click on **Blank Report**.
4.  (You might not be prompted for account setup again if you recently did it for Project A). If prompted:
  *   Country: Select **India** (or your preferred country).
  *   Company: Enter **ArcadeCrew** (or any name).
  *   Agree and **Continue**.
5.  Select the **BigQuery** connector.
6.  Click **AUTHORIZE** if needed.
7.  Under "Project", select **Project B's ID**.
8.  Under "Dataset", select `customer_b_dataset`.
9.  Under "Table", select `customer_b_table`.
10. Click **ADD**, then **ADD TO REPORT**.

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
