/* =========================================================
   PROJECT 3: CUSTOMER CHURN, RETENTION & REVENUE RISK
   SCRIPT: 05_core_kpis.sql

   PURPOSE:
   1. Validate the analytics customer table.
   2. Calculate core customer KPIs.
   3. Calculate churn and retention KPIs.
   4. Calculate monthly-charge and revenue KPIs.
   5. Calculate CLTV and high-value churn KPIs.
   6. Create reusable reporting views for Power BI.

   SOURCE TABLE:
   analytics.customer_churn_clean

   REPORTING VIEWS CREATED:
   reporting.vw_executive_kpis
   reporting.vw_customer_status_summary
   reporting.vw_churn_summary
   reporting.vw_customer_value_summary
   ========================================================= */


/* =========================================================
   SECTION 1
   VALIDATE SOURCE TABLE
   ========================================================= */

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM analytics.customer_churn_clean;


/* Expected:
   total_rows       = 7043
   unique_customers = 7043
*/


/* =========================================================
   SECTION 2
   BASIC CUSTOMER COUNTS
   ========================================================= */

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ) AS active_customers,

    COUNT(*) FILTER (
        WHERE customer_status = 'Stayed'
    ) AS stayed_customers,

    COUNT(*) FILTER (
        WHERE customer_status = 'Joined'
    ) AS joined_customers,

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ) AS churned_customers

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 3
   CUSTOMER STATUS DISTRIBUTION
   ========================================================= */

SELECT
    customer_status,
    COUNT(*) AS customers
FROM analytics.customer_churn_clean
GROUP BY customer_status
ORDER BY customers DESC;


/* =========================================================
   SECTION 4
   CHURN RATE
   ========================================================= */

SELECT
    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE churn_value = 1
        )
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 5
   NON-CHURN RATE
   ========================================================= */

SELECT
    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE churn_value = 0
        )
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS non_churn_rate_pct

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 6
   EXISTING CUSTOMER RETENTION RATE

   Definition:
   Stayed / (Stayed + Churned)

   Joined customers are excluded because they are newly
   acquired customers rather than retained customers.
   ========================================================= */

SELECT
    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE customer_status = 'Stayed'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE customer_status IN (
                    'Stayed',
                    'Churned'
                )
            ),
            0
        ),
        2
    ) AS existing_customer_retention_rate_pct

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 7
   TENURE KPIS
   ========================================================= */

SELECT
    ROUND(
        AVG(tenure_in_months),
        2
    ) AS average_tenure_months,

    MIN(tenure_in_months) AS minimum_tenure_months,

    MAX(tenure_in_months) AS maximum_tenure_months

FROM analytics.customer_churn_clean;


SELECT
    customer_status,

    COUNT(*) AS customers,

    ROUND(
        AVG(tenure_in_months),
        2
    ) AS average_tenure_months

FROM analytics.customer_churn_clean

GROUP BY customer_status

ORDER BY average_tenure_months DESC;


/* =========================================================
   SECTION 8
   MONTHLY CHARGE KPIS
   ========================================================= */

SELECT
    ROUND(
        AVG(monthly_charge),
        2
    ) AS average_monthly_charge,

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
    ) AS churned_monthly_charge_base

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 9
   MONTHLY CHARGE BY CUSTOMER STATUS
   ========================================================= */

SELECT
    customer_status,

    COUNT(*) AS customers,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS average_monthly_charge,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base

FROM analytics.customer_churn_clean

GROUP BY customer_status

ORDER BY monthly_charge_base DESC;


/* =========================================================
   SECTION 10
   HISTORICAL REVENUE KPIS
   ========================================================= */

SELECT
    ROUND(
        SUM(total_revenue),
        2
    ) AS total_historical_revenue,

    ROUND(
        AVG(total_revenue),
        2
    ) AS average_revenue_per_customer

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 11
   HISTORICAL REVENUE BY CUSTOMER STATUS
   ========================================================= */

SELECT
    customer_status,

    COUNT(*) AS customers,

    ROUND(
        SUM(total_revenue),
        2
    ) AS total_revenue,

    ROUND(
        AVG(total_revenue),
        2
    ) AS average_revenue_per_customer

FROM analytics.customer_churn_clean

GROUP BY customer_status

ORDER BY total_revenue DESC;


/* =========================================================
   SECTION 12
   CLTV KPIS
   ========================================================= */

SELECT
    ROUND(
        AVG(cltv),
        2
    ) AS average_cltv,

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

    ROUND(
        AVG(cltv) FILTER (
            WHERE churn_value = 1
        ),
        2
    ) AS average_churned_customer_cltv

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 13
   CLTV BY CUSTOMER STATUS
   ========================================================= */

SELECT
    customer_status,

    COUNT(*) AS customers,

    ROUND(
        AVG(cltv),
        2
    ) AS average_cltv,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv

FROM analytics.customer_churn_clean

GROUP BY customer_status

ORDER BY average_cltv DESC;


/* =========================================================
   SECTION 14
   CUSTOMER VALUE DISTRIBUTION
   ========================================================= */

SELECT
    customer_value_segment,

    COUNT(*) AS customers,

    ROUND(
        AVG(cltv),
        2
    ) AS average_cltv

FROM analytics.customer_churn_clean

GROUP BY
    customer_value_segment,
    customer_value_segment_sort

ORDER BY customer_value_segment_sort;


/* =========================================================
   SECTION 15
   HIGH-VALUE CUSTOMER KPIS

   High-value customer definition:
   High Value + Very High Value
   ========================================================= */

SELECT

    COUNT(*) FILTER (
        WHERE customer_value_segment IN (
            'High Value',
            'Very High Value'
        )
    ) AS high_value_customers,


    COUNT(*) FILTER (
        WHERE churn_value = 1
          AND customer_value_segment IN (
              'High Value',
              'Very High Value'
          )
    ) AS high_value_churned_customers,


    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE churn_value = 1
              AND customer_value_segment IN (
                  'High Value',
                  'Very High Value'
              )
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE customer_value_segment IN (
                    'High Value',
                    'Very High Value'
                )
            ),
            0
        ),
        2
    ) AS high_value_churn_rate_pct

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 16
   CUSTOMER VALUE SEGMENT CHURN SUMMARY
   ========================================================= */

SELECT
    customer_value_segment,

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
        AVG(cltv),
        2
    ) AS average_cltv

FROM analytics.customer_churn_clean

GROUP BY
    customer_value_segment,
    customer_value_segment_sort

ORDER BY customer_value_segment_sort;


/* =========================================================
   SECTION 17
   SATISFACTION KPI
   ========================================================= */

SELECT
    ROUND(
        AVG(satisfaction_score),
        2
    ) AS average_satisfaction_score

FROM analytics.customer_churn_clean;


SELECT
    customer_status,

    COUNT(*) AS customers,

    ROUND(
        AVG(satisfaction_score),
        2
    ) AS average_satisfaction_score

FROM analytics.customer_churn_clean

GROUP BY customer_status

ORDER BY average_satisfaction_score DESC;


/* =========================================================
   SECTION 18
   CREATE EXECUTIVE KPI VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_executive_kpis AS

SELECT

    /* CUSTOMER BASE */

    COUNT(*) AS total_customers,


    COUNT(*) FILTER (
        WHERE churn_value = 0
    ) AS active_customers,


    COUNT(*) FILTER (
        WHERE customer_status = 'Stayed'
    ) AS stayed_customers,


    COUNT(*) FILTER (
        WHERE customer_status = 'Joined'
    ) AS joined_customers,


    COUNT(*) FILTER (
        WHERE churn_value = 1
    ) AS churned_customers,


    /* CHURN */

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE churn_value = 1
        )
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct,


    /* RETENTION */

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE customer_status = 'Stayed'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE customer_status IN (
                    'Stayed',
                    'Churned'
                )
            ),
            0
        ),
        2
    ) AS existing_customer_retention_rate_pct,


    /* CUSTOMER RELATIONSHIP */

    ROUND(
        AVG(tenure_in_months),
        2
    ) AS avg_tenure_months,


    ROUND(
        AVG(satisfaction_score),
        2
    ) AS avg_satisfaction_score,


    /* MONTHLY CHARGE */

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,


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


    /* REVENUE */

    ROUND(
        SUM(total_revenue),
        2
    ) AS total_historical_revenue,


    ROUND(
        AVG(total_revenue),
        2
    ) AS avg_revenue_per_customer,


    /* CLTV */

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        SUM(cltv) FILTER (
            WHERE churn_value = 1
        ),
        2
    ) AS churned_customer_cltv,


    /* HIGH-VALUE CUSTOMERS */

    COUNT(*) FILTER (
        WHERE customer_value_segment IN (
            'High Value',
            'Very High Value'
        )
    ) AS high_value_customers,


    COUNT(*) FILTER (
        WHERE churn_value = 1
          AND customer_value_segment IN (
              'High Value',
              'Very High Value'
          )
    ) AS high_value_churned_customers,


    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE churn_value = 1
              AND customer_value_segment IN (
                  'High Value',
                  'Very High Value'
              )
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE customer_value_segment IN (
                    'High Value',
                    'Very High Value'
                )
            ),
            0
        ),
        2
    ) AS high_value_churn_rate_pct


FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 19
   CREATE CUSTOMER STATUS SUMMARY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_customer_status_summary AS

SELECT

    customer_status,

    COUNT(*) AS customers,


    ROUND(
        100.0 * COUNT(*)
        /
        NULLIF(
            SUM(COUNT(*)) OVER (),
            0
        ),
        2
    ) AS customer_share_pct,


    ROUND(
        AVG(tenure_in_months),
        2
    ) AS avg_tenure_months,


    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,


    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,


    ROUND(
        SUM(total_revenue),
        2
    ) AS total_revenue,


    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        AVG(satisfaction_score),
        2
    ) AS avg_satisfaction_score


FROM analytics.customer_churn_clean

GROUP BY customer_status;


/* =========================================================
   SECTION 20
   CREATE CHURN SUMMARY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_churn_summary AS

SELECT

    CASE
        WHEN churn_value = 1
            THEN 'Churned'
        WHEN churn_value = 0
            THEN 'Not Churned'
        ELSE 'Unknown'
    END AS churn_status,


    churn_value,


    COUNT(*) AS customers,


    ROUND(
        100.0 * COUNT(*)
        /
        NULLIF(
            SUM(COUNT(*)) OVER (),
            0
        ),
        2
    ) AS customer_share_pct,


    ROUND(
        AVG(tenure_in_months),
        2
    ) AS avg_tenure_months,


    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,


    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,


    ROUND(
        SUM(total_revenue),
        2
    ) AS total_revenue,


    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        AVG(satisfaction_score),
        2
    ) AS avg_satisfaction_score


FROM analytics.customer_churn_clean

GROUP BY churn_value;


/* =========================================================
   SECTION 21
   CREATE CUSTOMER VALUE SUMMARY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_customer_value_summary AS

SELECT

    customer_value_segment,

    customer_value_segment_sort,

    COUNT(*) AS customers,


    COUNT(*) FILTER (
        WHERE churn_value = 1
    ) AS churned_customers,


    COUNT(*) FILTER (
        WHERE churn_value = 0
    ) AS active_customers,


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
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        SUM(total_revenue),
        2
    ) AS total_revenue


FROM analytics.customer_churn_clean

GROUP BY
    customer_value_segment,
    customer_value_segment_sort;


/* =========================================================
   SECTION 22
   TEST EXECUTIVE KPI VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_executive_kpis;


/* Expected:
   1 row
*/


/* =========================================================
   SECTION 23
   TEST CUSTOMER STATUS VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_customer_status_summary
ORDER BY customers DESC;


/* Expected:
   Stayed
   Joined
   Churned
*/


/* =========================================================
   SECTION 24
   TEST CHURN SUMMARY VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_churn_summary
ORDER BY churn_value;


/* Expected:
   Not Churned
   Churned
*/


/* =========================================================
   SECTION 25
   TEST CUSTOMER VALUE SUMMARY VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_customer_value_summary
ORDER BY customer_value_segment_sort;


/* =========================================================
   SECTION 26
   RECONCILIATION TESTS
   ========================================================= */

SELECT
    SUM(customers) AS customers_from_status_view
FROM reporting.vw_customer_status_summary;


SELECT
    SUM(customers) AS customers_from_churn_view
FROM reporting.vw_churn_summary;


SELECT
    SUM(customers) AS customers_from_value_view
FROM reporting.vw_customer_value_summary;


/* Each result should reconcile to the source customer count,
   expected to be 7043.
*/


/* =========================================================
   SECTION 27
   FINAL REPORTING VIEW CHECK
   ========================================================= */

SELECT
    table_schema,
    table_name
FROM information_schema.views
WHERE table_schema = 'reporting'
ORDER BY table_name;


/* Expected Step 6 views:

   reporting.vw_churn_summary
   reporting.vw_customer_status_summary
   reporting.vw_customer_value_summary
   reporting.vw_executive_kpis
*/


/* =========================================================
   END OF SCRIPT
   ========================================================= */


SELECT
    SUM(customers) AS customers_from_status_view
FROM reporting.vw_customer_status_summary;

SELECT *
FROM reporting.vw_churn_summary;