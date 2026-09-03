/* =========================================================
   PROJECT 3: CUSTOMER CHURN, RETENTION & REVENUE RISK
   SCRIPT: 08_revenue_value_risk_analysis.sql

   PURPOSE:
   1. Analyse monthly charge concentration.
   2. Analyse historical revenue distribution.
   3. Analyse CLTV concentration.
   4. Quantify value associated with retention priorities.
   5. Quantify high-value retention exposure.
   6. Analyse the financial profile of historical churn.
   7. Create Power BI-ready financial reporting views.

   IMPORTANT TERMINOLOGY:

   monthly_charge
   = monthly billing-value proxy

   total_revenue
   = historical/cumulative revenue field

   CLTV
   = customer lifetime value measure

   Priority exposure does NOT represent guaranteed
   future revenue loss.

   SOURCE:
   analytics.customer_churn_clean
   reporting.vw_retention_customer_priority

   OUTPUT VIEWS:
   reporting.vw_financial_risk_kpis
   reporting.vw_retention_financial_by_priority
   reporting.vw_retention_financial_by_segment
   reporting.vw_churn_financial_impact
   reporting.vw_retention_value_exposure
   ========================================================= */


/* =========================================================
   SECTION 1
   VALIDATE CUSTOMER BASE
   ========================================================= */

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM analytics.customer_churn_clean;


/* Expected:
   7043
   7043
*/


/* =========================================================
   SECTION 2
   PORTFOLIO FINANCIAL BASELINE
   ========================================================= */

SELECT

    COUNT(*) AS customers,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS total_monthly_charge_base,

    ROUND(
        SUM(total_revenue),
        2
    ) AS total_historical_revenue,

    ROUND(
        AVG(total_revenue),
        2
    ) AS avg_historical_revenue_per_customer,

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 3
   MONTHLY CHARGE BY CHURN STATUS
   ========================================================= */

SELECT

    CASE
        WHEN churn_value = 1 THEN 'Churned'
        WHEN churn_value = 0 THEN 'Not Churned'
        ELSE 'Unknown'
    END AS churn_status,

    COUNT(*) AS customers,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        100.0 *
        SUM(monthly_charge)
        /
        NULLIF(
            SUM(SUM(monthly_charge)) OVER (),
            0
        ),
        2
    ) AS monthly_charge_share_pct

FROM analytics.customer_churn_clean

GROUP BY churn_value

ORDER BY churn_value;


/* =========================================================
   SECTION 4
   HISTORICAL REVENUE BY CUSTOMER STATUS
   ========================================================= */

SELECT
    customer_status,

    COUNT(*) AS customers,

    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue,

    ROUND(
        AVG(total_revenue),
        2
    ) AS avg_revenue_per_customer,

    ROUND(
        100.0 *
        SUM(total_revenue)
        /
        NULLIF(
            SUM(SUM(total_revenue)) OVER (),
            0
        ),
        2
    ) AS historical_revenue_share_pct

FROM analytics.customer_churn_clean

GROUP BY customer_status

ORDER BY historical_revenue DESC;


/* =========================================================
   SECTION 5
   CLTV BY CUSTOMER STATUS
   ========================================================= */

SELECT
    customer_status,

    COUNT(*) AS customers,

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,

    ROUND(
        100.0 *
        SUM(cltv)
        /
        NULLIF(
            SUM(SUM(cltv)) OVER (),
            0
        ),
        2
    ) AS cltv_share_pct

FROM analytics.customer_churn_clean

GROUP BY customer_status

ORDER BY total_cltv DESC;


/* =========================================================
   SECTION 6
   CUSTOMER VALUE SEGMENT FINANCIAL PROFILE
   ========================================================= */

SELECT
    customer_value_segment,
    customer_value_segment_sort,

    COUNT(*) AS customers,

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ) AS churned_customers,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE churn_value = 1
        )
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,

    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue

FROM analytics.customer_churn_clean

GROUP BY
    customer_value_segment,
    customer_value_segment_sort

ORDER BY customer_value_segment_sort;


/* =========================================================
   SECTION 7
   HIGH + VERY HIGH VALUE CUSTOMER PROFILE
   ========================================================= */

SELECT

    COUNT(*) AS high_value_customers,

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ) AS high_value_churned_customers,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE churn_value = 1
        )
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS high_value_churn_rate_pct,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS high_value_monthly_charge_base,

    ROUND(
        SUM(cltv),
        2
    ) AS high_value_total_cltv,

    ROUND(
        SUM(total_revenue),
        2
    ) AS high_value_historical_revenue

FROM analytics.customer_churn_clean

WHERE customer_value_segment IN (
    'High Value',
    'Very High Value'
);


/* =========================================================
   SECTION 8
   FINANCIAL PROFILE BY RETENTION PRIORITY
   EXISTING CUSTOMERS ONLY
   ========================================================= */

SELECT
    retention_priority,
    retention_priority_sort,

    COUNT(*) AS customers,

    ROUND(
        100.0 *
        COUNT(*)
        /
        NULLIF(
            SUM(COUNT(*)) OVER (),
            0
        ),
        2
    ) AS customer_share_pct,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        100.0 *
        SUM(monthly_charge)
        /
        NULLIF(
            SUM(SUM(monthly_charge)) OVER (),
            0
        ),
        2
    ) AS monthly_charge_share_pct,

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,

    ROUND(
        100.0 *
        SUM(cltv)
        /
        NULLIF(
            SUM(SUM(cltv)) OVER (),
            0
        ),
        2
    ) AS cltv_share_pct,

    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue

FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Stayed'

GROUP BY
    retention_priority,
    retention_priority_sort

ORDER BY retention_priority_sort;


/* =========================================================
   SECTION 9
   P1 + P2 PRIORITY RETENTION POPULATION
   ========================================================= */

SELECT

    COUNT(*) AS priority_retention_customers,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,

    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue

FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Stayed'

AND retention_priority IN (
    'P1 - Critical Retention',
    'P2 - Proactive Retention'
);


/* =========================================================
   SECTION 10
   P1 + P2 SHARE OF EXISTING CUSTOMER BASE
   ========================================================= */

SELECT

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE retention_priority IN (
                'P1 - Critical Retention',
                'P2 - Proactive Retention'
            )
        )
        /
        NULLIF(
            COUNT(*),
            0
        ),
        2
    ) AS priority_customer_share_pct,


    ROUND(
        100.0 *
        SUM(monthly_charge) FILTER (
            WHERE retention_priority IN (
                'P1 - Critical Retention',
                'P2 - Proactive Retention'
            )
        )
        /
        NULLIF(
            SUM(monthly_charge),
            0
        ),
        2
    ) AS priority_monthly_charge_share_pct,


    ROUND(
        100.0 *
        SUM(cltv) FILTER (
            WHERE retention_priority IN (
                'P1 - Critical Retention',
                'P2 - Proactive Retention'
            )
        )
        /
        NULLIF(
            SUM(cltv),
            0
        ),
        2
    ) AS priority_cltv_share_pct

FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Stayed';


/* =========================================================
   SECTION 11
   HIGH-VALUE AT-RISK PROFILE
   ========================================================= */

SELECT

    COUNT(*) AS high_value_at_risk_customers,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,

    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue,

    ROUND(
        AVG(retention_signal_count),
        2
    ) AS avg_retention_signals

FROM reporting.vw_retention_customer_priority

WHERE retention_segment = 'High-Value At-Risk';


/* =========================================================
   SECTION 12
   HIGH-VALUE AT-RISK VS HIGH-VALUE STABLE
   ========================================================= */

SELECT
    retention_segment,

    COUNT(*) AS customers,

    ROUND(
        AVG(retention_signal_count),
        2
    ) AS avg_retention_signals,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,

    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue

FROM reporting.vw_retention_customer_priority

WHERE retention_segment IN (
    'High-Value At-Risk',
    'High-Value Stable'
)

GROUP BY retention_segment

ORDER BY retention_segment;


/* =========================================================
   SECTION 13
   FINANCIAL PROFILE BY RETENTION SEGMENT
   EXISTING CUSTOMERS ONLY
   ========================================================= */

SELECT
    retention_segment,

    suggested_action,

    COUNT(*) AS customers,

    ROUND(
        AVG(retention_signal_count),
        2
    ) AS avg_retention_signals,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        100.0 *
        SUM(monthly_charge)
        /
        NULLIF(
            SUM(SUM(monthly_charge)) OVER (),
            0
        ),
        2
    ) AS monthly_charge_share_pct,

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,

    ROUND(
        100.0 *
        SUM(cltv)
        /
        NULLIF(
            SUM(SUM(cltv)) OVER (),
            0
        ),
        2
    ) AS cltv_share_pct,

    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue

FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Stayed'

GROUP BY
    retention_segment,
    suggested_action

ORDER BY total_cltv DESC;


/* =========================================================
   SECTION 14
   HISTORICAL CHURN FINANCIAL PROFILE
   ========================================================= */

SELECT

    COUNT(*) AS churned_customers,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS churned_monthly_charge_base,

    ROUND(
        SUM(total_revenue),
        2
    ) AS churned_historical_revenue,

    ROUND(
        AVG(cltv),
        2
    ) AS avg_churned_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS churned_customer_cltv

FROM analytics.customer_churn_clean

WHERE churn_value = 1;


/* =========================================================
   SECTION 15
   FINANCIAL PROFILE BY CHURN CATEGORY
   ========================================================= */

SELECT
    churn_category,

    COUNT(*) AS churned_customers,

    ROUND(
        100.0 *
        COUNT(*)
        /
        NULLIF(
            SUM(COUNT(*)) OVER (),
            0
        ),
        2
    ) AS share_of_churn_pct,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv

FROM analytics.customer_churn_clean

WHERE churn_value = 1

GROUP BY churn_category

ORDER BY monthly_charge_base DESC;


/* =========================================================
   SECTION 16
   FINANCIAL PROFILE BY DETAILED CHURN REASON
   ========================================================= */

SELECT
    churn_category,

    churn_reason,

    COUNT(*) AS churned_customers,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,

    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv

FROM analytics.customer_churn_clean

WHERE churn_value = 1

GROUP BY
    churn_category,
    churn_reason

ORDER BY monthly_charge_base DESC;


/* =========================================================
   SECTION 17
   CREATE FINANCIAL KPI VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_financial_risk_kpis AS

SELECT

    /* -----------------------------------------------------
       CUSTOMER BASE
       ----------------------------------------------------- */

    COUNT(*) AS total_customers,


    COUNT(*) FILTER (
        WHERE churn_value = 0
    ) AS active_customers,


    COUNT(*) FILTER (
        WHERE churn_value = 1
    ) AS churned_customers,


    /* -----------------------------------------------------
       MONTHLY CHARGE BASE
       ----------------------------------------------------- */

    ROUND(
        SUM(monthly_charge),
        2
    ) AS total_monthly_charge_base,


    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE churn_value = 0
        ),
        2
    ) AS active_monthly_charge_base,


    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE churn_value = 1
        ),
        2
    ) AS churned_monthly_charge_base,


    /* -----------------------------------------------------
       HISTORICAL REVENUE
       ----------------------------------------------------- */

    ROUND(
        SUM(total_revenue),
        2
    ) AS total_historical_revenue,


    ROUND(
        SUM(total_revenue) FILTER (
            WHERE churn_value = 1
        ),
        2
    ) AS churned_historical_revenue,


    /* -----------------------------------------------------
       CLTV
       ----------------------------------------------------- */

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,


    ROUND(
        SUM(cltv) FILTER (
            WHERE churn_value = 1
        ),
        2
    ) AS churned_customer_cltv,


    /* -----------------------------------------------------
       P1 EXISTING CUSTOMER EXPOSURE
       ----------------------------------------------------- */

    COUNT(*) FILTER (
        WHERE customer_status = 'Stayed'
          AND retention_priority =
              'P1 - Critical Retention'
    ) AS p1_customers,


    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE customer_status = 'Stayed'
              AND retention_priority =
                  'P1 - Critical Retention'
        ),
        2
    ) AS p1_monthly_charge_base,


    ROUND(
        SUM(cltv) FILTER (
            WHERE customer_status = 'Stayed'
              AND retention_priority =
                  'P1 - Critical Retention'
        ),
        2
    ) AS p1_total_cltv,


    /* -----------------------------------------------------
       P1 + P2 EXISTING CUSTOMER EXPOSURE
       ----------------------------------------------------- */

    COUNT(*) FILTER (
        WHERE customer_status = 'Stayed'
          AND retention_priority IN (
              'P1 - Critical Retention',
              'P2 - Proactive Retention'
          )
    ) AS priority_retention_customers,


    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE customer_status = 'Stayed'
              AND retention_priority IN (
                  'P1 - Critical Retention',
                  'P2 - Proactive Retention'
              )
        ),
        2
    ) AS priority_monthly_charge_base,


    ROUND(
        SUM(cltv) FILTER (
            WHERE customer_status = 'Stayed'
              AND retention_priority IN (
                  'P1 - Critical Retention',
                  'P2 - Proactive Retention'
              )
        ),
        2
    ) AS priority_total_cltv,


    /* -----------------------------------------------------
       HIGH-VALUE AT-RISK
       ----------------------------------------------------- */

    COUNT(*) FILTER (
        WHERE retention_segment =
            'High-Value At-Risk'
    ) AS high_value_at_risk_customers,


    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE retention_segment =
                'High-Value At-Risk'
        ),
        2
    ) AS high_value_at_risk_monthly_charge_base,


    ROUND(
        SUM(cltv) FILTER (
            WHERE retention_segment =
                'High-Value At-Risk'
        ),
        2
    ) AS high_value_at_risk_cltv


FROM reporting.vw_retention_customer_priority;


/* =========================================================
   SECTION 18
   CREATE RETENTION FINANCIAL PRIORITY VIEW
   EXISTING CUSTOMERS ONLY
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_retention_financial_by_priority AS

SELECT
    retention_priority,

    retention_priority_sort,

    COUNT(*) AS customers,


    ROUND(
        100.0 *
        COUNT(*)
        /
        NULLIF(
            SUM(COUNT(*)) OVER (),
            0
        ),
        2
    ) AS customer_share_pct,


    ROUND(
        AVG(retention_signal_count),
        2
    ) AS avg_retention_signals,


    ROUND(
        AVG(priority_score),
        2
    ) AS avg_priority_score,


    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,


    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,


    ROUND(
        100.0 *
        SUM(monthly_charge)
        /
        NULLIF(
            SUM(SUM(monthly_charge)) OVER (),
            0
        ),
        2
    ) AS monthly_charge_share_pct,


    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,


    ROUND(
        100.0 *
        SUM(cltv)
        /
        NULLIF(
            SUM(SUM(cltv)) OVER (),
            0
        ),
        2
    ) AS cltv_share_pct,


    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue


FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Stayed'

GROUP BY
    retention_priority,
    retention_priority_sort;


/* =========================================================
   SECTION 19
   CREATE RETENTION FINANCIAL SEGMENT VIEW
   EXISTING CUSTOMERS ONLY
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_retention_financial_by_segment AS

SELECT
    retention_segment,

    suggested_action,

    COUNT(*) AS customers,


    ROUND(
        100.0 *
        COUNT(*)
        /
        NULLIF(
            SUM(COUNT(*)) OVER (),
            0
        ),
        2
    ) AS customer_share_pct,


    ROUND(
        AVG(retention_signal_count),
        2
    ) AS avg_retention_signals,


    ROUND(
        AVG(priority_score),
        2
    ) AS avg_priority_score,


    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,


    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,


    ROUND(
        100.0 *
        SUM(monthly_charge)
        /
        NULLIF(
            SUM(SUM(monthly_charge)) OVER (),
            0
        ),
        2
    ) AS monthly_charge_share_pct,


    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,


    ROUND(
        100.0 *
        SUM(cltv)
        /
        NULLIF(
            SUM(SUM(cltv)) OVER (),
            0
        ),
        2
    ) AS cltv_share_pct,


    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue


FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Stayed'

GROUP BY
    retention_segment,
    suggested_action;


/* =========================================================
   SECTION 20
   CREATE CHURN FINANCIAL IMPACT VIEW
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_churn_financial_impact AS

SELECT
    COALESCE(
        churn_category,
        'Unknown'
    ) AS churn_category,


    COALESCE(
        churn_reason,
        'Unknown'
    ) AS churn_reason,


    COUNT(*) AS churned_customers,


    ROUND(
        100.0 *
        COUNT(*)
        /
        NULLIF(
            SUM(COUNT(*)) OVER (),
            0
        ),
        2
    ) AS share_of_churn_pct,


    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,


    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,


    ROUND(
        100.0 *
        SUM(monthly_charge)
        /
        NULLIF(
            SUM(SUM(monthly_charge)) OVER (),
            0
        ),
        2
    ) AS share_of_churned_monthly_charge_pct,


    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue,


    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv


FROM analytics.customer_churn_clean

WHERE churn_value = 1

GROUP BY
    churn_category,
    churn_reason;


/* =========================================================
   SECTION 21
   CREATE CUSTOMER-LEVEL RETENTION VALUE EXPOSURE VIEW

   Includes P1 and P2 existing customers only.
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_retention_value_exposure AS

SELECT

    customer_id,

    city,

    customer_value_segment,

    customer_value_segment_sort,

    tenure_in_months,

    tenure_band,

    contract,

    monthly_charge,

    total_revenue,

    cltv,

    satisfaction_score,

    service_count,

    retention_signal_count,

    priority_score,

    retention_priority,

    retention_priority_sort,

    retention_segment,

    suggested_action


FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Stayed'

AND retention_priority IN (
    'P1 - Critical Retention',
    'P2 - Proactive Retention'
);


/* =========================================================
   SECTION 22
   TEST FINANCIAL KPI VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_financial_risk_kpis;


/* Expected:
   1 row
*/


/* =========================================================
   SECTION 23
   TEST FINANCIAL PRIORITY VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_retention_financial_by_priority

ORDER BY retention_priority_sort;


/* Expected:
   P1
   P2
   P3
   P4
*/


/* =========================================================
   SECTION 24
   TEST FINANCIAL SEGMENT VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_retention_financial_by_segment

ORDER BY total_cltv DESC;


/* =========================================================
   SECTION 25
   TOP FINANCIALLY MATERIAL CHURN REASONS
   ========================================================= */

SELECT
    churn_category,
    churn_reason,
    churned_customers,
    share_of_churn_pct,
    monthly_charge_base,
    share_of_churned_monthly_charge_pct,
    historical_revenue,
    total_cltv

FROM reporting.vw_churn_financial_impact

ORDER BY monthly_charge_base DESC

LIMIT 15;


/* =========================================================
   SECTION 26
   TOP PRIORITY RETENTION CUSTOMERS BY CLTV
   ========================================================= */

SELECT
    customer_id,
    city,
    customer_value_segment,
    tenure_in_months,
    contract,
    monthly_charge,
    cltv,
    satisfaction_score,
    retention_signal_count,
    priority_score,
    retention_priority,
    retention_segment,
    suggested_action

FROM reporting.vw_retention_value_exposure

ORDER BY
    retention_priority_sort,
    priority_score DESC,
    cltv DESC

LIMIT 50;


/* =========================================================
   SECTION 27
   RECONCILE MONTHLY CHARGE BASE
   ========================================================= */

SELECT

    ROUND(
        SUM(monthly_charge),
        2
    ) AS total_monthly_charge_base,

    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE churn_value = 0
        ),
        2
    ) AS active_monthly_charge_base,

    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE churn_value = 1
        ),
        2
    ) AS churned_monthly_charge_base,

    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE churn_value = 0
        )
        +
        SUM(monthly_charge) FILTER (
            WHERE churn_value = 1
        ),
        2
    ) AS reconciled_monthly_charge_base

FROM analytics.customer_churn_clean;


/* total_monthly_charge_base should equal
   reconciled_monthly_charge_base.
*/


/* =========================================================
   SECTION 28
   RECONCILE RETENTION PRIORITY CUSTOMERS
   ========================================================= */

SELECT
    SUM(customers)
        AS stayed_customers_from_priority_view

FROM reporting.vw_retention_financial_by_priority;


/* Compare against: */

SELECT
    COUNT(*) AS stayed_customers_from_source

FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Stayed';


/* These totals must match.
*/


/* =========================================================
   SECTION 29
   RECONCILE RETENTION SEGMENTS
   ========================================================= */

SELECT
    SUM(customers)
        AS stayed_customers_from_segment_view

FROM reporting.vw_retention_financial_by_segment;


/* Compare against the Stayed customer count.
*/


/* =========================================================
   SECTION 30
   RECONCILE CHURN FINANCIAL IMPACT
   ========================================================= */

SELECT
    SUM(churned_customers)
        AS churned_customers_from_financial_view

FROM reporting.vw_churn_financial_impact;


/* Compare against: */

SELECT
    COUNT(*) AS churned_customers_from_source

FROM analytics.customer_churn_clean

WHERE churn_value = 1;


/* These totals must match.
*/


/* =========================================================
   SECTION 31
   CHECK CUSTOMER-LEVEL VALUE EXPOSURE VIEW
   ========================================================= */

SELECT

    COUNT(*) AS priority_customers,

    COUNT(DISTINCT customer_id)
        AS unique_priority_customers

FROM reporting.vw_retention_value_exposure;


/* Counts should be equal.
*/


/* =========================================================
   SECTION 32
   CHECK FOR DUPLICATE CUSTOMERS
   ========================================================= */

SELECT
    customer_id,
    COUNT(*) AS occurrences

FROM reporting.vw_retention_value_exposure

GROUP BY customer_id

HAVING COUNT(*) > 1;


/* Expected:
   0 rows
*/


/* =========================================================
   SECTION 33
   CHECK REPORTING VIEWS
   ========================================================= */

SELECT
    table_schema,
    table_name

FROM information_schema.views

WHERE table_schema = 'reporting'

ORDER BY table_name;


/* Step 9 adds:

   vw_financial_risk_kpis
   vw_retention_financial_by_priority
   vw_retention_financial_by_segment
   vw_churn_financial_impact
   vw_retention_value_exposure
*/


/* =========================================================
   SECTION 34
   METHODOLOGY NOTES

   1. Monthly Charge Base is treated as a billing-value
      proxy and is not guaranteed recurring revenue.

   2. Churned Monthly Charge Base represents monthly charges
      associated with customers who already churned.

   3. Total Revenue is treated as historical/cumulative
      customer revenue, not revenue lost.

   4. CLTV is a customer-value measure and must not be
      interpreted as guaranteed future cash flow.

   5. P1/P2 customer values represent business-priority
      exposure from the rule-based segmentation developed
      in Step 8.

   6. Retention Priority is not predicted churn
      probability.

   7. Financial concentration should be interpreted
      alongside customer counts rather than in isolation.

   ========================================================= */


/* =========================================================
   END OF SCRIPT
   ========================================================= */


SELECT *
FROM reporting.vw_financial_risk_kpis;


SELECT
    retention_priority,
    customers,
    customer_share_pct,
    monthly_charge_base,
    monthly_charge_share_pct,
    total_cltv,
    cltv_share_pct

FROM reporting.vw_retention_financial_by_priority

ORDER BY retention_priority_sort;