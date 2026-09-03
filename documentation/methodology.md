# Methodology

## Analytical Scope

This project uses descriptive and diagnostic business analytics to identify elevated-churn customer segments, prioritize retention activity and quantify customer-value concentration.

It is not a machine-learning churn prediction model.

## Data Pipeline

IBM Source Files  
→ PostgreSQL Staging  
→ Analytics Layer  
→ Reporting Views  
→ Power BI

## Churn Analysis

Customer churn rates were analyzed across contract type, tenure, monthly charges, service characteristics, satisfaction and customer-reported churn reasons.

Segment churn was compared with overall portfolio churn using churn-rate gaps and churn lift.

## Retention Priority

A transparent rule-based retention framework was developed using seven churn-associated signals combined with CLTV-based customer value.

Priority levels:

- P1 — Critical Retention
- P2 — Proactive Retention
- P3 — Monitor
- P4 — Stable / Loyalty

## Financial Analysis

Monthly Charge Base is treated as a billing-value proxy.

CLTV represents Customer Lifetime Value and should not be interpreted as guaranteed future revenue.

## Key Limitations

- The dataset represents a customer snapshot rather than a longitudinal time series.
- Associations do not prove causation.
- The source churn score was excluded from driver analysis to avoid target leakage.
- Retention Priority is a business prioritization framework, not predicted churn probability.
