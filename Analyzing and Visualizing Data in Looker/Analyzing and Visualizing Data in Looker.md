<h1 align="center">
✨🌐   Analyzing and Visualizing Data in Looker ✨
<div align="center">
<a href="" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

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
## Task 1: Single Value Visualization (`Average Elevation`)
```
explore: +airports { 
    query: ArcadeCrew_Task1 {
      measures: [average_elevation]
    }
  }
```

- **Explore** → **FAA** → **Airports**
- Customize Visualization:
  - Select **Single Value**
  - Set **Value Format**: `0.00`
  - Modify **Value Color** and **Title**
- Save to **New Dashboard** → **"Airports"**

## Task 2: Bar Chart (`Average Elevation by Facility Type`)
```
explore: +airports {
    query: ArcadeCrew_Task2 {
      dimensions: [facility_type]
      measures: [average_elevation, count]
  }
}
```

- **Explore** → **FAA** → **Airports**
- Set **Row Limit**: `5`
- Customize Visualization:
  - Select **Bar Chart**
  - Enable **Value Labels**
  - Rename **Axes** and set **Value Format**: `0.00`
- Save to **Existing Dashboard** → **"Airports"**

## Task 3: Line Chart (`Number of Flights Cancelled Each Week in 2004`)
```
explore: +flights {
    query: ArcadeCrew_Task3 {
      dimensions: [depart_week]
      measures: [cancelled_count]
      filters: [flights.depart_date: "2004"]
  }
}
```

- **Explore** → **FAA** → **Flights**
- Customize Visualization:
  - Select **Line Chart**
  - Set **Filled Point Style**
  - Add **Reference Line**
- Save to **New Dashboard** → **"Airports and Flights"**

## Task 4: Line Chart (`Number of Flights by Distance Tier in 2003`)
```
explore: +flights {
    query: ArcadeCrew_Task4 {
      dimensions: [depart_week, distance_tiered]
      measures: [count]
      filters: [flights.depart_date: "2003"]
  }
}
```

- **Explore** → **FAA** → **Flights**
- Customize Visualization:
  - Select **Stacked Line Chart**
  - Enable **Overlay Series Positioning**
- Save to **Existing Dashboard** → **"Airports and Flights"**
  
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
