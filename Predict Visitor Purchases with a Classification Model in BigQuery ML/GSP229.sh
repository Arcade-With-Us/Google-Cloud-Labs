#!/bin/bash
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

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Creating the 'ecommerce' BigQuery dataset if it doesn't exist...${RESET_FORMAT}"
bq mk ecommerce

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🧠 Training the first classification model (ecommerce.classification_model)...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}   This model uses 'bounces' and 'time_on_site' features.${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`ecommerce.classification_model\`
OPTIONS
(
model_type='logistic_reg',
input_label_cols = ['will_buy_on_return_visit']
)
AS

SELECT
  * EXCEPT(fullVisitorId)
FROM

  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    \`data-to-insights.ecommerce.web_analytics\`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430')
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)
;
"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📊 Evaluating the first model's performance (ecommerce.classification_model)...${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}   Calculating ROC AUC and assessing model quality.${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
  roc_auc,
  CASE
    WHEN roc_auc > .9 THEN 'good'
    WHEN roc_auc > .8 THEN 'fair'
    WHEN roc_auc > .7 THEN 'decent'
    WHEN roc_auc > .6 THEN 'not great'
  ELSE 'poor' END AS model_quality
FROM
  ML.EVALUATE(MODEL ecommerce.classification_model,  (

SELECT
  * EXCEPT(fullVisitorId)
FROM

  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    \`data-to-insights.ecommerce.web_analytics\`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN '20170501' AND '20170630')
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)

));
"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}✨ Training the second, enhanced classification model (ecommerce.classification_model_2)...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}   This model includes more features like pageviews, traffic source, device, etc.${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`ecommerce.classification_model_2\`
OPTIONS
  (model_type='logistic_reg', input_label_cols = ['will_buy_on_return_visit']) AS

WITH all_visitor_stats AS (
  SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid
)

SELECT * EXCEPT(unique_session_id) FROM (
  SELECT
    CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
    will_buy_on_return_visit,
    MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site,
    IFNULL(totals.pageviews, 0) AS pageviews,
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    device.deviceCategory,
    IFNULL(geoNetwork.country, '') AS country
  FROM \`data-to-insights.ecommerce.web_analytics\`,
       UNNEST(hits) AS h
  JOIN all_visitor_stats USING(fullvisitorid)
  WHERE totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430'
  GROUP BY
    unique_session_id,
    will_buy_on_return_visit,
    bounces,
    time_on_site,
    totals.pageviews,
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    device.deviceCategory,
    country
);
"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📈 Evaluating the second model's performance (ecommerce.classification_model_2)...${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}   Assessing the enhanced model's quality based on ROC AUC.${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
  roc_auc,
  CASE
    WHEN roc_auc > 0.9 THEN 'good'
    WHEN roc_auc > 0.8 THEN 'fair'
    WHEN roc_auc > 0.7 THEN 'decent'
    WHEN roc_auc > 0.6 THEN 'not great'
    ELSE 'poor'
  END AS model_quality
FROM
  ML.EVALUATE(MODEL \`ecommerce.classification_model_2\`,  (
    WITH all_visitor_stats AS (
      SELECT
        fullvisitorid,
        IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
      FROM \`data-to-insights.ecommerce.web_analytics\`
      GROUP BY fullvisitorid
    )
    SELECT * EXCEPT(unique_session_id) FROM (
      SELECT
        CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
        will_buy_on_return_visit,
        MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
        IFNULL(totals.bounces, 0) AS bounces,
        IFNULL(totals.timeOnSite, 0) AS time_on_site,
        totals.pageviews,
        trafficSource.source,
        trafficSource.medium,
        channelGrouping,
        device.deviceCategory,
        IFNULL(geoNetwork.country, '') AS country
      FROM \`data-to-insights.ecommerce.web_analytics\`,
           UNNEST(hits) AS h
      JOIN all_visitor_stats USING(fullvisitorid)
      WHERE totals.newVisits = 1
        AND date BETWEEN '20170501' AND '20170630'
      GROUP BY
        unique_session_id,
        will_buy_on_return_visit,
        bounces,
        time_on_site,
        totals.pageviews,
        trafficSource.source,
        trafficSource.medium,
        channelGrouping,
        device.deviceCategory,
        country
    )
  ));
"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🔮 Making predictions using the enhanced model (ecommerce.classification_model_2)...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}   Predicting purchase likelihood for visitors from July 2017.${RESET_FORMAT}"
bq query --nouse_legacy_sql '
SELECT
*
FROM
  ml.PREDICT(MODEL `ecommerce.classification_model_2`,
   (
WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid
)
  SELECT
      CONCAT(fullvisitorid, "-",CAST(visitId AS STRING)) AS unique_session_id,
      will_buy_on_return_visit,
      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      totals.pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      IFNULL(geoNetwork.country, "") AS country
  FROM `data-to-insights.ecommerce.web_analytics`,
     UNNEST(hits) AS h
    JOIN all_visitor_stats USING(fullvisitorid)
  WHERE
    totals.newVisits = 1
    AND date BETWEEN "20170701" AND "20170801"
  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
)
)
ORDER BY
  predicted_will_buy_on_return_visit DESC;'


echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔄 Re-evaluating the first model (ecommerce.classification_model) for comparison...${RESET_FORMAT}"
bq query --nouse_legacy_sql '
SELECT
  roc_auc,
  CASE
    WHEN roc_auc > .9 THEN "good"
    WHEN roc_auc > .8 THEN "fair"
    WHEN roc_auc > .7 THEN "decent"
    WHEN roc_auc > .6 THEN "not great"
  ELSE "poor" END AS model_quality
FROM
  ML.EVALUATE(MODEL ecommerce.classification_model,  (

SELECT
  * EXCEPT(fullVisitorId)
FROM

  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN "20170501" AND "20170630")
  JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)

));'

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade With Us! 👇${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade With Us):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://youtube.com/@arcadewithus_we?si=yeEby5M3k40gdX4l${RESET_FORMAT}"
echo
