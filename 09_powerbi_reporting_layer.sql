/* =========================================================
   PROJECT 3: CUSTOMER CHURN, RETENTION & REVENUE RISK

   SCRIPT:
   09_powerbi_reporting_layer.sql

   PURPOSE:
   1. Audit the existing reporting layer.
   2. Create a curated Power BI customer table.
   3. Standardise dashboard labels and sort columns.
   4. Create Power BI-ready summary views.
   5. Create a Power BI data-quality view.
   6. Perform final SQL reconciliation before Power BI.

   PRIMARY POWER BI TABLE:
   reporting.vw_pbi_customer_detail

   SUPPORTING VIEWS:
   reporting.vw_pbi_executive_kpis
   reporting.vw_pbi_customer_status
   reporting.vw_pbi_churn_outcome
   reporting.vw_pbi_churn_drivers
   reporting.vw_pbi_churn_reasons
   reporting.vw_pbi_churn_category
   reporting.vw_pbi_retention_priority
   reporting.vw_pbi_retention_segment
   reporting.vw_pbi_data_quality

   IMPORTANT:
   Churn Score is deliberately excluded from the Power BI
   driver layer because it is already a predictive score
   in the source dataset.

   ========================================================= */


/* =========================================================
   SECTION 1
   AUDIT EXISTING REPORTING VIEWS
   ========================================================= */

SELECT
    table_schema,
    table_name
FROM information_schema.views
WHERE table_schema = 'reporting'
ORDER BY table_name;


/* =========================================================
   SECTION 2
   CREATE MAIN POWER BI CUSTOMER DETAIL VIEW

   Grain:
   1 row = 1 customer
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_customer_detail AS

SELECT

    /* -----------------------------------------------------
       CUSTOMER IDENTIFICATION
       ----------------------------------------------------- */

    c.customer_id,


    /* -----------------------------------------------------
       CUSTOMER LIFECYCLE STATUS
       ----------------------------------------------------- */

    c.customer_status,


    CASE
        WHEN c.customer_status = 'Stayed' THEN 1
        WHEN c.customer_status = 'Joined' THEN 2
        WHEN c.customer_status = 'Churned' THEN 3
        ELSE 99
    END AS customer_status_sort,


    c.churn_value,


    CASE
        WHEN c.churn_value = 1
            THEN 'Churned'

        WHEN c.churn_value = 0
            THEN 'Not Churned'

        ELSE 'Unknown'
    END AS churn_status,


    CASE
        WHEN c.churn_value = 0 THEN 1
        WHEN c.churn_value = 1 THEN 2
        ELSE 99
    END AS churn_status_sort,


    /* -----------------------------------------------------
       DEMOGRAPHICS
       ----------------------------------------------------- */

    c.gender,

    c.age,

    c.age_band,

    c.age_band_sort,

    c.senior_citizen,


    CASE
        WHEN c.senior_citizen IS TRUE
            THEN 'Senior Citizen'

        WHEN c.senior_citizen IS FALSE
            THEN 'Not Senior Citizen'

        ELSE 'Unknown'
    END AS senior_citizen_label,


    c.married,

    c.dependents,


    /* -----------------------------------------------------
       LOCATION
       ----------------------------------------------------- */

    c.city,

    c.zip_code,


    /* -----------------------------------------------------
       TENURE / CONTRACT
       ----------------------------------------------------- */

    c.tenure_in_months,

    c.tenure_band,

    c.tenure_band_sort,

    c.contract,

    c.payment_method,


    /* -----------------------------------------------------
       SERVICES
       ----------------------------------------------------- */

    c.internet_service,


    CASE
        WHEN c.internet_service IS TRUE
            THEN 'Internet Customer'

        WHEN c.internet_service IS FALSE
            THEN 'No Internet Service'

        ELSE 'Unknown'
    END AS internet_service_label,


    c.internet_type,

    c.premium_tech_support,

    c.referred_a_friend,


    CASE
        WHEN c.referred_a_friend IS TRUE
            THEN 'Referred Friend'

        WHEN c.referred_a_friend IS FALSE
            THEN 'No Referral'

        ELSE 'Unknown'
    END AS referral_status,


    c.number_of_referrals,

    c.service_count,


    /* -----------------------------------------------------
       FINANCIAL
       ----------------------------------------------------- */

    c.monthly_charge,

    c.monthly_charge_band,

    c.monthly_charge_band_sort,

    c.total_revenue,

    c.cltv,

    c.customer_value_segment,

    c.customer_value_segment_sort,


    /* -----------------------------------------------------
       CUSTOMER EXPERIENCE / CHURN
       ----------------------------------------------------- */

    c.satisfaction_score,

    c.churn_category_display,

    c.churn_reason_display,


    /* -----------------------------------------------------
       RETENTION SIGNALS
       ----------------------------------------------------- */

    r.early_tenure_signal,

    r.month_to_month_signal,

    r.low_satisfaction_signal,

    r.no_tech_support_signal,

    r.no_referral_signal,

    r.low_service_depth_signal,

    r.high_charge_signal,

    r.retention_signal_count,


    /* -----------------------------------------------------
       RETENTION PRIORITY
       ----------------------------------------------------- */

    r.priority_score,

    r.retention_priority,


    CASE
        WHEN r.retention_priority =
             'P1 - Critical Retention'
            THEN 'P1'

        WHEN r.retention_priority =
             'P2 - Proactive Retention'
            THEN 'P2'

        WHEN r.retention_priority =
             'P3 - Monitor'
            THEN 'P3'

        WHEN r.retention_priority =
             'P4 - Stable / Loyalty'
            THEN 'P4'

        WHEN r.customer_status = 'Joined'
            THEN 'New'

        WHEN r.customer_status = 'Churned'
            THEN 'Churned'

        ELSE 'Review'
    END AS retention_priority_short,


    r.retention_priority_sort,

    r.retention_segment,

    r.suggested_action,


    /* -----------------------------------------------------
       POWER BI HELPER FLAGS
       ----------------------------------------------------- */

    CASE
        WHEN c.churn_value = 0 THEN TRUE
        WHEN c.churn_value = 1 THEN FALSE
        ELSE NULL
    END AS is_active_customer,


    CASE
        WHEN c.customer_status = 'Stayed'
            THEN TRUE
        ELSE FALSE
    END AS is_existing_customer,


    CASE
        WHEN c.customer_status = 'Joined'
            THEN TRUE
        ELSE FALSE
    END AS is_new_customer,


    CASE
        WHEN c.customer_status = 'Stayed'
         AND r.retention_priority IN (
                'P1 - Critical Retention',
                'P2 - Proactive Retention'
             )
            THEN TRUE

        ELSE FALSE
    END AS is_priority_retention_target,


    CASE
        WHEN c.customer_value_segment IN (
                'High Value',
                'Very High Value'
             )
            THEN TRUE

        ELSE FALSE
    END AS is_high_value_customer,


    CASE
        WHEN r.retention_segment =
             'High-Value At-Risk'
            THEN TRUE

        ELSE FALSE
    END AS is_high_value_at_risk


FROM analytics.customer_churn_clean c

LEFT JOIN reporting.vw_retention_customer_priority r

    ON c.customer_id = r.customer_id;


/* =========================================================
   SECTION 3
   VALIDATE POWER BI CUSTOMER GRAIN
   ========================================================= */

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT customer_id)
        AS unique_customers

FROM reporting.vw_pbi_customer_detail;


/* Expected:
   total_rows       = 7043
   unique_customers = 7043
*/


/* =========================================================
   SECTION 4
   CHECK FOR DUPLICATE CUSTOMER IDS
   ========================================================= */

SELECT
    customer_id,
    COUNT(*) AS occurrences

FROM reporting.vw_pbi_customer_detail

GROUP BY customer_id

HAVING COUNT(*) > 1;


/* Expected:
   0 rows
*/


/* =========================================================
   SECTION 5
   CREATE EXECUTIVE KPI BENCHMARK VIEW
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_executive_kpis AS

SELECT

    /* -----------------------------------------------------
       CUSTOMER BASE
       ----------------------------------------------------- */

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


    /* -----------------------------------------------------
       CHURN
       ----------------------------------------------------- */

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE churn_value = 1
        )
        /
        NULLIF(
            COUNT(*),
            0
        ),
        2
    ) AS churn_rate_pct,


    /* -----------------------------------------------------
       RETENTION RATE
       Stayed / (Stayed + Churned)
       ----------------------------------------------------- */

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


    /* -----------------------------------------------------
       EXPERIENCE / RELATIONSHIP
       ----------------------------------------------------- */

    ROUND(
        AVG(tenure_in_months),
        2
    ) AS avg_tenure_months,


    ROUND(
        AVG(satisfaction_score),
        2
    ) AS avg_satisfaction_score,


    /* -----------------------------------------------------
       MONTHLY CHARGE
       ----------------------------------------------------- */

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


    ROUND(
        AVG(total_revenue),
        2
    ) AS avg_historical_revenue_per_customer,


    /* -----------------------------------------------------
       CLTV
       ----------------------------------------------------- */

    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


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
       HIGH-VALUE CUSTOMER CHURN
       ----------------------------------------------------- */

    COUNT(*) FILTER (
        WHERE is_high_value_customer IS TRUE
    ) AS high_value_customers,


    COUNT(*) FILTER (
        WHERE is_high_value_customer IS TRUE
          AND churn_value = 1
    ) AS high_value_churned_customers,


    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE is_high_value_customer IS TRUE
              AND churn_value = 1
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE is_high_value_customer IS TRUE
            ),
            0
        ),
        2
    ) AS high_value_churn_rate_pct,


    /* -----------------------------------------------------
       P1 EXISTING CUSTOMERS
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
       P1 + P2 PRIORITY RETENTION POPULATION
       ----------------------------------------------------- */

    COUNT(*) FILTER (
        WHERE is_priority_retention_target IS TRUE
    ) AS priority_retention_customers,


    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE is_priority_retention_target IS TRUE
        ),
        2
    ) AS priority_monthly_charge_base,


    ROUND(
        SUM(cltv) FILTER (
            WHERE is_priority_retention_target IS TRUE
        ),
        2
    ) AS priority_total_cltv,


    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE is_priority_retention_target IS TRUE
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE customer_status = 'Stayed'
            ),
            0
        ),
        2
    ) AS priority_customer_share_pct,


    ROUND(
        100.0 *
        SUM(monthly_charge) FILTER (
            WHERE is_priority_retention_target IS TRUE
        )
        /
        NULLIF(
            SUM(monthly_charge) FILTER (
                WHERE customer_status = 'Stayed'
            ),
            0
        ),
        2
    ) AS priority_monthly_charge_share_pct,


    ROUND(
        100.0 *
        SUM(cltv) FILTER (
            WHERE is_priority_retention_target IS TRUE
        )
        /
        NULLIF(
            SUM(cltv) FILTER (
                WHERE customer_status = 'Stayed'
            ),
            0
        ),
        2
    ) AS priority_cltv_share_pct,


    /* -----------------------------------------------------
       HIGH-VALUE AT-RISK
       ----------------------------------------------------- */

    COUNT(*) FILTER (
        WHERE is_high_value_at_risk IS TRUE
    ) AS high_value_at_risk_customers,


    ROUND(
        SUM(monthly_charge) FILTER (
            WHERE is_high_value_at_risk IS TRUE
        ),
        2
    ) AS high_value_at_risk_monthly_charge_base,


    ROUND(
        SUM(cltv) FILTER (
            WHERE is_high_value_at_risk IS TRUE
        ),
        2
    ) AS high_value_at_risk_cltv


FROM reporting.vw_pbi_customer_detail;


/* =========================================================
   SECTION 6
   CREATE CUSTOMER STATUS SUMMARY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_customer_status AS

SELECT

    customer_status,


    CASE
        WHEN customer_status = 'Stayed' THEN 1
        WHEN customer_status = 'Joined' THEN 2
        WHEN customer_status = 'Churned' THEN 3
        ELSE 99
    END AS customer_status_sort,


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
    ) AS historical_revenue,


    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        AVG(satisfaction_score),
        2
    ) AS avg_satisfaction_score


FROM reporting.vw_pbi_customer_detail

GROUP BY customer_status;


/* =========================================================
   SECTION 7
   CREATE CHURN OUTCOME VIEW
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_churn_outcome AS

SELECT

    churn_status,

    churn_status_sort,

    churn_value,

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
    ) AS historical_revenue,


    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        AVG(satisfaction_score),
        2
    ) AS avg_satisfaction_score


FROM reporting.vw_pbi_customer_detail

GROUP BY
    churn_status,
    churn_status_sort,
    churn_value;


/* =========================================================
   SECTION 8
   CREATE POWER BI CHURN DRIVER VIEW
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_churn_drivers AS

SELECT

    driver_name,


    CASE
        WHEN driver_name = 'Contract' THEN 1
        WHEN driver_name = 'Tenure Band' THEN 2
        WHEN driver_name = 'Monthly Charge Band' THEN 3
        WHEN driver_name = 'Payment Method' THEN 4
        WHEN driver_name = 'Internet Type' THEN 5
        WHEN driver_name = 'Premium Tech Support' THEN 6
        WHEN driver_name = 'Referral Status' THEN 7
        WHEN driver_name = 'Referral Band' THEN 8
        WHEN driver_name = 'Service Count Band' THEN 9
        WHEN driver_name = 'Age Band' THEN 10
        WHEN driver_name = 'Senior Citizen' THEN 11
        WHEN driver_name = 'Gender' THEN 12
        WHEN driver_name = 'Satisfaction Score' THEN 13
        ELSE 99
    END AS driver_name_sort,


    driver_value,

    driver_sort,

    customers,

    churned_customers,

    active_customers,

    churn_rate_pct,

    overall_churn_rate_pct,

    churn_rate_gap_pp,

    churn_lift,


    CASE

        WHEN churn_lift >= 1.50
            THEN 'Very High Relative Churn'

        WHEN churn_lift >= 1.20
            THEN 'High Relative Churn'

        WHEN churn_lift > 1.00
            THEN 'Above Average'

        WHEN churn_lift >= 0.80
            THEN 'Near Average'

        ELSE 'Below Average'

    END AS relative_churn_band,


    CASE
        WHEN churn_lift >= 1.50 THEN 1
        WHEN churn_lift >= 1.20 THEN 2
        WHEN churn_lift > 1.00 THEN 3
        WHEN churn_lift >= 0.80 THEN 4
        ELSE 5
    END AS relative_churn_band_sort,


    CASE
        WHEN churn_lift > 1
            THEN TRUE
        ELSE FALSE
    END AS is_above_average_churn,


    CASE
        WHEN customers >= 100
            THEN TRUE
        ELSE FALSE
    END AS meets_minimum_segment_size,


    avg_monthly_charge,

    avg_tenure_months,

    avg_satisfaction_score,

    avg_cltv


FROM reporting.vw_churn_driver_summary;


/* =========================================================
   SECTION 9
   CREATE POWER BI CHURN REASON VIEW
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_churn_reasons AS

SELECT

    churn_category_display
        AS churn_category,

    churn_reason_display
        AS churn_reason,

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
    ) AS share_of_total_churn_pct,


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
    ) AS total_cltv,


    ROW_NUMBER() OVER (
        ORDER BY
            COUNT(*) DESC,
            churn_reason_display
    )::INTEGER AS rank_by_customer_count,


    ROW_NUMBER() OVER (
        ORDER BY
            SUM(monthly_charge) DESC,
            churn_reason_display
    )::INTEGER AS rank_by_monthly_charge


FROM reporting.vw_pbi_customer_detail

WHERE churn_value = 1

GROUP BY
    churn_category_display,
    churn_reason_display;


/* =========================================================
   SECTION 10
   CREATE POWER BI CHURN CATEGORY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_churn_category AS

SELECT

    churn_category_display
        AS churn_category,

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
    ) AS share_of_total_churn_pct,


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
    ) AS total_cltv,


    ROW_NUMBER() OVER (
        ORDER BY
            COUNT(*) DESC,
            churn_category_display
    )::INTEGER AS rank_by_customer_count,


    ROW_NUMBER() OVER (
        ORDER BY
            SUM(monthly_charge) DESC,
            churn_category_display
    )::INTEGER AS rank_by_monthly_charge


FROM reporting.vw_pbi_customer_detail

WHERE churn_value = 1

GROUP BY churn_category_display;


/* =========================================================
   SECTION 11
   CREATE POWER BI RETENTION PRIORITY VIEW

   Existing Stayed customers only.
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_retention_priority AS

SELECT

    retention_priority,


    CASE
        WHEN retention_priority =
             'P1 - Critical Retention'
            THEN 'P1'

        WHEN retention_priority =
             'P2 - Proactive Retention'
            THEN 'P2'

        WHEN retention_priority =
             'P3 - Monitor'
            THEN 'P3'

        WHEN retention_priority =
             'P4 - Stable / Loyalty'
            THEN 'P4'

        ELSE 'Review'
    END AS retention_priority_short,


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


FROM reporting.vw_pbi_customer_detail

WHERE customer_status = 'Stayed'

GROUP BY
    retention_priority,
    retention_priority_sort;


/* =========================================================
   SECTION 12
   CREATE POWER BI RETENTION SEGMENT VIEW

   Existing Stayed customers only.
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_retention_segment AS

SELECT

    retention_segment,


    CASE
        WHEN retention_segment =
             'High-Value At-Risk'
            THEN 1

        WHEN retention_segment =
             'Elevated-Risk Standard Value'
            THEN 2

        WHEN retention_segment =
             'Monitor'
            THEN 3

        WHEN retention_segment =
             'High-Value Stable'
            THEN 4

        WHEN retention_segment =
             'Loyalty / Expansion'
            THEN 5

        ELSE 99
    END AS retention_segment_sort,


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


FROM reporting.vw_pbi_customer_detail

WHERE customer_status = 'Stayed'

GROUP BY
    retention_segment,
    suggested_action;


/* =========================================================
   SECTION 13
   CREATE POWER BI DATA QUALITY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW
reporting.vw_pbi_data_quality AS

WITH dq AS (

    SELECT

        /* RAW / STAGING COUNTS */

        (
            SELECT COUNT(*)
            FROM staging.demographics_raw
        ) AS demographics_rows,


        (
            SELECT COUNT(*)
            FROM staging.location_raw
        ) AS location_rows,


        (
            SELECT COUNT(*)
            FROM staging.population_raw
        ) AS population_rows,


        (
            SELECT COUNT(*)
            FROM staging.services_raw
        ) AS services_rows,


        (
            SELECT COUNT(*)
            FROM staging.status_raw
        ) AS status_rows,


        /* ANALYTICS COUNTS */

        (
            SELECT COUNT(*)
            FROM analytics.customer_churn_clean
        ) AS analytics_rows,


        (
            SELECT COUNT(DISTINCT customer_id)
            FROM analytics.customer_churn_clean
        ) AS analytics_unique_customers,


        /* POWER BI COUNTS */

        (
            SELECT COUNT(*)
            FROM reporting.vw_pbi_customer_detail
        ) AS pbi_customer_rows,


        (
            SELECT COUNT(DISTINCT customer_id)
            FROM reporting.vw_pbi_customer_detail
        ) AS pbi_unique_customers,


        /* DUPLICATE CUSTOMER IDS */

        (
            SELECT COUNT(*)

            FROM (

                SELECT customer_id

                FROM reporting.vw_pbi_customer_detail

                GROUP BY customer_id

                HAVING COUNT(*) > 1

            ) duplicate_ids

        ) AS duplicate_customer_ids,


        /* CORE MISSING FIELDS */

        (
            SELECT COUNT(*)
            FROM reporting.vw_pbi_customer_detail
            WHERE customer_id IS NULL
               OR TRIM(customer_id) = ''
        ) AS missing_customer_id,


        (
            SELECT COUNT(*)
            FROM reporting.vw_pbi_customer_detail
            WHERE age IS NULL
        ) AS missing_age,


        (
            SELECT COUNT(*)
            FROM reporting.vw_pbi_customer_detail
            WHERE tenure_in_months IS NULL
        ) AS missing_tenure,


        (
            SELECT COUNT(*)
            FROM reporting.vw_pbi_customer_detail
            WHERE contract IS NULL
        ) AS missing_contract,


        (
            SELECT COUNT(*)
            FROM reporting.vw_pbi_customer_detail
            WHERE monthly_charge IS NULL
        ) AS missing_monthly_charge,


        (
            SELECT COUNT(*)
            FROM reporting.vw_pbi_customer_detail
            WHERE churn_value IS NULL
        ) AS missing_churn_value,


        (
            SELECT COUNT(*)
            FROM reporting.vw_pbi_customer_detail
            WHERE retention_priority IS NULL
        ) AS missing_retention_priority,


        (
            SELECT COUNT(*)
            FROM reporting.vw_pbi_customer_detail
            WHERE retention_segment IS NULL
        ) AS missing_retention_segment

)

SELECT

    dq.*,


    CASE

        WHEN pbi_customer_rows = pbi_unique_customers

         AND duplicate_customer_ids = 0

         AND missing_customer_id = 0

         AND missing_churn_value = 0

            THEN 'PASS'

        ELSE 'REVIEW'

    END AS customer_grain_status,


    CASE

        WHEN demographics_rows = location_rows

         AND demographics_rows = services_rows

         AND demographics_rows = status_rows

         AND analytics_rows = pbi_customer_rows

         AND analytics_unique_customers =
             pbi_unique_customers

            THEN 'PASS'

        ELSE 'REVIEW'

    END AS pipeline_reconciliation_status


FROM dq;


/* =========================================================
   SECTION 14
   TEST POWER BI EXECUTIVE KPI VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_pbi_executive_kpis;


/* Expected:
   1 row
*/


/* =========================================================
   SECTION 15
   TEST CUSTOMER STATUS VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_pbi_customer_status
ORDER BY customer_status_sort;


/* Typically:
   Stayed
   Joined
   Churned
*/


/* =========================================================
   SECTION 16
   TEST CHURN OUTCOME VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_pbi_churn_outcome
ORDER BY churn_status_sort;


/* Expected:
   Not Churned
   Churned
*/


/* =========================================================
   SECTION 17
   TEST CHURN DRIVER VIEW
   ========================================================= */

SELECT
    driver_name,
    driver_value,
    customers,
    churn_rate_pct,
    overall_churn_rate_pct,
    churn_rate_gap_pp,
    churn_lift,
    relative_churn_band,
    meets_minimum_segment_size

FROM reporting.vw_pbi_churn_drivers

ORDER BY
    driver_name_sort,
    driver_sort;


/* =========================================================
   SECTION 18
   TEST TOP ELEVATED CHURN SEGMENTS
   ========================================================= */

SELECT
    driver_name,
    driver_value,
    customers,
    churn_rate_pct,
    churn_rate_gap_pp,
    churn_lift

FROM reporting.vw_pbi_churn_drivers

WHERE meets_minimum_segment_size IS TRUE
  AND is_above_average_churn IS TRUE

ORDER BY churn_lift DESC

LIMIT 20;


/* =========================================================
   SECTION 19
   TEST CHURN REASON VIEW
   ========================================================= */

SELECT
    churn_category,
    churn_reason,
    churned_customers,
    share_of_total_churn_pct,
    monthly_charge_base,
    share_of_churned_monthly_charge_pct,
    total_cltv,
    rank_by_customer_count,
    rank_by_monthly_charge

FROM reporting.vw_pbi_churn_reasons

ORDER BY rank_by_customer_count

LIMIT 20;


/* =========================================================
   SECTION 20
   TEST CHURN CATEGORY VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_pbi_churn_category
ORDER BY rank_by_customer_count;


/* =========================================================
   SECTION 21
   TEST RETENTION PRIORITY VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_pbi_retention_priority
ORDER BY retention_priority_sort;


/* =========================================================
   SECTION 22
   TEST RETENTION SEGMENT VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_pbi_retention_segment
ORDER BY retention_segment_sort;


/* =========================================================
   SECTION 23
   TEST DATA QUALITY VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_pbi_data_quality;


/* Ideally:

   customer_grain_status         = PASS
   pipeline_reconciliation_status = PASS
*/


/* =========================================================
   SECTION 24
   RECONCILE MAIN CUSTOMER COUNT
   ========================================================= */

SELECT

    (
        SELECT COUNT(*)
        FROM analytics.customer_churn_clean
    ) AS analytics_customers,


    (
        SELECT COUNT(*)
        FROM reporting.vw_pbi_customer_detail
    ) AS pbi_customers,


    (
        SELECT total_customers
        FROM reporting.vw_pbi_executive_kpis
    ) AS executive_kpi_customers;


/* All three must match.
   Expected = 7043
*/


/* =========================================================
   SECTION 25
   RECONCILE CUSTOMER STATUS
   ========================================================= */

SELECT
    SUM(customers)
        AS customers_from_status_view

FROM reporting.vw_pbi_customer_status;


/* Compare against total customer count.
*/


/* =========================================================
   SECTION 26
   RECONCILE CHURN OUTCOME
   ========================================================= */

SELECT
    SUM(customers)
        AS customers_from_churn_view

FROM reporting.vw_pbi_churn_outcome;


/* Compare against total customer count.
*/


/* =========================================================
   SECTION 27
   RECONCILE CHURNED CUSTOMERS
   ========================================================= */

SELECT

    (
        SELECT COUNT(*)
        FROM reporting.vw_pbi_customer_detail
        WHERE churn_value = 1
    ) AS churned_from_customer_detail,


    (
        SELECT SUM(churned_customers)
        FROM reporting.vw_pbi_churn_reasons
    ) AS churned_from_reason_view,


    (
        SELECT churned_customers
        FROM reporting.vw_pbi_executive_kpis
    ) AS churned_from_kpi_view;


/* All three must match.
*/


/* =========================================================
   SECTION 28
   RECONCILE EXISTING CUSTOMER PRIORITIES
   ========================================================= */

SELECT

    (
        SELECT COUNT(*)
        FROM reporting.vw_pbi_customer_detail
        WHERE customer_status = 'Stayed'
    ) AS stayed_customers,


    (
        SELECT SUM(customers)
        FROM reporting.vw_pbi_retention_priority
    ) AS customers_from_priority_view,


    (
        SELECT SUM(customers)
        FROM reporting.vw_pbi_retention_segment
    ) AS customers_from_segment_view;


/* All three must match.
*/


/* =========================================================
   SECTION 29
   RECONCILE MONTHLY CHARGE
   ========================================================= */

SELECT

    ROUND(
        SUM(monthly_charge),
        2
    ) AS customer_detail_monthly_charge_base,


    (
        SELECT total_monthly_charge_base
        FROM reporting.vw_pbi_executive_kpis
    ) AS executive_monthly_charge_base

FROM reporting.vw_pbi_customer_detail;


/* Values must match.
*/


/* =========================================================
   SECTION 30
   RECONCILE PRIORITY RETENTION POPULATION
   ========================================================= */

SELECT

    (
        SELECT COUNT(*)

        FROM reporting.vw_pbi_customer_detail

        WHERE is_priority_retention_target IS TRUE

    ) AS priority_customers_from_detail,


    (
        SELECT priority_retention_customers

        FROM reporting.vw_pbi_executive_kpis

    ) AS priority_customers_from_kpi;


/* Values must match.
*/


/* =========================================================
   SECTION 31
   AUDIT FINAL POWER BI VIEW INVENTORY
   ========================================================= */

SELECT
    table_schema,
    table_name

FROM information_schema.views

WHERE table_schema = 'reporting'

  AND table_name LIKE 'vw_pbi_%'

ORDER BY table_name;


/* Expected Power BI layer:

   vw_pbi_churn_category
   vw_pbi_churn_drivers
   vw_pbi_churn_outcome
   vw_pbi_churn_reasons
   vw_pbi_customer_detail
   vw_pbi_customer_status
   vw_pbi_data_quality
   vw_pbi_executive_kpis
   vw_pbi_retention_priority
   vw_pbi_retention_segment
*/


/* =========================================================
   SECTION 32
   FINAL METHODOLOGY NOTES

   1. vw_pbi_customer_detail is the primary interactive
      Power BI table.

   2. Its grain is exactly one row per customer.

   3. Summary views are primarily SQL benchmarks and
      specialised reporting sources.

   4. Summary views should not automatically be related to
      one another in Power BI.

   5. KPI cards that need to respond to dashboard slicers
      should eventually be built using DAX measures over
      vw_pbi_customer_detail.

   6. Churn Score is deliberately excluded from the Power BI
      driver layer.

   7. Churn-driver results describe historical associations,
      not causal relationships.

   8. Retention Priority is a transparent business rule,
      not predicted churn probability.

   9. Monthly Charge Base is a billing-value proxy, not
      guaranteed future revenue.

   10. CLTV represents customer-value potential and should
       not be described as guaranteed future cash flow.

   ========================================================= */


/* =========================================================
   END OF SCRIPT
   ========================================================= */



SELECT *
FROM reporting.vw_pbi_data_quality;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM reporting.vw_pbi_customer_detail;

SELECT
    customer_id,
    customer_status,
    churn_status,
    gender,
    age_band,
    tenure_band,
    contract,
    payment_method,
    internet_type,
    monthly_charge,
    customer_value_segment,
    satisfaction_score,
    retention_signal_count,
    priority_score,
    retention_priority,
    retention_segment,
    suggested_action

FROM reporting.vw_pbi_customer_detail

LIMIT 25;

SELECT *
FROM reporting.vw_pbi_executive_kpis;

SELECT
    driver_name,
    driver_value,
    customers,
    churn_rate_pct,
    overall_churn_rate_pct,
    churn_rate_gap_pp,
    churn_lift,
    relative_churn_band

FROM reporting.vw_pbi_churn_drivers

WHERE meets_minimum_segment_size IS TRUE

ORDER BY churn_lift DESC

LIMIT 15;

SELECT
    retention_priority,
    customers,
    customer_share_pct,
    monthly_charge_base,
    monthly_charge_share_pct,
    total_cltv,
    cltv_share_pct

FROM reporting.vw_pbi_retention_priority

ORDER BY retention_priority_sort;

SELECT
    churn_category,
    churn_reason,
    churned_customers,
    monthly_charge_base,
    total_cltv

FROM reporting.vw_pbi_churn_reasons

ORDER BY rank_by_monthly_charge

LIMIT 10;

