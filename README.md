# Boreas Auto Finance– Portfolio Risk Analytics
An end-to-end automotive loans analytics project leveraging Python, MySQL, and Power BI to assess portfolio health, repayment trends, and collection efficiency during the business-managed lifecycle.

## Overview

This project is an end-to-end analytical solution for  **Boreas Auto Finance** with a focus on **repayment behavior, overdue trends, and business-team risk visibility** during the initial phase of a loan’s lifecycle.
The objective is to provide **clear, actionable insights** for monitoring portfolio health, identifying risk concentration, and supporting data-driven operational decisions.

The analysis spans **January 2023 to November 2024** and integrates **Python (EDA & feature engineering), MySQL (analytical queries), and Power BI (interactive dashboards)**.

---

## Business Context

* Repayment responsibility remains with the **business team during the initial loan lifecycle** before transfer to collections.
* Limited consolidated visibility made it difficult to:

  * Track collection efficiency over time
  * Monitor overdue and DPD trends
  * Identify high-risk managers, branches, and sourcing channels
  * Assess whether loan tenure influences repayment behavior

This project addresses these gaps through structured analysis and dashboards.

---


## Data & Assumptions

* Dataset is **synthetic and generated for analytical demonstration**.
* Covers **repayment activity for ~680 days** (Jan 2023 – Nov 2024).
* Each contract has a **fixed monthly due date** (5th, 10th, or 15th).
* Actual payment dates are not available; repayments (with or without DPD) are assumed to occur **only on the scheduled due date**.
* Extreme values are treated as **valid high-exposure cases**, not data errors.

---

## Key Analytical Components

### Python (EDA & Feature Engineering)

* Data validation (nulls, uniqueness, record grain)
* Channel classification (Dealer / Broker / Self)
* DPD bucket creation
* EMI-sequence behavior analysis
* Tenure vs DPD bucket correlation assessment
* Monthly DPD trend analysis

### MySQL (Analytical Queries)

* Rolling 3-month trends for:

  * Overdue amount
  * DPD days
  * Amount recovered
* Concentration analysis (top contributors by dealer, broker, branch)
* EMI bounce behavior by due date
* State-wise and branch-wise recovery patterns

### Power BI (Dashboards)

* **Portfolio Health**: Financed amount, overdue, PSL %, LTV, collection efficiency
* **Risk & Repayment Behavior**: DPD buckets, NPA %, overdue trends, high-risk branches
* **Manager & Channel Oversight**: Portfolio quality, risk concentration, track records

---

## High-Level Insights

* Portfolio stress is driven by a **limited subset of contracts**, not the entire base.
* Repayment pressure increases **after early EMIs**, highlighting lifecycle risk.
* Certain sourcing channels and managers show **disproportionate overdue exposure**.
* Recovery trends weakened toward late 2024, requiring closer operational monitoring.
* Track-record classification enables **forward-looking underwriting and monitoring controls**.

---

## Tools Used

* **Python**: pandas, numpy, matplotlib, SQLAlchemy
* **SQL**: MySQL (window functions, ranking, rolling trends)
* **Visualization**: Power BI

---

## How to view:

1. View `boras_auto_finance_EDA.ipynb` for data preparation and exploratory analysis.
2. Run `boreas_auto_finance.sql` to recreate schema and analytical queries.
3. View `Boreas_Auto_Finance_report.pdf` for consolidated insights and dashboard interpretations.

---

## Disclaimer

This project is created for **learning and portfolio demonstration purposes only**.
All data is synthetic and does not represent any real individual, institution, or financial entity.

---

