/* =========================================================
   PROJECT 3: CUSTOMER CHURN, RETENTION & REVENUE RISK
   SCRIPT: 07_retention_segmentation.sql

   PURPOSE:
   1. Translate churn-driver findings into actionable
      retention signals.
   2. Combine retention signals with customer value.
   3. Create a transparent business priority score.
   4. Segment existing, new and churned customers.
   5. Assign recommended business actions.
   6. Create Power BI-ready reporting views.

   IMPORTANT:
   This is a rule-based business prioritisation framework.
   It is NOT a machine-learning churn prediction model.

   SOURCE:
   analytics.customer_churn_clean

   OUTPUT VIEWS:
   reporting.vw_retention_customer_priority
   reporting.vw_retention_priority_summary
   reporting.vw_retention_segment_summary
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
   7043 rows
   7043 unique customers
*/


/* =========================================================
   SECTION 2
   REVIEW CUSTOMER STATUS
   ========================================================= */

SELECT
    customer_status,
    COUNT(*) AS customers
FROM analytics.customer_churn_clean
GROUP BY customer_status
ORDER BY customers DESC;


/* =========================================================
   SECTION 3
   REVIEW STEP 7 ELEVATED-CHURN SEGMENTS

   Use this output to confirm the appropriateness of the
   retention signals used later in this script.
   ========================================================= */

SELECT
    risk_rank,
    driver_name,
    driver_value,
    customers,
    churn_rate_pct,
    overall_churn_rate_pct,
    churn_rate_gap_pp,
    churn_lift
FROM reporting.vw_top_churn_risk_segments
ORDER BY risk_rank
LIMIT 20;


/* =========================================================
   SECTION 4
   CREATE CUSTOMER-LEVEL RETENTION PRIORITY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_retention_customer_priority AS

WITH base_signals AS (

    SELECT

        /* CUSTOMER IDENTIFICATION */

        customer_id,

        customer_status,

        churn_value,

        gender,

        age,

        age_band,

        city,

        zip_code,


        /* CUSTOMER VALUE */

        customer_value_segment,

        customer_value_segment_sort,

        cltv,


        CASE
            WHEN customer_value_segment = 'Very High Value'
                THEN 3

            WHEN customer_value_segment = 'High Value'
                THEN 2

            WHEN customer_value_segment = 'Medium Value'
                THEN 1

            ELSE 0
        END AS value_weight,


        /* COMMERCIAL / RELATIONSHIP FIELDS */

        tenure_in_months,

        tenure_band,

        contract,

        monthly_charge,

        monthly_charge_band,

        total_revenue,

        satisfaction_score,

        premium_tech_support,

        internet_service,

        referred_a_friend,

        number_of_referrals,

        service_count,


        /* -------------------------------------------------
           RETENTION SIGNAL 1:
           EARLY TENURE
           ------------------------------------------------- */

        CASE
            WHEN tenure_in_months <= 12
                THEN 1
            ELSE 0
        END AS early_tenure_signal,


        /* -------------------------------------------------
           RETENTION SIGNAL 2:
           MONTH-TO-MONTH CONTRACT
           ------------------------------------------------- */

        CASE
            WHEN contract = 'Month-to-Month'
                THEN 1
            ELSE 0
        END AS month_to_month_signal,


        /* -------------------------------------------------
           RETENTION SIGNAL 3:
           LOW SATISFACTION
           ------------------------------------------------- */

        CASE
            WHEN satisfaction_score <= 2
                THEN 1
            ELSE 0
        END AS low_satisfaction_signal,


        /* -------------------------------------------------
           RETENTION SIGNAL 4:
           NO PREMIUM TECH SUPPORT

           Only customers with internet service are flagged.
           ------------------------------------------------- */

        CASE
            WHEN internet_service IS TRUE
             AND LOWER(
                    COALESCE(
                        premium_tech_support,
                        ''
                    )
                 ) = 'no'
                THEN 1

            ELSE 0
        END AS no_tech_support_signal,


        /* -------------------------------------------------
           RETENTION SIGNAL 5:
           NO REFERRAL RELATIONSHIP
           ------------------------------------------------- */

        CASE
            WHEN referred_a_friend IS FALSE
                THEN 1
            ELSE 0
        END AS no_referral_signal,


        /* -------------------------------------------------
           RETENTION SIGNAL 6:
           LOW SERVICE DEPTH
           ------------------------------------------------- */

        CASE
            WHEN service_count <= 2
                THEN 1
            ELSE 0
        END AS low_service_depth_signal,


        /* -------------------------------------------------
           RETENTION SIGNAL 7:
           VERY HIGH MONTHLY CHARGE
           ------------------------------------------------- */

        CASE
            WHEN monthly_charge_band = 'Very High'
                THEN 1
            ELSE 0
        END AS high_charge_signal


    FROM analytics.customer_churn_clean

),


signal_totals AS (

    SELECT

        b.*,


        (
            early_tenure_signal
            +
            month_to_month_signal
            +
            low_satisfaction_signal
            +
            no_tech_support_signal
            +
            no_referral_signal
            +
            low_service_depth_signal
            +
            high_charge_signal
        ) AS retention_signal_count


    FROM base_signals b

),


scored_customers AS (

    SELECT

        s.*,


        /* -------------------------------------------------
           PRIORITY SCORE

           Retention signals + customer value weight.

           This is a business prioritisation score,
           NOT predicted churn probability.
           ------------------------------------------------- */

        (
            retention_signal_count
            +
            value_weight
        ) AS priority_score


    FROM signal_totals s

),


segmented_customers AS (

    SELECT

        sc.*,


        /* -------------------------------------------------
           RETENTION PRIORITY
           ------------------------------------------------- */

        CASE

            /* Already churned */

            WHEN customer_status = 'Churned'
                THEN 'Churned - Win-Back'


            /* Newly joined customer */

            WHEN customer_status = 'Joined'
                THEN 'New Customer - Onboarding'


            /* Existing customers */

            WHEN customer_status = 'Stayed'
             AND priority_score >= 7
                THEN 'P1 - Critical Retention'


            WHEN customer_status = 'Stayed'
             AND priority_score BETWEEN 5 AND 6
                THEN 'P2 - Proactive Retention'


            WHEN customer_status = 'Stayed'
             AND priority_score BETWEEN 3 AND 4
                THEN 'P3 - Monitor'


            WHEN customer_status = 'Stayed'
             AND priority_score <= 2
                THEN 'P4 - Stable / Loyalty'


            ELSE 'Review'
        END AS retention_priority,


        /* -------------------------------------------------
           PRIORITY SORT
           ------------------------------------------------- */

        CASE

            WHEN customer_status = 'Stayed'
             AND priority_score >= 7
                THEN 1

            WHEN customer_status = 'Stayed'
             AND priority_score BETWEEN 5 AND 6
                THEN 2

            WHEN customer_status = 'Stayed'
             AND priority_score BETWEEN 3 AND 4
                THEN 3

            WHEN customer_status = 'Stayed'
             AND priority_score <= 2
                THEN 4

            WHEN customer_status = 'Joined'
                THEN 5

            WHEN customer_status = 'Churned'
                THEN 6

            ELSE 99

        END AS retention_priority_sort,


        /* -------------------------------------------------
           BUSINESS RETENTION SEGMENT
           ------------------------------------------------- */

        CASE

            WHEN customer_status = 'Churned'
                THEN 'Churned / Win-Back'


            WHEN customer_status = 'Joined'
                THEN 'New Customer'


            WHEN customer_status = 'Stayed'
             AND customer_value_segment IN (
                    'High Value',
                    'Very High Value'
                 )
             AND retention_signal_count >= 3
                THEN 'High-Value At-Risk'


            WHEN customer_status = 'Stayed'
             AND customer_value_segment IN (
                    'High Value',
                    'Very High Value'
                 )
             AND retention_signal_count < 3
                THEN 'High-Value Stable'


            WHEN customer_status = 'Stayed'
             AND customer_value_segment IN (
                    'Low Value',
                    'Medium Value'
                 )
             AND retention_signal_count >= 3
                THEN 'Elevated-Risk Standard Value'


            WHEN customer_status = 'Stayed'
             AND retention_signal_count BETWEEN 1 AND 2
                THEN 'Monitor'


            WHEN customer_status = 'Stayed'
             AND retention_signal_count = 0
                THEN 'Loyalty / Expansion'


            ELSE 'Review'

        END AS retention_segment,


        /* -------------------------------------------------
           SUGGESTED BUSINESS ACTION
           ------------------------------------------------- */

        CASE

            WHEN customer_status = 'Churned'
                THEN 'Targeted win-back campaign'


            WHEN customer_status = 'Joined'
                THEN 'Structured onboarding and early engagement'


            WHEN customer_status = 'Stayed'
             AND customer_value_segment IN (
                    'High Value',
                    'Very High Value'
                 )
             AND retention_signal_count >= 3
                THEN 'Personalised retention outreach'


            WHEN customer_status = 'Stayed'
             AND customer_value_segment IN (
                    'High Value',
                    'Very High Value'
                 )
             AND retention_signal_count < 3
                THEN 'Loyalty recognition and cross-sell'


            WHEN customer_status = 'Stayed'
             AND customer_value_segment IN (
                    'Low Value',
                    'Medium Value'
                 )
             AND retention_signal_count >= 3
                THEN 'Digital retention campaign'


            WHEN customer_status = 'Stayed'
             AND retention_signal_count BETWEEN 1 AND 2
                THEN 'Monitor and targeted engagement'


            WHEN customer_status = 'Stayed'
             AND retention_signal_count = 0
                THEN 'Referral, loyalty or expansion offer'


            ELSE 'Manual review'

        END AS suggested_action


    FROM scored_customers sc

)


SELECT *
FROM segmented_customers;


/* =========================================================
   SECTION 5
   CREATE RETENTION PRIORITY SUMMARY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_retention_priority_summary AS

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

GROUP BY
    retention_priority,
    retention_priority_sort;


/* =========================================================
   SECTION 6
   CREATE RETENTION SEGMENT SUMMARY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_retention_segment_summary AS

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

GROUP BY
    retention_segment,
    suggested_action;


/* =========================================================
   SECTION 7
   VALIDATE CUSTOMER COUNT
   ========================================================= */

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM reporting.vw_retention_customer_priority;


/* Expected:
   total_rows       = 7043
   unique_customers = 7043
*/


/* =========================================================
   SECTION 8
   CHECK MISSING PRIORITY / SEGMENT / ACTION
   ========================================================= */

SELECT

    COUNT(*) FILTER (
        WHERE retention_priority IS NULL
    ) AS missing_priority,

    COUNT(*) FILTER (
        WHERE retention_segment IS NULL
    ) AS missing_segment,

    COUNT(*) FILTER (
        WHERE suggested_action IS NULL
    ) AS missing_action

FROM reporting.vw_retention_customer_priority;


/* Expected:
   0
   0
   0
*/


/* =========================================================
   SECTION 9
   CHECK RETENTION SIGNAL DISTRIBUTION
   ========================================================= */

SELECT
    retention_signal_count,
    COUNT(*) AS customers
FROM reporting.vw_retention_customer_priority
GROUP BY retention_signal_count
ORDER BY retention_signal_count;


/* =========================================================
   SECTION 10
   CHECK PRIORITY SCORE DISTRIBUTION
   ========================================================= */

SELECT
    priority_score,
    COUNT(*) AS customers
FROM reporting.vw_retention_customer_priority
GROUP BY priority_score
ORDER BY priority_score;


/* =========================================================
   SECTION 11
   RETENTION PRIORITY DISTRIBUTION
   ========================================================= */

SELECT
    retention_priority,
    retention_priority_sort,
    customers,
    customer_share_pct,
    avg_retention_signals,
    avg_priority_score,
    avg_monthly_charge,
    monthly_charge_base,
    avg_cltv,
    total_cltv
FROM reporting.vw_retention_priority_summary
ORDER BY retention_priority_sort;


/* =========================================================
   SECTION 12
   RETENTION SEGMENT DISTRIBUTION
   ========================================================= */

SELECT
    retention_segment,
    customers,
    customer_share_pct,
    avg_retention_signals,
    avg_priority_score,
    monthly_charge_base,
    avg_cltv,
    total_cltv,
    suggested_action
FROM reporting.vw_retention_segment_summary
ORDER BY customers DESC;


/* =========================================================
   SECTION 13
   EXISTING CUSTOMER PRIORITIES ONLY
   ========================================================= */

SELECT
    retention_priority,
    retention_priority_sort,
    COUNT(*) AS customers
FROM reporting.vw_retention_customer_priority
WHERE customer_status = 'Stayed'
GROUP BY
    retention_priority,
    retention_priority_sort
ORDER BY retention_priority_sort;


/* =========================================================
   SECTION 14
   HIGH-VALUE AT-RISK CUSTOMERS
   ========================================================= */

SELECT
    COUNT(*) AS high_value_at_risk_customers,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS monthly_charge_base,

    ROUND(
        SUM(cltv),
        2
    ) AS total_cltv,

    ROUND(
        AVG(retention_signal_count),
        2
    ) AS avg_retention_signals

FROM reporting.vw_retention_customer_priority

WHERE retention_segment = 'High-Value At-Risk';


/* =========================================================
   SECTION 15
   P1 CRITICAL RETENTION CUSTOMERS
   ========================================================= */

SELECT

    COUNT(*) AS p1_customers,

    ROUND(
        SUM(monthly_charge),
        2
    ) AS p1_monthly_charge_base,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS p1_avg_monthly_charge,

    ROUND(
        SUM(cltv),
        2
    ) AS p1_total_cltv,

    ROUND(
        AVG(cltv),
        2
    ) AS p1_avg_cltv

FROM reporting.vw_retention_customer_priority

WHERE retention_priority = 'P1 - Critical Retention';


/* =========================================================
   SECTION 16
   CHECK THAT CHURNED CUSTOMERS ARE NOT P1-P4
   ========================================================= */

SELECT
    COUNT(*) AS invalid_churned_priority
FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Churned'

AND retention_priority LIKE 'P%';


/* Expected:
   0
*/


/* =========================================================
   SECTION 17
   CHECK THAT JOINED CUSTOMERS ARE NOT P1-P4
   ========================================================= */

SELECT
    COUNT(*) AS invalid_joined_priority
FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Joined'

AND retention_priority LIKE 'P%';


/* Expected:
   0
*/


/* =========================================================
   SECTION 18
   RECONCILE PRIORITY SUMMARY
   ========================================================= */

SELECT
    SUM(customers)
        AS customers_from_priority_summary
FROM reporting.vw_retention_priority_summary;


/* Expected:
   7043
*/


/* =========================================================
   SECTION 19
   RECONCILE SEGMENT SUMMARY
   ========================================================= */

SELECT
    SUM(customers)
        AS customers_from_segment_summary
FROM reporting.vw_retention_segment_summary;


/* Expected:
   7043
*/


/* =========================================================
   SECTION 20
   VIEW HIGH-PRIORITY CUSTOMER SAMPLE
   ========================================================= */

SELECT
    customer_id,
    customer_value_segment,
    tenure_in_months,
    contract,
    satisfaction_score,
    premium_tech_support,
    referred_a_friend,
    service_count,
    monthly_charge,
    cltv,
    retention_signal_count,
    priority_score,
    retention_priority,
    retention_segment,
    suggested_action

FROM reporting.vw_retention_customer_priority

WHERE retention_priority IN (
    'P1 - Critical Retention',
    'P2 - Proactive Retention'
)

ORDER BY
    retention_priority_sort,
    priority_score DESC,
    cltv DESC

LIMIT 50;


/* =========================================================
   SECTION 21
   SIGNAL PREVALENCE AMONG STAYED CUSTOMERS
   ========================================================= */

SELECT

    COUNT(*) AS stayed_customers,


    SUM(early_tenure_signal)
        AS early_tenure_customers,


    SUM(month_to_month_signal)
        AS month_to_month_customers,


    SUM(low_satisfaction_signal)
        AS low_satisfaction_customers,


    SUM(no_tech_support_signal)
        AS no_tech_support_customers,


    SUM(no_referral_signal)
        AS no_referral_customers,


    SUM(low_service_depth_signal)
        AS low_service_depth_customers,


    SUM(high_charge_signal)
        AS high_charge_customers


FROM reporting.vw_retention_customer_priority

WHERE customer_status = 'Stayed';


/* =========================================================
   SECTION 22
   CHECK REPORTING VIEWS
   ========================================================= */

SELECT
    table_schema,
    table_name

FROM information_schema.views

WHERE table_schema = 'reporting'

ORDER BY table_name;


/* Step 8 should add:

   reporting.vw_retention_customer_priority
   reporting.vw_retention_priority_summary
   reporting.vw_retention_segment_summary
*/


/* =========================================================
   SECTION 23
   METHODOLOGY NOTES

   1. This framework is descriptive and rule-based.

   2. It does not estimate individual churn probability.

   3. Retention signals should be reviewed against the
      actual Step 7 churn-driver findings.

   4. Customer value is represented using the CLTV-based
      value segment created in Step 5.

   5. Existing, new and churned customers are deliberately
      treated separately.

   6. Churn Score from the original IBM dataset is NOT used.

   7. Monthly Charge Base is a billing-value proxy, not
      guaranteed recurring revenue.

   8. CLTV is a customer-value measure and should not be
      described as guaranteed future cash revenue.

   ========================================================= */


/* =========================================================
   END OF SCRIPT
   ========================================================= */