/* =========================================================
   PROJECT 3: CUSTOMER CHURN, RETENTION & REVENUE RISK
   SCRIPT: 04_create_analytics_layer.sql

   PURPOSE:
   1. Preserve staging tables unchanged.
   2. Join all five IBM Telco source tables.
   3. Clean text values.
   4. Convert numeric fields to appropriate PostgreSQL types.
   5. Create customer-level analytical features.
   6. Create an analysis-ready customer table.
   7. Validate final customer count and data quality.

   TARGET TABLE:
   analytics.customer_churn_clean
   ========================================================= */


/* =========================================================
   SECTION 1
   REMOVE PREVIOUS ANALYTICS TABLE IF IT EXISTS

   This makes the script rerunnable during development.
   It DOES NOT affect staging data.
   ========================================================= */

DROP TABLE IF EXISTS analytics.customer_churn_clean;


/* =========================================================
   SECTION 2
   CREATE THE CLEAN CUSTOMER-LEVEL ANALYTICS TABLE
   ========================================================= */

CREATE TABLE analytics.customer_churn_clean AS

WITH cleaned_source AS (

    SELECT

        /* -------------------------------------------------
           CUSTOMER IDENTIFICATION
           ------------------------------------------------- */

        TRIM(d.customer_id) AS customer_id,

        NULLIF(TRIM(s.quarter), '') AS quarter,


        /* -------------------------------------------------
           DEMOGRAPHICS
           ------------------------------------------------- */

        NULLIF(TRIM(d.gender), '') AS gender,


        CASE
            WHEN NULLIF(TRIM(d.age), '') IS NOT NULL
             AND TRIM(d.age) ~ '^[0-9]+$'
            THEN TRIM(d.age)::INTEGER
            ELSE NULL
        END AS age,


        CASE
            WHEN LOWER(TRIM(d.under_30)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(d.under_30)) = 'no'  THEN FALSE
            ELSE NULL
        END AS under_30,


        CASE
            WHEN LOWER(TRIM(d.senior_citizen)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(d.senior_citizen)) = 'no'  THEN FALSE
            ELSE NULL
        END AS senior_citizen,


        CASE
            WHEN LOWER(TRIM(d.married)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(d.married)) = 'no'  THEN FALSE
            ELSE NULL
        END AS married,


        CASE
            WHEN LOWER(TRIM(d.dependents)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(d.dependents)) = 'no'  THEN FALSE
            ELSE NULL
        END AS dependents,


        CASE
            WHEN NULLIF(TRIM(d.number_of_dependents), '') IS NOT NULL
             AND TRIM(d.number_of_dependents) ~ '^[0-9]+$'
            THEN TRIM(d.number_of_dependents)::INTEGER
            ELSE NULL
        END AS number_of_dependents,


        /* -------------------------------------------------
           LOCATION
           ------------------------------------------------- */

        NULLIF(TRIM(l.country), '') AS country,

        NULLIF(TRIM(l.state), '') AS state,

        NULLIF(TRIM(l.city), '') AS city,

        NULLIF(TRIM(l.zip_code), '') AS zip_code,


        CASE
            WHEN NULLIF(TRIM(l.latitude), '') IS NOT NULL
             AND TRIM(l.latitude)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(l.latitude)::NUMERIC(10,6)
            ELSE NULL
        END AS latitude,


        CASE
            WHEN NULLIF(TRIM(l.longitude), '') IS NOT NULL
             AND TRIM(l.longitude)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(l.longitude)::NUMERIC(10,6)
            ELSE NULL
        END AS longitude,


        CASE
            WHEN NULLIF(TRIM(p.population), '') IS NOT NULL
             AND TRIM(p.population) ~ '^[0-9]+$'
            THEN TRIM(p.population)::INTEGER
            ELSE NULL
        END AS population,


        /* -------------------------------------------------
           CUSTOMER RELATIONSHIP / TENURE
           ------------------------------------------------- */

        CASE
            WHEN LOWER(TRIM(s.referred_a_friend)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(s.referred_a_friend)) = 'no'  THEN FALSE
            ELSE NULL
        END AS referred_a_friend,


        CASE
            WHEN NULLIF(TRIM(s.number_of_referrals), '') IS NOT NULL
             AND TRIM(s.number_of_referrals) ~ '^[0-9]+$'
            THEN TRIM(s.number_of_referrals)::INTEGER
            ELSE NULL
        END AS number_of_referrals,


        CASE
            WHEN NULLIF(TRIM(s.tenure_in_months), '') IS NOT NULL
             AND TRIM(s.tenure_in_months) ~ '^[0-9]+$'
            THEN TRIM(s.tenure_in_months)::INTEGER
            ELSE NULL
        END AS tenure_in_months,


        COALESCE(
            NULLIF(TRIM(s.offer), ''),
            'None'
        ) AS offer,


        /* -------------------------------------------------
           PHONE / INTERNET SERVICES
           ------------------------------------------------- */

        CASE
            WHEN LOWER(TRIM(s.phone_service)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(s.phone_service)) = 'no'  THEN FALSE
            ELSE NULL
        END AS phone_service,


        CASE
            WHEN NULLIF(
                    TRIM(s.avg_monthly_long_distance_charges),
                    ''
                 ) IS NOT NULL
             AND TRIM(s.avg_monthly_long_distance_charges)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(
                    s.avg_monthly_long_distance_charges
                 )::NUMERIC(12,2)
            ELSE NULL
        END AS avg_monthly_long_distance_charges,


        COALESCE(
            NULLIF(TRIM(s.multiple_lines), ''),
            'Not Applicable'
        ) AS multiple_lines,


        CASE
            WHEN LOWER(TRIM(s.internet_service)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(s.internet_service)) = 'no'  THEN FALSE
            ELSE NULL
        END AS internet_service,


        COALESCE(
            NULLIF(TRIM(s.internet_type), ''),
            'No Internet'
        ) AS internet_type,


        CASE
            WHEN NULLIF(TRIM(s.avg_monthly_gb_download), '') IS NOT NULL
             AND TRIM(s.avg_monthly_gb_download)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(s.avg_monthly_gb_download)::NUMERIC(12,2)
            ELSE NULL
        END AS avg_monthly_gb_download,


        COALESCE(
            NULLIF(TRIM(s.online_security), ''),
            'Not Applicable'
        ) AS online_security,


        COALESCE(
            NULLIF(TRIM(s.online_backup), ''),
            'Not Applicable'
        ) AS online_backup,


        COALESCE(
            NULLIF(TRIM(s.device_protection_plan), ''),
            'Not Applicable'
        ) AS device_protection_plan,


        COALESCE(
            NULLIF(TRIM(s.premium_tech_support), ''),
            'Not Applicable'
        ) AS premium_tech_support,


        COALESCE(
            NULLIF(TRIM(s.streaming_tv), ''),
            'Not Applicable'
        ) AS streaming_tv,


        COALESCE(
            NULLIF(TRIM(s.streaming_movies), ''),
            'Not Applicable'
        ) AS streaming_movies,


        COALESCE(
            NULLIF(TRIM(s.streaming_music), ''),
            'Not Applicable'
        ) AS streaming_music,


        COALESCE(
            NULLIF(TRIM(s.unlimited_data), ''),
            'Not Applicable'
        ) AS unlimited_data,


        /* -------------------------------------------------
           CONTRACT / BILLING
           ------------------------------------------------- */

        NULLIF(TRIM(s.contract), '') AS contract,


        CASE
            WHEN LOWER(TRIM(s.paperless_billing)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(s.paperless_billing)) = 'no'  THEN FALSE
            ELSE NULL
        END AS paperless_billing,


        NULLIF(TRIM(s.payment_method), '') AS payment_method,


        /* -------------------------------------------------
           FINANCIAL FIELDS
           ------------------------------------------------- */

        CASE
            WHEN NULLIF(TRIM(s.monthly_charge), '') IS NOT NULL
             AND TRIM(s.monthly_charge)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(s.monthly_charge)::NUMERIC(12,2)
            ELSE NULL
        END AS monthly_charge,


        CASE
            WHEN NULLIF(TRIM(s.total_charges), '') IS NOT NULL
             AND TRIM(s.total_charges)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(s.total_charges)::NUMERIC(14,2)
            ELSE NULL
        END AS total_charges,


        CASE
            WHEN NULLIF(TRIM(s.total_refunds), '') IS NOT NULL
             AND TRIM(s.total_refunds)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(s.total_refunds)::NUMERIC(14,2)
            ELSE NULL
        END AS total_refunds,


        CASE
            WHEN NULLIF(
                    TRIM(s.total_extra_data_charges),
                    ''
                 ) IS NOT NULL
             AND TRIM(s.total_extra_data_charges)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(
                    s.total_extra_data_charges
                 )::NUMERIC(14,2)
            ELSE NULL
        END AS total_extra_data_charges,


        CASE
            WHEN NULLIF(
                    TRIM(s.total_long_distance_charges),
                    ''
                 ) IS NOT NULL
             AND TRIM(s.total_long_distance_charges)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(
                    s.total_long_distance_charges
                 )::NUMERIC(14,2)
            ELSE NULL
        END AS total_long_distance_charges,


        CASE
            WHEN NULLIF(TRIM(s.total_revenue), '') IS NOT NULL
             AND TRIM(s.total_revenue)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(s.total_revenue)::NUMERIC(14,2)
            ELSE NULL
        END AS total_revenue,


        /* -------------------------------------------------
           CUSTOMER STATUS / CHURN
           ------------------------------------------------- */

        CASE
            WHEN NULLIF(TRIM(st.satisfaction_score), '') IS NOT NULL
             AND TRIM(st.satisfaction_score) ~ '^[0-9]+$'
            THEN TRIM(st.satisfaction_score)::INTEGER
            ELSE NULL
        END AS satisfaction_score,


        NULLIF(TRIM(st.customer_status), '') AS customer_status,


        NULLIF(TRIM(st.churn_label), '') AS churn_label,


        CASE
            WHEN NULLIF(TRIM(st.churn_value), '') IS NOT NULL
             AND TRIM(st.churn_value) ~ '^[01]$'
            THEN TRIM(st.churn_value)::INTEGER
            ELSE NULL
        END AS churn_value,


        CASE
            WHEN NULLIF(TRIM(st.churn_score), '') IS NOT NULL
             AND TRIM(st.churn_score) ~ '^[0-9]+$'
            THEN TRIM(st.churn_score)::INTEGER
            ELSE NULL
        END AS churn_score,


        CASE
            WHEN NULLIF(TRIM(st.cltv), '') IS NOT NULL
             AND TRIM(st.cltv)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(st.cltv)::NUMERIC(14,2)
            ELSE NULL
        END AS cltv,


        NULLIF(TRIM(st.churn_category), '') AS churn_category,

        NULLIF(TRIM(st.churn_reason), '') AS churn_reason


    FROM staging.demographics_raw d


    LEFT JOIN staging.services_raw s
        ON TRIM(d.customer_id) = TRIM(s.customer_id)


    LEFT JOIN staging.status_raw st
        ON TRIM(d.customer_id) = TRIM(st.customer_id)


    LEFT JOIN staging.location_raw l
        ON TRIM(d.customer_id) = TRIM(l.customer_id)


    LEFT JOIN staging.population_raw p
        ON TRIM(l.zip_code) = TRIM(p.zip_code)

),


/* =========================================================
   SECTION 3
   CALCULATE DATA-DRIVEN QUARTILE THRESHOLDS
   ========================================================= */

thresholds AS (

    SELECT

        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY monthly_charge)
            AS monthly_charge_q1,

        PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY monthly_charge)
            AS monthly_charge_q2,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY monthly_charge)
            AS monthly_charge_q3,

        PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY cltv)
            AS cltv_q1,

        PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY cltv)
            AS cltv_q2,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY cltv)
            AS cltv_q3

    FROM cleaned_source

),


/* =========================================================
   SECTION 4
   CREATE ANALYTICAL FEATURES
   ========================================================= */

featured_data AS (

    SELECT

        c.*,


        /* -------------------------------------------------
           AGE BAND
           ------------------------------------------------- */

        CASE
            WHEN c.age IS NULL THEN 'Unknown'
            WHEN c.age < 30 THEN 'Under 30'
            WHEN c.age BETWEEN 30 AND 44 THEN '30-44'
            WHEN c.age BETWEEN 45 AND 59 THEN '45-59'
            ELSE '60+'
        END AS age_band,


        /* Sort key for Power BI */
        CASE
            WHEN c.age IS NULL THEN 99
            WHEN c.age < 30 THEN 1
            WHEN c.age BETWEEN 30 AND 44 THEN 2
            WHEN c.age BETWEEN 45 AND 59 THEN 3
            ELSE 4
        END AS age_band_sort,


        /* -------------------------------------------------
           TENURE BAND
           ------------------------------------------------- */

        CASE
            WHEN c.tenure_in_months IS NULL
                THEN 'Unknown'

            WHEN c.tenure_in_months BETWEEN 0 AND 6
                THEN '0-6 Months'

            WHEN c.tenure_in_months BETWEEN 7 AND 12
                THEN '7-12 Months'

            WHEN c.tenure_in_months BETWEEN 13 AND 24
                THEN '13-24 Months'

            WHEN c.tenure_in_months BETWEEN 25 AND 48
                THEN '25-48 Months'

            ELSE '49+ Months'
        END AS tenure_band,


        /* Sort key for Power BI */
        CASE
            WHEN c.tenure_in_months IS NULL THEN 99
            WHEN c.tenure_in_months BETWEEN 0 AND 6 THEN 1
            WHEN c.tenure_in_months BETWEEN 7 AND 12 THEN 2
            WHEN c.tenure_in_months BETWEEN 13 AND 24 THEN 3
            WHEN c.tenure_in_months BETWEEN 25 AND 48 THEN 4
            ELSE 5
        END AS tenure_band_sort,


        /* -------------------------------------------------
           MONTHLY CHARGE SEGMENT
           ------------------------------------------------- */

        CASE
            WHEN c.monthly_charge IS NULL THEN 'Unknown'

            WHEN c.monthly_charge <= t.monthly_charge_q1
                THEN 'Low'

            WHEN c.monthly_charge <= t.monthly_charge_q2
                THEN 'Medium'

            WHEN c.monthly_charge <= t.monthly_charge_q3
                THEN 'High'

            ELSE 'Very High'
        END AS monthly_charge_band,


        CASE
            WHEN c.monthly_charge IS NULL THEN 99
            WHEN c.monthly_charge <= t.monthly_charge_q1 THEN 1
            WHEN c.monthly_charge <= t.monthly_charge_q2 THEN 2
            WHEN c.monthly_charge <= t.monthly_charge_q3 THEN 3
            ELSE 4
        END AS monthly_charge_band_sort,


        /* -------------------------------------------------
           CUSTOMER VALUE SEGMENT BASED ON CLTV
           ------------------------------------------------- */

        CASE
            WHEN c.cltv IS NULL THEN 'Unknown'

            WHEN c.cltv <= t.cltv_q1
                THEN 'Low Value'

            WHEN c.cltv <= t.cltv_q2
                THEN 'Medium Value'

            WHEN c.cltv <= t.cltv_q3
                THEN 'High Value'

            ELSE 'Very High Value'
        END AS customer_value_segment,


        CASE
            WHEN c.cltv IS NULL THEN 99
            WHEN c.cltv <= t.cltv_q1 THEN 1
            WHEN c.cltv <= t.cltv_q2 THEN 2
            WHEN c.cltv <= t.cltv_q3 THEN 3
            ELSE 4
        END AS customer_value_segment_sort,


        /* -------------------------------------------------
           CHURN BOOLEAN
           ------------------------------------------------- */

        CASE
            WHEN c.churn_value = 1 THEN TRUE
            WHEN c.churn_value = 0 THEN FALSE
            ELSE NULL
        END AS is_churned,


        /* -------------------------------------------------
           CHURN DISPLAY FIELDS
           Preserve NULL analytically but provide readable
           categories for Power BI.
           ------------------------------------------------- */

        CASE
            WHEN c.churn_value = 1
                THEN COALESCE(c.churn_category, 'Unknown')

            ELSE 'Not Churned'
        END AS churn_category_display,


        CASE
            WHEN c.churn_value = 1
                THEN COALESCE(c.churn_reason, 'Unknown')

            ELSE 'Not Churned'
        END AS churn_reason_display,


        /* -------------------------------------------------
           SERVICE COUNT

           Count active customer services/features.
           ------------------------------------------------- */

        (
            CASE
                WHEN c.phone_service IS TRUE THEN 1 ELSE 0
            END

            +

            CASE
                WHEN c.internet_service IS TRUE THEN 1 ELSE 0
            END

            +

            CASE
                WHEN LOWER(c.multiple_lines) = 'yes'
                    THEN 1 ELSE 0
            END

            +

            CASE
                WHEN LOWER(c.online_security) = 'yes'
                    THEN 1 ELSE 0
            END

            +

            CASE
                WHEN LOWER(c.online_backup) = 'yes'
                    THEN 1 ELSE 0
            END

            +

            CASE
                WHEN LOWER(c.device_protection_plan) = 'yes'
                    THEN 1 ELSE 0
            END

            +

            CASE
                WHEN LOWER(c.premium_tech_support) = 'yes'
                    THEN 1 ELSE 0
            END

            +

            CASE
                WHEN LOWER(c.streaming_tv) = 'yes'
                    THEN 1 ELSE 0
            END

            +

            CASE
                WHEN LOWER(c.streaming_movies) = 'yes'
                    THEN 1 ELSE 0
            END

            +

            CASE
                WHEN LOWER(c.streaming_music) = 'yes'
                    THEN 1 ELSE 0
            END

            +

            CASE
                WHEN LOWER(c.unlimited_data) = 'yes'
                    THEN 1 ELSE 0
            END

        ) AS service_count


    FROM cleaned_source c

    CROSS JOIN thresholds t
)


/* =========================================================
   SECTION 5
   CREATE FINAL TABLE
   ========================================================= */

SELECT *
FROM featured_data;


/* =========================================================
   SECTION 6
   ADD PRIMARY KEY

   Run only after the staging-key checks have confirmed
   one unique row per customer.
   ========================================================= */

ALTER TABLE analytics.customer_churn_clean
ADD CONSTRAINT pk_customer_churn_clean
PRIMARY KEY (customer_id);


/* =========================================================
   SECTION 7
   CREATE USEFUL INDEXES

   These are useful for analytical queries and reporting.
   ========================================================= */

CREATE INDEX idx_customer_churn_status
ON analytics.customer_churn_clean (customer_status);


CREATE INDEX idx_customer_churn_value
ON analytics.customer_churn_clean (churn_value);


CREATE INDEX idx_customer_churn_contract
ON analytics.customer_churn_clean (contract);


CREATE INDEX idx_customer_churn_tenure_band
ON analytics.customer_churn_clean (tenure_band);


CREATE INDEX idx_customer_churn_city
ON analytics.customer_churn_clean (city);


CREATE INDEX idx_customer_churn_value_segment
ON analytics.customer_churn_clean (customer_value_segment);


/* =========================================================
   SECTION 8
   VALIDATION: ROW COUNT AND UNIQUE CUSTOMER COUNT
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
   SECTION 9
   CHECK FOR DUPLICATE CUSTOMER IDS
   ========================================================= */

SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM analytics.customer_churn_clean
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


/* Expected:
   0 rows
*/


/* =========================================================
   SECTION 10
   CHECK NULL CUSTOMER IDS
   ========================================================= */

SELECT COUNT(*) AS missing_customer_ids
FROM analytics.customer_churn_clean
WHERE customer_id IS NULL
   OR TRIM(customer_id) = '';


/* Expected:
   0
*/


/* =========================================================
   SECTION 11
   VERIFY CHURN DISTRIBUTION
   ========================================================= */

SELECT
    churn_label,
    churn_value,
    is_churned,
    COUNT(*) AS customers
FROM analytics.customer_churn_clean
GROUP BY
    churn_label,
    churn_value,
    is_churned
ORDER BY churn_value;


/* =========================================================
   SECTION 12
   VERIFY CUSTOMER STATUS
   ========================================================= */

SELECT
    customer_status,
    COUNT(*) AS customers
FROM analytics.customer_churn_clean
GROUP BY customer_status
ORDER BY customers DESC;


/* =========================================================
   SECTION 13
   VERIFY AGE BANDS
   ========================================================= */

SELECT
    age_band,
    age_band_sort,
    COUNT(*) AS customers,
    MIN(age) AS minimum_age,
    MAX(age) AS maximum_age
FROM analytics.customer_churn_clean
GROUP BY
    age_band,
    age_band_sort
ORDER BY age_band_sort;


/* =========================================================
   SECTION 14
   VERIFY TENURE BANDS
   ========================================================= */

SELECT
    tenure_band,
    tenure_band_sort,
    COUNT(*) AS customers,
    MIN(tenure_in_months) AS minimum_tenure,
    MAX(tenure_in_months) AS maximum_tenure
FROM analytics.customer_churn_clean
GROUP BY
    tenure_band,
    tenure_band_sort
ORDER BY tenure_band_sort;


/* =========================================================
   SECTION 15
   VERIFY MONTHLY CHARGE BANDS
   ========================================================= */

SELECT
    monthly_charge_band,
    monthly_charge_band_sort,
    COUNT(*) AS customers,
    ROUND(MIN(monthly_charge), 2) AS minimum_charge,
    ROUND(MAX(monthly_charge), 2) AS maximum_charge,
    ROUND(AVG(monthly_charge), 2) AS average_charge
FROM analytics.customer_churn_clean
GROUP BY
    monthly_charge_band,
    monthly_charge_band_sort
ORDER BY monthly_charge_band_sort;


/* =========================================================
   SECTION 16
   VERIFY CUSTOMER VALUE SEGMENTS
   ========================================================= */

SELECT
    customer_value_segment,
    customer_value_segment_sort,
    COUNT(*) AS customers,
    ROUND(MIN(cltv), 2) AS minimum_cltv,
    ROUND(MAX(cltv), 2) AS maximum_cltv,
    ROUND(AVG(cltv), 2) AS average_cltv
FROM analytics.customer_churn_clean
GROUP BY
    customer_value_segment,
    customer_value_segment_sort
ORDER BY customer_value_segment_sort;


/* =========================================================
   SECTION 17
   VERIFY SERVICE COUNT
   ========================================================= */

SELECT
    service_count,
    COUNT(*) AS customers
FROM analytics.customer_churn_clean
GROUP BY service_count
ORDER BY service_count;


/* =========================================================
   SECTION 18
   CORE FIELD COMPLETENESS
   ========================================================= */

SELECT

    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE gender IS NULL
    ) AS missing_gender,

    COUNT(*) FILTER (
        WHERE age IS NULL
    ) AS missing_age,

    COUNT(*) FILTER (
        WHERE tenure_in_months IS NULL
    ) AS missing_tenure,

    COUNT(*) FILTER (
        WHERE contract IS NULL
    ) AS missing_contract,

    COUNT(*) FILTER (
        WHERE monthly_charge IS NULL
    ) AS missing_monthly_charge,

    COUNT(*) FILTER (
        WHERE total_revenue IS NULL
    ) AS missing_total_revenue,

    COUNT(*) FILTER (
        WHERE satisfaction_score IS NULL
    ) AS missing_satisfaction_score,

    COUNT(*) FILTER (
        WHERE churn_value IS NULL
    ) AS missing_churn_value,

    COUNT(*) FILTER (
        WHERE cltv IS NULL
    ) AS missing_cltv

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 19
   CHECK BOOLEAN / SOURCE CONSISTENCY
   ========================================================= */

SELECT
    churn_label,
    churn_value,
    COUNT(*) AS customers
FROM analytics.customer_churn_clean
GROUP BY
    churn_label,
    churn_value
ORDER BY
    churn_value,
    churn_label;


/* =========================================================
   SECTION 20
   FINANCIAL SUMMARY
   ========================================================= */

SELECT

    COUNT(*) AS customers,

    ROUND(AVG(monthly_charge), 2)
        AS avg_monthly_charge,

    ROUND(SUM(total_charges), 2)
        AS total_customer_charges,

    ROUND(SUM(total_refunds), 2)
        AS total_refunds,

    ROUND(SUM(total_extra_data_charges), 2)
        AS total_extra_data_charges,

    ROUND(SUM(total_long_distance_charges), 2)
        AS total_long_distance_charges,

    ROUND(SUM(total_revenue), 2)
        AS total_revenue,

    ROUND(AVG(cltv), 2)
        AS average_cltv

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 21
   CHURNED CUSTOMER REASON VALIDATION
   ========================================================= */

SELECT
    COUNT(*) AS churned_without_reason
FROM analytics.customer_churn_clean
WHERE churn_value = 1
AND churn_reason IS NULL;


/* Ideally:
   0
*/


SELECT
    COUNT(*) AS non_churners_with_reason
FROM analytics.customer_churn_clean
WHERE churn_value = 0
AND churn_reason IS NOT NULL;


/* Ideally:
   0
*/


/* =========================================================
   SECTION 22
   CHECK ANALYTICS TABLE COLUMN TYPES
   ========================================================= */

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name = 'customer_churn_clean'
ORDER BY ordinal_position;


/* =========================================================
   SECTION 23
   SAMPLE CLEAN RECORDS
   ========================================================= */

SELECT
    customer_id,
    gender,
    age,
    age_band,
    city,
    tenure_in_months,
    tenure_band,
    contract,
    internet_type,
    service_count,
    monthly_charge,
    monthly_charge_band,
    total_revenue,
    satisfaction_score,
    customer_status,
    churn_value,
    customer_value_segment,
    churn_category,
    churn_reason
FROM analytics.customer_churn_clean
ORDER BY customer_id
LIMIT 20;


/* =========================================================
   END OF SCRIPT
   ========================================================= */