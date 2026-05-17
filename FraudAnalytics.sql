

-- ============================================================
--  1. EXPLORATORY DATA ANALYSIS (EDA)
-- ============================================================

-- ----------------------------------------------------------
--  1.1  Dataset Overview
-- ----------------------------------------------------------

-- Row count and fraud label split
SELECT
    COUNT(*)                                                        AS total_transactions,
    SUM(fraud)                                                      AS fraud_count,
    COUNT(*) - SUM(fraud)                                           AS legit_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions;


SELECT
    SUM(CASE WHEN amount           IS NULL THEN 1 ELSE 0 END) AS null_amount,
    SUM(CASE WHEN currency         IS NULL THEN 1 ELSE 0 END) AS null_currency,
    SUM(CASE WHEN local_timestamp  IS NULL THEN 1 ELSE 0 END) AS null_timestamp,
    SUM(CASE WHEN payment_channel  IS NULL THEN 1 ELSE 0 END) AS null_channel,
    SUM(CASE WHEN ip_risk_score    IS NULL THEN 1 ELSE 0 END) AS null_ip_risk,
    SUM(CASE WHEN fraud            IS NULL THEN 1 ELSE 0 END) AS null_fraud
FROM fraud_transactions;


-- ----------------------------------------------------------
--  1.2  Numeric Feature Summary
-- ----------------------------------------------------------


SELECT
    ROUND(MIN(amount), 2)               AS min_amount,
    ROUND(MAX(amount), 2)               AS max_amount,
    ROUND(AVG(amount), 2)               AS avg_amount,
    ROUND(STDEV(amount), 2)             AS std_amount,
    ROUND(AVG(decline_rate_30d), 4)     AS avg_decline_rate,
    ROUND(AVG(credit_util_today), 4)    AS avg_credit_util,
    ROUND(AVG(CAST(chargebacks_365d AS DECIMAL(10,4))), 4) AS avg_chargebacks,
    ROUND(AVG(CAST(days_since_last_txn AS DECIMAL(10,1))), 1) AS avg_days_since_last_txn,
    ROUND(AVG(ip_risk_score), 4)        AS avg_ip_risk_score
FROM fraud_transactions;

-- Median and P95 
SELECT DISTINCT
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY amount)
        OVER () AS median_amount,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY amount)
        OVER () AS p95_amount
FROM fraud_transactions;


-- Amount distribution by bucket

SELECT
    amount_bucket,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM (
    SELECT
        fraud,
        CASE
            WHEN amount < 1000   THEN '1. < 1K'
            WHEN amount < 10000  THEN '2. 1K - 10K'
            WHEN amount < 50000  THEN '3. 10K - 50K'
            WHEN amount < 100000 THEN '4. 50K - 100K'
            ELSE '5. > 100K'
        END AS amount_bucket
    FROM fraud_transactions
) sub
GROUP BY amount_bucket
ORDER BY amount_bucket;


-- ----------------------------------------------------------
--  1.3  Categorical Feature Distribution
-- ----------------------------------------------------------

-- Payment channel breakdown
SELECT
    payment_channel,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY payment_channel
ORDER BY fraud_rate_pct DESC;


-- Card entry mode breakdown
SELECT
    card_entry_mode,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY card_entry_mode
ORDER BY fraud_rate_pct DESC;


-- Auth result breakdown
SELECT
    auth_result,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY auth_result
ORDER BY fraud_rate_pct DESC;


-- Terminal / location breakdown
SELECT
    term_location,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY term_location
ORDER BY fraud_rate_pct DESC;


-- Currency breakdown
SELECT
    currency,
    COUNT(*)                                                        AS txn_count,
    ROUND(AVG(amount), 2)                                           AS avg_amount,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY currency
ORDER BY fraud_rate_pct DESC;


-- ----------------------------------------------------------
--  1.4  Boolean Feature Fraud Rates
-- ----------------------------------------------------------

SELECT
    'card_present' AS feature,
    CASE WHEN card_present = 1 THEN 'true' ELSE 'false' END AS value,
    COUNT(*)                                                        AS txn_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY card_present

UNION ALL

SELECT
    'cross_border',
    CASE WHEN cross_border = 1 THEN 'true' ELSE 'false' END,
    COUNT(*),
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)
FROM fraud_transactions
GROUP BY cross_border

UNION ALL

SELECT
    'tokenised',
    CASE WHEN tokenised = 1 THEN 'true' ELSE 'false' END,
    COUNT(*),
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)
FROM fraud_transactions
GROUP BY tokenised

ORDER BY feature, value;


-- ----------------------------------------------------------
--  1.5  Time-Based EDA
-- ----------------------------------------------------------

-- Fraud by hour of day

SELECT
    DATEPART(HOUR, local_timestamp)                                 AS hour_of_day,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY DATEPART(HOUR, local_timestamp)
ORDER BY hour_of_day;


-- Fraud by day of week
SELECT
    DATENAME(WEEKDAY, local_timestamp)                              AS day_of_week,
    DATEPART(WEEKDAY, local_timestamp)                              AS dow_num,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY DATENAME(WEEKDAY, local_timestamp),
         DATEPART(WEEKDAY, local_timestamp)
ORDER BY dow_num;


-- Monthly fraud trend
SELECT
    DATEFROMPARTS(YEAR(local_timestamp), MONTH(local_timestamp), 1) AS month,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY DATEFROMPARTS(YEAR(local_timestamp), MONTH(local_timestamp), 1)
ORDER BY month;


-- ============================================================
--  2. IN-DEPTH FRAUD ANALYSIS
-- ============================================================

-- ----------------------------------------------------------
--  2.1  Fraud vs Legit: Feature Comparison
-- ----------------------------------------------------------

SELECT
    fraud,
    COUNT(*)                                                        AS txn_count,
    ROUND(AVG(amount), 2)                                           AS avg_amount,
    ROUND(AVG(ip_risk_score), 4)                                    AS avg_ip_risk,
    ROUND(AVG(decline_rate_30d), 4)                                 AS avg_decline_rate,
    ROUND(AVG(credit_util_today), 4)                                AS avg_credit_util,
    ROUND(AVG(CAST(chargebacks_365d AS DECIMAL(10,4))), 2)          AS avg_chargebacks,
    ROUND(AVG(CAST(days_since_last_txn AS DECIMAL(10,1))), 1)       AS avg_days_since_last_txn,
    ROUND(AVG(night_ratio_30d), 4)                                  AS avg_night_ratio,
    ROUND(AVG(online_share_7d), 4)                                  AS avg_online_share,
    ROUND(AVG(CAST(distinct_countries_30d AS DECIMAL(10,2))), 2)    AS avg_distinct_countries,
    ROUND(AVG(CAST(device_diversity_30d AS DECIMAL(10,2))), 2)      AS avg_device_diversity,
    ROUND(AVG(mcc_entropy_30d), 4)                                  AS avg_mcc_entropy
FROM fraud_transactions
GROUP BY fraud
ORDER BY fraud;


-- ----------------------------------------------------------
--  2.2  High-Risk Channel x Auth Combinations
-- ----------------------------------------------------------

SELECT TOP 20
    payment_channel,
    auth_result,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct,
    ROUND(AVG(amount), 2)                                           AS avg_amount
FROM fraud_transactions
GROUP BY payment_channel, auth_result
HAVING COUNT(*) > 50
ORDER BY fraud_rate_pct DESC;


-- ----------------------------------------------------------
--  2.3  Cross-Border + Card-Not-Present Risk Matrix
-- ----------------------------------------------------------

SELECT
    cross_border,
    card_present,
    tokenised,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct,
    ROUND(AVG(amount), 2)                                           AS avg_amount,
    ROUND(AVG(ip_risk_score), 4)                                    AS avg_ip_risk
FROM fraud_transactions
GROUP BY cross_border, card_present, tokenised
ORDER BY fraud_rate_pct DESC;


-- ----------------------------------------------------------
--  2.4  Behavioral Signals: Decline Rate & Chargebacks
-- ----------------------------------------------------------

-- Fraud rate by decline rate band
SELECT
    decline_band,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM (
    SELECT
        fraud,
        CASE
            WHEN decline_rate_30d = 0    THEN '1. 0%'
            WHEN decline_rate_30d < 0.10 THEN '2. < 10%'
            WHEN decline_rate_30d < 0.25 THEN '3. 10-25%'
            WHEN decline_rate_30d < 0.50 THEN '4. 25-50%'
            ELSE '5. >= 50%'
        END AS decline_band
    FROM fraud_transactions
) sub
GROUP BY decline_band
ORDER BY decline_band;


-- Fraud rate by prior chargeback count
SELECT
    chargebacks_365d,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM fraud_transactions
GROUP BY chargebacks_365d
ORDER BY chargebacks_365d;


-- ----------------------------------------------------------
--  2.5  IP Risk Score Distribution
-- ----------------------------------------------------------

SELECT
    ip_risk_band,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct,
    ROUND(AVG(amount), 2)                                           AS avg_amount
FROM (
    SELECT
        fraud, amount,
        CASE
            WHEN ip_risk_score < 0.20 THEN '1. 0.00-0.20 (Low)'
            WHEN ip_risk_score < 0.40 THEN '2. 0.20-0.40 (Medium-Low)'
            WHEN ip_risk_score < 0.60 THEN '3. 0.40-0.60 (Medium)'
            WHEN ip_risk_score < 0.80 THEN '4. 0.60-0.80 (Medium-High)'
            ELSE '5. 0.80-1.00 (High)'
        END AS ip_risk_band
    FROM fraud_transactions
) sub
GROUP BY ip_risk_band
ORDER BY ip_risk_band;


-- ----------------------------------------------------------
--  2.6  Device & Merchant Concentration
-- ----------------------------------------------------------

-- Devices used in the most fraud transactions
SELECT TOP 20
    device_id,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct,
    ROUND(AVG(amount), 2)                                           AS avg_amount
FROM fraud_transactions
GROUP BY device_id
HAVING SUM(fraud) > 0
ORDER BY fraud_count DESC;


-- Merchants with the highest fraud exposure
SELECT TOP 20
    merchant_id,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct,
    ROUND(SUM(amount * fraud), 2)                                   AS total_fraud_amount
FROM fraud_transactions
GROUP BY merchant_id
HAVING SUM(fraud) > 0
ORDER BY total_fraud_amount DESC;


-- ----------------------------------------------------------
--  2.7  MCC (Merchant Category Code) Fraud Rates
-- ----------------------------------------------------------

SELECT TOP 20
    mcc,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct,
    ROUND(AVG(mcc_entropy_30d), 4)                                  AS avg_mcc_entropy,
    ROUND(SUM(amount * fraud), 2)                                   AS total_fraud_amount
FROM fraud_transactions
GROUP BY mcc
HAVING COUNT(*) > 100
ORDER BY fraud_rate_pct DESC;


-- ----------------------------------------------------------
--  2.8  Card Activation Age vs Fraud
-- ----------------------------------------------------------

SELECT
    card_age_band,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM (
    SELECT
        fraud,
        CASE
            WHEN card_activation_age < 7   THEN '1. < 1 week (new card)'
            WHEN card_activation_age < 30  THEN '2. 1-4 weeks'
            WHEN card_activation_age < 90  THEN '3. 1-3 months'
            WHEN card_activation_age < 365 THEN '4. 3-12 months'
            ELSE '5. > 1 year'
        END AS card_age_band
    FROM fraud_transactions
) sub
GROUP BY card_age_band
ORDER BY card_age_band;


-- ----------------------------------------------------------
--  2.9  Credit Utilisation & Spending Trend
-- ----------------------------------------------------------

SELECT
    util_band,
    spend_direction,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct
FROM (
    SELECT
        fraud,
        CASE
            WHEN credit_util_today < 0.25 THEN '1. 0-25%'
            WHEN credit_util_today < 0.50 THEN '2. 25-50%'
            WHEN credit_util_today < 0.75 THEN '3. 50-75%'
            ELSE '4. 75-100%+'
        END AS util_band,
        CASE
            WHEN spending_trend > 0 THEN 'Increasing'
            WHEN spending_trend = 0 THEN 'Flat'
            ELSE 'Decreasing'
        END AS spend_direction
    FROM fraud_transactions
) sub
GROUP BY util_band, spend_direction
ORDER BY fraud_rate_pct DESC;


-- ----------------------------------------------------------
--  2.10  Composite High-Risk Segment
-- ----------------------------------------------------------

SELECT TOP 25
    cross_border,
    card_present,
    auth_result,
    card_entry_mode,
    CASE WHEN ip_risk_score >= 0.6  THEN 'HIGH' ELSE 'LOW-MED' END AS ip_risk_tier,
    CASE WHEN decline_rate_30d >= 0.25 THEN 'HIGH' ELSE 'NORMAL' END AS decline_tier,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS fraud_count,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct,
    ROUND(SUM(amount * fraud), 2)                                   AS total_fraud_exposure
FROM fraud_transactions
GROUP BY
    cross_border, card_present, auth_result, card_entry_mode,
    CASE WHEN ip_risk_score >= 0.6  THEN 'HIGH' ELSE 'LOW-MED' END,
    CASE WHEN decline_rate_30d >= 0.25 THEN 'HIGH' ELSE 'NORMAL' END
HAVING COUNT(*) > 20
ORDER BY fraud_rate_pct DESC;


-- ============================================================
--  3. FRAUD RISK SCORING (Rule-Based)
-- ============================================================

WITH scored AS (
    SELECT
        txn_id,
        fraud,
        amount,
        payment_channel,
        auth_result,

        CASE WHEN cross_border = 0      THEN 1 ELSE 0 END           AS s_cross_border,
        CASE WHEN card_present = 0      THEN 1 ELSE 0 END           AS s_card_not_present,
        CASE WHEN tokenised = 0         THEN 1 ELSE 0 END           AS s_not_tokenised,
        CASE WHEN ip_risk_score >= 0.60 THEN 2
             WHEN ip_risk_score >= 0.40 THEN 1 ELSE 0 END           AS s_ip_risk,
        CASE WHEN decline_rate_30d >= 0.50 THEN 2
             WHEN decline_rate_30d >= 0.25 THEN 1 ELSE 0 END        AS s_decline_rate,
        CASE WHEN chargebacks_365d >= 2 THEN 2
             WHEN chargebacks_365d  = 1 THEN 1 ELSE 0 END           AS s_chargebacks,
        CASE WHEN auth_result IN ('3DS_FAIL','CVV_FAIL',
                                  'AVS_FAIL','BIOMETRIC_FAIL')
             THEN 2 ELSE 0 END                                      AS s_auth_fail,
        CASE WHEN card_activation_age < 7  THEN 2
             WHEN card_activation_age < 30 THEN 1 ELSE 0 END        AS s_new_card,
        CASE WHEN device_diversity_30d >= 3 THEN 1 ELSE 0 END       AS s_device_diversity,
        CASE WHEN distinct_countries_30d >= 3 THEN 2
             WHEN distinct_countries_30d  = 2 THEN 1 ELSE 0 END     AS s_country_diversity,
        CASE WHEN amount > mean_amount_30d + 2 * std_amount_30d
             THEN 2 ELSE 0 END                                      AS s_amount_spike,
        CASE WHEN night_ratio_30d >= 0.60 THEN 1 ELSE 0 END         AS s_night_heavy,
        CASE WHEN credit_util_today >= 0.80 THEN 1 ELSE 0 END       AS s_high_util
    FROM fraud_transactions
),
risk_score AS (
    SELECT *,
        s_cross_border + s_card_not_present + s_not_tokenised +
        s_ip_risk + s_decline_rate + s_chargebacks + s_auth_fail +
        s_new_card + s_device_diversity + s_country_diversity +
        s_amount_spike + s_night_heavy + s_high_util                AS total_risk_score
    FROM scored
),
tiered AS (
    SELECT *,
        CASE
            WHEN total_risk_score >= 10 THEN 'CRITICAL'
            WHEN total_risk_score >= 6  THEN 'HIGH'
            WHEN total_risk_score >= 3  THEN 'MEDIUM'
            ELSE 'LOW'
        END AS risk_tier
    FROM risk_score
)
SELECT
    risk_tier,
    COUNT(*)                                                        AS txn_count,
    SUM(fraud)                                                      AS actual_fraud,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct,
    ROUND(AVG(CAST(total_risk_score AS DECIMAL(10,2))), 2)          AS avg_risk_score,
    ROUND(AVG(amount), 2)                                           AS avg_amount,
    ROUND(SUM(amount * fraud), 2)                                   AS total_fraud_exposure
FROM tiered
GROUP BY risk_tier
ORDER BY MIN(total_risk_score) DESC;



-- ============================================================
--  4. WINDOW FUNCTION ANALYSIS
-- ============================================================

-- ----------------------------------------------------------
--  4.1  Running fraud totals over time
-- ----------------------------------------------------------


WITH daily AS (
    SELECT
        CAST(local_timestamp AS DATE)                               AS txn_date,
        COUNT(*)                                                    AS daily_txns,
        SUM(fraud)                                                  AS daily_fraud
    FROM fraud_transactions
    GROUP BY CAST(local_timestamp AS DATE)
)
SELECT
    txn_date,
    daily_txns,
    daily_fraud,
    SUM(daily_fraud) OVER (ORDER BY txn_date)                       AS cumulative_fraud,
    ROUND(AVG(CAST(daily_fraud AS DECIMAL(10,2))) OVER (
        ORDER BY txn_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2)                                                           AS fraud_7d_moving_avg
FROM daily
ORDER BY txn_date;


-- ----------------------------------------------------------
--  4.2  Percentile rank of each transaction's amount
--        within its payment channel (anomaly detection)
-- ----------------------------------------------------------


SELECT TOP 50
    txn_id,
    payment_channel,
    amount,
    fraud,
    ROUND(PERCENT_RANK() OVER (
        PARTITION BY payment_channel ORDER BY amount
    ) * 100, 1)                                                     AS amount_pct_rank_in_channel,
    ROUND(AVG(amount) OVER (
        PARTITION BY payment_channel
    ), 2)                                                           AS channel_avg_amount
FROM fraud_transactions
WHERE fraud = 1
ORDER BY amount_pct_rank_in_channel DESC;


-- ----------------------------------------------------------
--  4.3  Merchant fraud ranking (within each country)
-- ----------------------------------------------------------

SELECT TOP 50
    merchant_country,
    merchant_id,
    txn_count,
    fraud_count,
    fraud_rate_pct,
    RANK() OVER (
        PARTITION BY merchant_country ORDER BY fraud_rate_pct DESC
    )                                                               AS rank_in_country
FROM (
    SELECT
        merchant_country,
        merchant_id,
        COUNT(*)                                                    AS txn_count,
        SUM(fraud)                                                  AS fraud_count,
        ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2) AS fraud_rate_pct
    FROM fraud_transactions
    GROUP BY merchant_country, merchant_id
    HAVING COUNT(*) > 30
) sub
ORDER BY merchant_country, rank_in_country;

-- ============================================================
--  5. SUMMARY VIEW
-- ============================================================


CREATE OR ALTER VIEW vw_fraud_kpis AS
SELECT
    COUNT(*)                                                        AS total_txns,
    SUM(fraud)                                                      AS total_fraud,
    ROUND(CAST(SUM(fraud) AS DECIMAL(15,4)) / COUNT(*) * 100, 2)   AS fraud_rate_pct,
    ROUND(SUM(amount), 2)                                           AS total_volume,
    ROUND(SUM(amount * fraud), 2)                                   AS total_fraud_exposure,
    ROUND(AVG(CASE WHEN fraud = 1 THEN amount END), 2)              AS avg_fraud_amount,
    ROUND(AVG(CASE WHEN fraud = 0 THEN amount END), 2)              AS avg_legit_amount,
    ROUND(AVG(ip_risk_score), 4)                                    AS avg_ip_risk_score,
    SUM(CASE WHEN cross_border = 1  AND fraud = 1 THEN 1 ELSE 0 END) AS cross_border_frauds,
    SUM(CASE WHEN card_present = 0  AND fraud = 1 THEN 1 ELSE 0 END) AS cnp_frauds
FROM fraud_transactions;

GO

SELECT * FROM vw_fraud_kpis;


