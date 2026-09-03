# Customer Churn, Retention & Revenue Risk Analysis

**PostgreSQL | SQL | Power BI | DAX | Business Analytics**

An end-to-end customer analytics project using the IBM Telco Customer Churn dataset to analyze churn behavior, identify retention priorities and quantify customer-value exposure across 7,043 customers.

## Project Objectives

The project addresses three key business questions:

1. Where is customer churn concentrated?
2. Which existing customers should receive retention attention?
3. How much customer value is associated with priority retention segments?

## Key Findings

- Overall customer churn rate: **26.5%**
- **1,869** customers churned from a portfolio of **7,043**
- Month-to-month customers showed substantially higher churn than longer-term contract customers
- Churn fell from approximately **53.3%** among customers with 0–6 months tenure to **9.5%** among customers with 49+ months tenure
- Customers without Premium Tech Support recorded approximately **31.2% churn**, compared with **15.2%** among customers with support
- **1,070** existing customers were classified as P1/P2 retention priorities
- **560** customers were classified as High-Value At-Risk
- P1/P2 customers represented **22.7%** of existing customers but **26.9% of existing-customer CLTV**
- High-Value At-Risk customers represented approximately **$3.0M in CLTV**

## Dashboard

### 1. Executive Churn Overview

![Executive Churn Overview](https://github.com/mdjamiulislam/customer-churn-retention-analysis/blob/main/01_executive_overview.png)

### 2. Churn Drivers

![Churn Drivers](https://github.com/mdjamiulislam/customer-churn-retention-analysis/blob/main/02_churn_drivers.png)

### 3. Customer Segmentation & Retention Priority

![Retention Priority](https://github.com/mdjamiulislam/customer-churn-retention-analysis/blob/main/03_retention_priority.png)

### 4. Revenue & Retention Risk

![Revenue and Retention Risk](https://github.com/mdjamiulislam/customer-churn-retention-analysis/blob/main/04_revenue_retention_risk.png)

### 5. Data Quality & Methodology

![Data Quality and Methodology](https://github.com/mdjamiulislam/customer-churn-retention-analysis/blob/main/05_data_quality_methodology.png)

## Technical Architecture

```text
IBM Enhanced Telco Dataset
          ↓
PostgreSQL Staging Layer
          ↓
Data Profiling & Validation
          ↓
Clean Analytics Layer
          ↓
Business KPI & Churn Analysis
          ↓
Retention Segmentation
          ↓
Financial Exposure Analysis
          ↓
Power BI Reporting Layer
          ↓
Interactive Power BI Dashboard


This demonstrates that the project was much more than dashboard building.

---

# 15. Add SQL workflow

Use:

```markdown
## SQL Workflow

| Script | Purpose |
|---|---|
| `01_database_setup.sql` | Database schemas and staging tables |
| `02_ingestion_validation.sql` | Import and source reconciliation |
| `03_data_profiling.sql` | Data-quality audit |
| `04_create_analytics_layer.sql` | Cleaning and transformation |
| `05_core_kpis.sql` | Executive KPI calculations |
| `06_churn_driver_analysis.sql` | Churn-rate and churn-lift analysis |
| `07_retention_segmentation.sql` | Retention prioritization framework |
| `08_revenue_value_risk_analysis.sql` | Financial and CLTV analysis |
| `09_powerbi_reporting_layer.sql` | Power BI-ready reporting views |


## Skills Demonstrated

- PostgreSQL database design
- SQL data profiling and validation
- Data cleaning and transformation
- CTEs and window functions
- Aggregations and business KPIs
- Churn-rate and churn-lift analysis
- Customer segmentation
- CLTV analysis
- Retention prioritisation
- Power BI data modelling
- DAX measures
- Interactive dashboard development
- Data-quality reconciliation
- Business storytelling

## Methodology Note

The retention-priority framework is a transparent rule-based business prioritisation model rather than a machine-learning churn prediction model.

Churn-driver findings represent historical associations and should not be interpreted as proof of causality.

Monthly Charge Base is used as a billing-value proxy, while CLTV represents customer lifetime value rather than guaranteed future revenue.

