# 🔍 Fraud Risk Intelligence 

> End-to-end fraud analysis project covering SQL-based EDA, in-depth behavioural analysis, rule-based risk scoring, and a two-page Power BI dashboard. 

---

## 📁 Project Files

| File | Description |
|---|---|
| `Topic_2_fraud_dataset.xlsx` | Raw dataset — 76,017 transactions, 36 columns |
| `fraud_analysis_sqlserver.sql` | Full SQL Server analysis script |
| `fraud_powerbi_dashboard.html` | Power BI dashboard mockup (2 pages) |
| `dashboard_calculations_explained.html` | Every number and DAX measure explained |
| `fraud_storytelling.html` | Investigative narrative of findings |

---

## 📊 Dataset Overview

| Property | Value |
|---|---|
| Total rows | 76,017 |
| Total columns | 36 |
| Null values | 0 |
| Fraud cases | 1,931 |
| Baseline fraud rate | 2.54% |
| Channels | 7 (POS, ATM, Mobile App, Web Browser, Smartwatch, IVR, API) |
| Currencies | 10 (USD, EUR, GBP, AUD, JPY, VND, INR, and others) |
| Countries | 15 |
| Date type | Synthetic / simulated dataset |

### Column Types

| Category | Columns |
|---|---|
| Transaction identifiers | `device_id`, `merchant_id`, `mcc` |
| Transaction details | `amount`, `currency`, `local_timestamp`, `payment_channel`, `merchant_country` |
| Card & auth | `card_present`, `card_entry_mode`, `auth_result`, `tokenised`, `pin_verif_method`, `auth_characteristics`, `message_type`, `recurring_flag` |
| Risk flags | `cross_border`, `ip_risk_score`, `card_activation_age` |
| Customer statistics (30d/7d) | `mean_amount_30d`, `std_amount_30d`, `max_amount_30d`, `decline_rate_30d`, `night_ratio_30d`, `online_share_7d`, `device_diversity_30d`, `mcc_entropy_30d`, `txn_count_recent`, `txn_count_total`, `distinct_merchants_7d` |
| Customer statistics (365d) | `chargebacks_365d` |
| Other | `distinct_countries_30d`, `days_since_last_txn`, `credit_util_today`, `spending_trend`, `term_location` |
| Target | `fraud` (0 = legitimate, 1 = fraud) |

### ⚠️ Data Notes

**`ip_risk`** — Stored as a JSON-like string in the raw file e.g. `{'ip': '209.31.165.203', 'score': 0.3581}`. The numeric score must be extracted at import time using Power Query M or SQL string parsing before use.

**`txn_counts`** — Stored as a tuple string e.g. `(13, 401)`. Must be split into two separate integer columns (`txn_count_recent`, `txn_count_total`) at import time.

---

## 🗄️ SQL Analysis — `fraud_analysis_sqlserver.sql`

Written in **SQL Server** syntax. Full breakdown of all sections:

### Section 0 — Table Creation
- Full `CREATE TABLE` with correct SQL Server data types
- `IDENTITY(1,1)` primary key replacing PostgreSQL `SERIAL`
- `BIT` columns for all booleans (`card_present`, `tokenised`, `cross_border`)
- `DATETIME2` for timestamp, `DECIMAL` for all numeric columns
- Import notes for `ip_risk` and `txn_counts` compound string columns

### Section 1 — Exploratory Data Analysis (EDA)
- **1.1** Dataset overview — row count, fraud split, fraud rate
- **1.2** Numeric feature summary — min, max, avg, stddev, median (P50), P95
- **1.3** Categorical breakdowns — payment channel, card entry mode, auth result, terminal location, currency (all with fraud rate per group)
- **1.4** Boolean feature fraud rates — `card_present`, `cross_border`, `tokenised`
- **1.5** Time-based EDA — fraud rate by hour of day, day of week, monthly trend

### Section 2 — In-Depth Analysis
- **2.1** Fraud vs legit feature comparison — avg behavioural signals side by side
- **2.1b** `distinct_countries_30d` — correct categorical usage (fraud rate by country code)
- **2.2** High-risk channel × auth result combinations
- **2.3** Cross-border + card-not-present + tokenised risk matrix
- **2.4** Decline rate bands + chargeback count vs fraud rate
- **2.5** IP risk score distribution bands
- **2.6** Top fraud devices and merchants by exposure
- **2.7** MCC fraud rates
- **2.8** Card activation age bands
- **2.9** Credit utilisation × spending trend grid
- **2.10** Composite high-risk segment (multi-signal combination)

### Section 3 — Rule-Based Risk Scoring
Assigns each transaction an additive risk score (0–18) across **12 signals**:

| Signal | Max Points | Logic |
|---|---|---|
| Cross-border = FALSE | 1 | Domestic = higher risk |
| Card not present | 1 | No physical card |
| Not tokenised | 1 | Raw card number transmitted |
| IP risk score | 0–2 | ≥ 0.6 = 2pts, ≥ 0.4 = 1pt |
| Decline rate | 0–2 | ≥ 0.5 = 2pts, ≥ 0.25 = 1pt |
| Chargebacks | 0–2 | ≥ 2 = 2pts, = 1 = 1pt |
| Auth failure | 0–2 | Any FAIL result = 2pts |
| New card | 0–2 | < 7 days = 2pts, < 30 days = 1pt |
| Device diversity | 0–1 | ≥ 3 devices = 1pt |
| Amount spike | 0–2 | > mean + 2×std = 2pts |
| Night ratio | 0–1 | < 0.60 night ratio = 1pt |
| High credit util | 0–1 | ≥ 0.80 utilisation = 1pt |

> **Note:** `distinct_countries_30d` was removed from scoring as it is a categorical country code, not a numeric count.

Transactions are tiered:

| Tier | Score | Est. Fraud Rate |
|---|---|---|
| CRITICAL | ≥ 10 | ~8.5% |
| HIGH | 6–9 | ~5.2% |
| MEDIUM | 3–5 | ~2.4% |
| LOW | 0–2 | ~0.8% |

### Section 4 — Window Function Analysis
- **4.1** Running cumulative fraud totals + 7-day moving average over time
- **4.2** `PERCENT_RANK()` of each fraud transaction's amount within its payment channel
- **4.3** `RANK()` of merchants by fraud rate within each country

### Section 5 — Summary View
`CREATE OR ALTER VIEW vw_fraud_kpis` — single-row executive summary with total volume, fraud exposure, avg amounts, cross-border fraud count, and card-not-present fraud count.

---

## 📈 Power BI Dashboard

Two-page dashboard built with DAX measures and calculated columns.

### Page 1 — EDA Overview
| Visual | Type | Key Finding |
|---|---|---|
| 5× KPI tiles | Card | 76,017 txns · 1,931 fraud · 2.54% rate · $189.3M exposure |
| Fraud rate by hour | Line chart | Peak at 1am (3.05%) |
| Fraud rate by channel | Bar chart | POS highest (2.84%), IVR lowest (2.38%) |
| Fraud/Legit split | Donut | 2.54% fraud |
| Fraud rate by amount | Bar chart | Inverse — smaller = higher fraud rate |
| Fraud rate by card entry mode | Bar chart | Magstripe highest (2.74%) |
| Boolean risk factors | Table | Cross-border LOWER fraud (1.98% vs 2.68%) |
| Fraud rate by currency | Bar chart | VND highest (3.30%), JPY lowest (1.96%) |
| Card activation age | Bar chart | 1–4 week new cards safest (0.54%) |
| Top countries | Table | FR (3.18%), CA (2.95%), PH (2.94%) |

### Page 2 — In-Depth Analysis
| Visual | Type | Key Finding |
|---|---|---|
| 5× KPI tiles | Card | Behavioural signal comparisons fraud vs legit |
| Decline rate vs amount | Scatter | Fraud clusters at low decline rate across all amounts |
| Decline rate band | Bar chart | Low decline = highest fraud (3.87%) |
| Auth result heatmap | Matrix + conditional format | 3DS_PASS highest (2.67%), BIOMETRIC_PASS lowest (2.31%) |
| Risk tier | Treemap | CRITICAL tier = 8.5% fraud rate |
| Device diversity | Bar chart | Fewer devices = higher fraud — closes unified narrative |

### Key DAX Measures

```dax
-- Core
Total Transactions = COUNTROWS(fraud_transactions)
Fraud Count        = SUM(fraud_transactions[fraud])
Fraud Rate %       = DIVIDE([Fraud Count], [Total Transactions]) * 100
Fraud Exposure     = CALCULATE(SUM([amount]), [fraud] = 1)

-- Behavioural comparisons
Avg Night Ratio Fraud = CALCULATE(AVERAGE([night_ratio_30d]), [fraud] = 1)
Avg Night Ratio Legit = CALCULATE(AVERAGE([night_ratio_30d]), [fraud] = 0)

-- Bucketing (calculated columns)
Amount Bucket   = SWITCH(TRUE(), [amount] < 1000, "1. < $1K", ...)
Card Age Bucket = SWITCH(TRUE(), [card_activation_age] < 7, "1. < 1 Week", ...)
Decline Band    = SWITCH(TRUE(), [decline_rate_30d] < 0.10, "2. < 10%", ...)
Risk Score      = IF([cross_border]=FALSE(),1,0) + IF([card_present]=FALSE(),1,0) + ...
Risk Tier       = SWITCH(TRUE(), [Risk Score] >= 10, "CRITICAL", ...)
```

---

## 🔑 Key Findings

### Counter-Intuitive Discoveries
| Assumption | Reality |
|---|---|
| Cross-border = riskier | Cross-border fraud rate is **LOWER** (1.98% vs 2.68%) |
| High IP risk = suspicious | IP score is **identical** for fraud and legit (0.2857 vs 0.2859) |
| High decline rate = risky | Fraud accounts have **fewer** declines (14.0% vs 16.7%) |
| Fraud happens at night | Fraud is a **daytime** operation (26.6% vs 50.6% night ratio) |
| 3DS = secure | 3DS_PASS has **higher** fraud rate than BIOMETRIC_FAIL |

### Strongest Predictive Signals
1. **Night ratio** — 47% lower in fraud accounts
2. **Decline rate** — 16% lower in fraud accounts (counter-intuitive direction)
3. **Chargebacks** — 7% higher in fraud accounts (only signal in expected direction)
4. **Card activation age** — 1–4 week cards have 0.54% fraud rate (safest)
5. **Multi-signal score** — CRITICAL tier reaches 8.5%, 3× the 2.54% baseline

### Unified Conclusion
> Fraud in this dataset is characterised by **suspicious normalcy**. Fraudsters operate locally, during business hours, on consistent devices, with clean credential histories. They pass authentication checks and blend into normal transaction patterns. Single-variable rules miss them. Multi-signal scoring finds them.

---

---

*Topic 2 — Risk Management Application · Fraud Dataset · 76,017 transactions · 36 features*
