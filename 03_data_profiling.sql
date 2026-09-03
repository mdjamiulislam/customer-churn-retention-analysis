/* ============================================================
   PROJECT 3: CUSTOMER CHURN, RETENTION & REVENUE RISK ANALYSIS
   SCRIPT: 03_data_profiling.sql

   PURPOSE:
   Perform a complete data-quality and profiling audit of the
   five raw staging tables before creating the analytics layer.

   IMPORTANT:
   - DO NOT UPDATE staging data.
   - DO NOT DELETE staging data.
   - DO NOT change staging data types.
   - This script is for inspection and validation only.

   SOURCE TABLES:
   staging.demographics_raw
   staging.location_raw
   staging.population_raw
   staging.services_raw
   staging.status_raw
   ============================================================ */


/* ============================================================
   SECTION 1
   BASELINE ROW COUNT CHECK
   ============================================================ */

SELECT
    'demographics_raw' AS table_name,
    COUNT(*) AS row_count
FROM staging.demographics_raw

UNION ALL

SELECT
    'location_raw',
    COUNT(*)
FROM staging.location_raw

UNION ALL

SELECT
    'population_raw',
    COUNT(*)
FROM staging.population_raw

UNION ALL

SELECT
    'services_raw',
    COUNT(*)
FROM staging.services_raw

UNION ALL

SELECT
    'status_raw',
    COUNT(*)
FROM staging.status_raw;


/* Expected customer-level tables:

   demographics_raw = 7043
   location_raw     = 7043
   services_raw     = 7043
   status_raw       = 7043

   population_raw will have a different row count.
*/


/* ============================================================
   SECTION 2
   CUSTOMER ID QUALITY CHECK
   ============================================================ */


/* 2.1 Total rows versus unique customers */

SELECT
    'demographics' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT TRIM(customer_id)) AS distinct_customer_ids
FROM staging.demographics_raw

UNION ALL

SELECT
    'location',
    COUNT(*),
    COUNT(DISTINCT TRIM(customer_id))
FROM staging.location_raw

UNION ALL

SELECT
    'services',
    COUNT(*),
    COUNT(DISTINCT TRIM(customer_id))
FROM staging.services_raw

UNION ALL

SELECT
    'status',
    COUNT(*),
    COUNT(DISTINCT TRIM(customer_id))
FROM staging.status_raw;


/* 2.2 Missing customer IDs */

SELECT
    'demographics' AS table_name,
    COUNT(*) AS missing_customer_ids
FROM staging.demographics_raw
WHERE customer_id IS NULL
   OR TRIM(customer_id) = ''

UNION ALL

SELECT
    'location',
    COUNT(*)
FROM staging.location_raw
WHERE customer_id IS NULL
   OR TRIM(customer_id) = ''

UNION ALL

SELECT
    'services',
    COUNT(*)
FROM staging.services_raw
WHERE customer_id IS NULL
   OR TRIM(customer_id) = ''

UNION ALL

SELECT
    'status',
    COUNT(*)
FROM staging.status_raw
WHERE customer_id IS NULL
   OR TRIM(customer_id) = '';


/* 2.3 Duplicate customer IDs */

SELECT
    'demographics' AS table_name,
    COUNT(*) AS duplicate_customer_ids
FROM (
    SELECT TRIM(customer_id)
    FROM staging.demographics_raw
    WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL
    GROUP BY TRIM(customer_id)
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT
    'location',
    COUNT(*)
FROM (
    SELECT TRIM(customer_id)
    FROM staging.location_raw
    WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL
    GROUP BY TRIM(customer_id)
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT
    'services',
    COUNT(*)
FROM (
    SELECT TRIM(customer_id)
    FROM staging.services_raw
    WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL
    GROUP BY TRIM(customer_id)
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT
    'status',
    COUNT(*)
FROM (
    SELECT TRIM(customer_id)
    FROM staging.status_raw
    WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL
    GROUP BY TRIM(customer_id)
    HAVING COUNT(*) > 1
) x;


/* ============================================================
   SECTION 3
   DEMOGRAPHICS PROFILING
   ============================================================ */


/* 3.1 Missing demographic values */

SELECT
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
           OR TRIM(customer_id) = ''
    ) AS missing_customer_id,

    COUNT(*) FILTER (
        WHERE gender IS NULL
           OR TRIM(gender) = ''
    ) AS missing_gender,

    COUNT(*) FILTER (
        WHERE age IS NULL
           OR TRIM(age) = ''
    ) AS missing_age,

    COUNT(*) FILTER (
        WHERE under_30 IS NULL
           OR TRIM(under_30) = ''
    ) AS missing_under_30,

    COUNT(*) FILTER (
        WHERE senior_citizen IS NULL
           OR TRIM(senior_citizen) = ''
    ) AS missing_senior_citizen,

    COUNT(*) FILTER (
        WHERE married IS NULL
           OR TRIM(married) = ''
    ) AS missing_married,

    COUNT(*) FILTER (
        WHERE dependents IS NULL
           OR TRIM(dependents) = ''
    ) AS missing_dependents,

    COUNT(*) FILTER (
        WHERE number_of_dependents IS NULL
           OR TRIM(number_of_dependents) = ''
    ) AS missing_number_of_dependents

FROM staging.demographics_raw;


/* 3.2 Gender distribution */

SELECT
    gender,
    COUNT(*) AS customers
FROM staging.demographics_raw
GROUP BY gender
ORDER BY customers DESC;


/* 3.3 Under 30 distribution */

SELECT
    under_30,
    COUNT(*) AS customers
FROM staging.demographics_raw
GROUP BY under_30
ORDER BY customers DESC;


/* 3.4 Senior citizen distribution */

SELECT
    senior_citizen,
    COUNT(*) AS customers
FROM staging.demographics_raw
GROUP BY senior_citizen
ORDER BY customers DESC;


/* 3.5 Married distribution */

SELECT
    married,
    COUNT(*) AS customers
FROM staging.demographics_raw
GROUP BY married
ORDER BY customers DESC;


/* 3.6 Dependents distribution */

SELECT
    dependents,
    COUNT(*) AS customers
FROM staging.demographics_raw
GROUP BY dependents
ORDER BY customers DESC;


/* ============================================================
   SECTION 4
   DEMOGRAPHIC NUMERIC VALIDATION
   ============================================================ */


/* 4.1 Invalid age values */

SELECT
    customer_id,
    age
FROM staging.demographics_raw
WHERE NULLIF(TRIM(age), '') IS NOT NULL
  AND TRIM(age) !~ '^[0-9]+$';


/* 4.2 Invalid Number of Dependents */

SELECT
    customer_id,
    number_of_dependents
FROM staging.demographics_raw
WHERE NULLIF(TRIM(number_of_dependents), '') IS NOT NULL
  AND TRIM(number_of_dependents) !~ '^[0-9]+$';


/* 4.3 Safe Age profile */

SELECT
    MIN(
        CASE
            WHEN TRIM(age) ~ '^[0-9]+$'
            THEN TRIM(age)::INTEGER
        END
    ) AS minimum_age,

    MAX(
        CASE
            WHEN TRIM(age) ~ '^[0-9]+$'
            THEN TRIM(age)::INTEGER
        END
    ) AS maximum_age,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(age) ~ '^[0-9]+$'
                THEN TRIM(age)::INTEGER
            END
        ),
        2
    ) AS average_age

FROM staging.demographics_raw;


/* 4.4 Number of Dependents profile */

SELECT
    MIN(
        CASE
            WHEN TRIM(number_of_dependents) ~ '^[0-9]+$'
            THEN TRIM(number_of_dependents)::INTEGER
        END
    ) AS minimum_dependents,

    MAX(
        CASE
            WHEN TRIM(number_of_dependents) ~ '^[0-9]+$'
            THEN TRIM(number_of_dependents)::INTEGER
        END
    ) AS maximum_dependents,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(number_of_dependents) ~ '^[0-9]+$'
                THEN TRIM(number_of_dependents)::INTEGER
            END
        ),
        2
    ) AS average_dependents

FROM staging.demographics_raw;


/* ============================================================
   SECTION 5
   DEMOGRAPHIC CONSISTENCY CHECKS
   ============================================================ */


/* 5.1 Age versus Under 30 */

SELECT
    customer_id,
    age,
    under_30
FROM staging.demographics_raw
WHERE TRIM(age) ~ '^[0-9]+$'
AND (
       (
           TRIM(age)::INTEGER < 30
           AND TRIM(under_30) <> 'Yes'
       )

       OR

       (
           TRIM(age)::INTEGER >= 30
           AND TRIM(under_30) <> 'No'
       )
    );


/* 5.2 Age versus Senior Citizen */

SELECT
    customer_id,
    age,
    senior_citizen
FROM staging.demographics_raw
WHERE TRIM(age) ~ '^[0-9]+$'
AND (
       (
           TRIM(age)::INTEGER >= 65
           AND TRIM(senior_citizen) <> 'Yes'
       )

       OR

       (
           TRIM(age)::INTEGER < 65
           AND TRIM(senior_citizen) <> 'No'
       )
    );


/* 5.3 Dependents indicator versus Number of Dependents */

SELECT
    customer_id,
    dependents,
    number_of_dependents
FROM staging.demographics_raw
WHERE TRIM(number_of_dependents) ~ '^[0-9]+$'
AND (
       (
           TRIM(dependents) = 'No'
           AND TRIM(number_of_dependents)::INTEGER > 0
       )

       OR

       (
           TRIM(dependents) = 'Yes'
           AND TRIM(number_of_dependents)::INTEGER = 0
       )
    );


/* ============================================================
   SECTION 6
   LOCATION PROFILING
   ============================================================ */


/* 6.1 Missing location values */

SELECT
    COUNT(*) FILTER (
        WHERE country IS NULL OR TRIM(country) = ''
    ) AS missing_country,

    COUNT(*) FILTER (
        WHERE state IS NULL OR TRIM(state) = ''
    ) AS missing_state,

    COUNT(*) FILTER (
        WHERE city IS NULL OR TRIM(city) = ''
    ) AS missing_city,

    COUNT(*) FILTER (
        WHERE zip_code IS NULL OR TRIM(zip_code) = ''
    ) AS missing_zip_code,

    COUNT(*) FILTER (
        WHERE latitude IS NULL OR TRIM(latitude) = ''
    ) AS missing_latitude,

    COUNT(*) FILTER (
        WHERE longitude IS NULL OR TRIM(longitude) = ''
    ) AS missing_longitude

FROM staging.location_raw;


/* 6.2 Country distribution */

SELECT
    country,
    COUNT(*) AS customers
FROM staging.location_raw
GROUP BY country
ORDER BY customers DESC;


/* 6.3 State distribution */

SELECT
    state,
    COUNT(*) AS customers
FROM staging.location_raw
GROUP BY state
ORDER BY customers DESC;


/* 6.4 Number of cities */

SELECT
    COUNT(DISTINCT TRIM(city)) AS distinct_cities
FROM staging.location_raw;


/* 6.5 Top cities by customer count */

SELECT
    city,
    COUNT(*) AS customers
FROM staging.location_raw
GROUP BY city
ORDER BY customers DESC, city
LIMIT 20;


/* ============================================================
   SECTION 7
   ZIP CODE AND COORDINATE VALIDATION
   ============================================================ */


/* 7.1 Invalid ZIP-code format */

SELECT
    zip_code,
    COUNT(*) AS records
FROM staging.location_raw
WHERE NULLIF(TRIM(zip_code), '') IS NOT NULL
  AND TRIM(zip_code) !~ '^[0-9]{5}$'
GROUP BY zip_code
ORDER BY records DESC;


/* 7.2 Invalid latitude */

SELECT
    customer_id,
    latitude
FROM staging.location_raw
WHERE NULLIF(TRIM(latitude), '') IS NOT NULL
AND TRIM(latitude) !~ '^-?[0-9]+([.][0-9]+)?$';


/* 7.3 Invalid longitude */

SELECT
    customer_id,
    longitude
FROM staging.location_raw
WHERE NULLIF(TRIM(longitude), '') IS NOT NULL
AND TRIM(longitude) !~ '^-?[0-9]+([.][0-9]+)?$';


/* 7.4 Safe coordinate ranges */

SELECT
    MIN(
        CASE
            WHEN TRIM(latitude) ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(latitude)::NUMERIC
        END
    ) AS minimum_latitude,

    MAX(
        CASE
            WHEN TRIM(latitude) ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(latitude)::NUMERIC
        END
    ) AS maximum_latitude,

    MIN(
        CASE
            WHEN TRIM(longitude) ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(longitude)::NUMERIC
        END
    ) AS minimum_longitude,

    MAX(
        CASE
            WHEN TRIM(longitude) ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(longitude)::NUMERIC
        END
    ) AS maximum_longitude

FROM staging.location_raw;


/* ============================================================
   SECTION 8
   POPULATION TABLE PROFILING
   ============================================================ */


/* 8.1 Missing population fields */

SELECT
    COUNT(*) FILTER (
        WHERE population_id IS NULL
           OR TRIM(population_id) = ''
    ) AS missing_population_id,

    COUNT(*) FILTER (
        WHERE zip_code IS NULL
           OR TRIM(zip_code) = ''
    ) AS missing_zip_code,

    COUNT(*) FILTER (
        WHERE population IS NULL
           OR TRIM(population) = ''
    ) AS missing_population

FROM staging.population_raw;


/* 8.2 ZIP-code uniqueness */

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT TRIM(zip_code)) AS distinct_zip_codes
FROM staging.population_raw;


/* 8.3 Duplicate ZIP codes */

SELECT
    TRIM(zip_code) AS zip_code,
    COUNT(*) AS occurrences
FROM staging.population_raw
WHERE NULLIF(TRIM(zip_code), '') IS NOT NULL
GROUP BY TRIM(zip_code)
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


/* 8.4 Invalid Population values */

SELECT
    population_id,
    zip_code,
    population
FROM staging.population_raw
WHERE NULLIF(TRIM(population), '') IS NOT NULL
AND TRIM(population) !~ '^[0-9]+$';


/* 8.5 Population range */

SELECT
    MIN(
        CASE
            WHEN TRIM(population) ~ '^[0-9]+$'
            THEN TRIM(population)::INTEGER
        END
    ) AS minimum_population,

    MAX(
        CASE
            WHEN TRIM(population) ~ '^[0-9]+$'
            THEN TRIM(population)::INTEGER
        END
    ) AS maximum_population,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(population) ~ '^[0-9]+$'
                THEN TRIM(population)::INTEGER
            END
        ),
        0
    ) AS average_population

FROM staging.population_raw;


/* ============================================================
   SECTION 9
   SERVICES CATEGORICAL PROFILING
   ============================================================ */


/* 9.1 Contract */

SELECT
    contract,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY contract
ORDER BY customers DESC;


/* 9.2 Payment Method */

SELECT
    payment_method,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY payment_method
ORDER BY customers DESC;


/* 9.3 Offer */

SELECT
    offer,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY offer
ORDER BY customers DESC;


/* 9.4 Internet Service */

SELECT
    internet_service,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY internet_service
ORDER BY customers DESC;


/* 9.5 Internet Type */

SELECT
    internet_type,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY internet_type
ORDER BY customers DESC;


/* 9.6 Phone Service */

SELECT
    phone_service,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY phone_service
ORDER BY customers DESC;


/* 9.7 Referred a Friend */

SELECT
    referred_a_friend,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY referred_a_friend
ORDER BY customers DESC;


/* 9.8 Multiple Lines */

SELECT
    multiple_lines,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY multiple_lines
ORDER BY customers DESC;


/* 9.9 Online Security */

SELECT
    online_security,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY online_security
ORDER BY customers DESC;


/* 9.10 Online Backup */

SELECT
    online_backup,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY online_backup
ORDER BY customers DESC;


/* 9.11 Device Protection */

SELECT
    device_protection_plan,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY device_protection_plan
ORDER BY customers DESC;


/* 9.12 Premium Tech Support */

SELECT
    premium_tech_support,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY premium_tech_support
ORDER BY customers DESC;


/* 9.13 Streaming TV */

SELECT
    streaming_tv,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY streaming_tv
ORDER BY customers DESC;


/* 9.14 Streaming Movies */

SELECT
    streaming_movies,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY streaming_movies
ORDER BY customers DESC;


/* 9.15 Streaming Music */

SELECT
    streaming_music,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY streaming_music
ORDER BY customers DESC;


/* 9.16 Unlimited Data */

SELECT
    unlimited_data,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY unlimited_data
ORDER BY customers DESC;


/* 9.17 Paperless Billing */

SELECT
    paperless_billing,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY paperless_billing
ORDER BY customers DESC;


/* ============================================================
   SECTION 10
   SERVICES MISSING-VALUE AUDIT
   ============================================================ */

SELECT

    COUNT(*) FILTER (
        WHERE tenure_in_months IS NULL
           OR TRIM(tenure_in_months) = ''
    ) AS missing_tenure,

    COUNT(*) FILTER (
        WHERE contract IS NULL
           OR TRIM(contract) = ''
    ) AS missing_contract,

    COUNT(*) FILTER (
        WHERE monthly_charge IS NULL
           OR TRIM(monthly_charge) = ''
    ) AS missing_monthly_charge,

    COUNT(*) FILTER (
        WHERE total_charges IS NULL
           OR TRIM(total_charges) = ''
    ) AS missing_total_charges,

    COUNT(*) FILTER (
        WHERE total_refunds IS NULL
           OR TRIM(total_refunds) = ''
    ) AS missing_total_refunds,

    COUNT(*) FILTER (
        WHERE total_extra_data_charges IS NULL
           OR TRIM(total_extra_data_charges) = ''
    ) AS missing_extra_data_charges,

    COUNT(*) FILTER (
        WHERE total_long_distance_charges IS NULL
           OR TRIM(total_long_distance_charges) = ''
    ) AS missing_long_distance_charges,

    COUNT(*) FILTER (
        WHERE total_revenue IS NULL
           OR TRIM(total_revenue) = ''
    ) AS missing_total_revenue

FROM staging.services_raw;


/* ============================================================
   SECTION 11
   SERVICES NUMERIC VALIDATION
   ============================================================ */

SELECT
    'number_of_referrals' AS field_name,
    COUNT(*) AS invalid_values
FROM staging.services_raw
WHERE NULLIF(TRIM(number_of_referrals), '') IS NOT NULL
AND TRIM(number_of_referrals) !~ '^[0-9]+$'

UNION ALL

SELECT
    'tenure_in_months',
    COUNT(*)
FROM staging.services_raw
WHERE NULLIF(TRIM(tenure_in_months), '') IS NOT NULL
AND TRIM(tenure_in_months) !~ '^[0-9]+$'

UNION ALL

SELECT
    'avg_monthly_long_distance_charges',
    COUNT(*)
FROM staging.services_raw
WHERE NULLIF(TRIM(avg_monthly_long_distance_charges), '') IS NOT NULL
AND TRIM(avg_monthly_long_distance_charges)
    !~ '^-?[0-9]+([.][0-9]+)?$'

UNION ALL

SELECT
    'avg_monthly_gb_download',
    COUNT(*)
FROM staging.services_raw
WHERE NULLIF(TRIM(avg_monthly_gb_download), '') IS NOT NULL
AND TRIM(avg_monthly_gb_download)
    !~ '^-?[0-9]+([.][0-9]+)?$'

UNION ALL

SELECT
    'monthly_charge',
    COUNT(*)
FROM staging.services_raw
WHERE NULLIF(TRIM(monthly_charge), '') IS NOT NULL
AND TRIM(monthly_charge)
    !~ '^-?[0-9]+([.][0-9]+)?$'

UNION ALL

SELECT
    'total_charges',
    COUNT(*)
FROM staging.services_raw
WHERE NULLIF(TRIM(total_charges), '') IS NOT NULL
AND TRIM(total_charges)
    !~ '^-?[0-9]+([.][0-9]+)?$'

UNION ALL

SELECT
    'total_refunds',
    COUNT(*)
FROM staging.services_raw
WHERE NULLIF(TRIM(total_refunds), '') IS NOT NULL
AND TRIM(total_refunds)
    !~ '^-?[0-9]+([.][0-9]+)?$'

UNION ALL

SELECT
    'total_extra_data_charges',
    COUNT(*)
FROM staging.services_raw
WHERE NULLIF(TRIM(total_extra_data_charges), '') IS NOT NULL
AND TRIM(total_extra_data_charges)
    !~ '^-?[0-9]+([.][0-9]+)?$'

UNION ALL

SELECT
    'total_long_distance_charges',
    COUNT(*)
FROM staging.services_raw
WHERE NULLIF(TRIM(total_long_distance_charges), '') IS NOT NULL
AND TRIM(total_long_distance_charges)
    !~ '^-?[0-9]+([.][0-9]+)?$'

UNION ALL

SELECT
    'total_revenue',
    COUNT(*)
FROM staging.services_raw
WHERE NULLIF(TRIM(total_revenue), '') IS NOT NULL
AND TRIM(total_revenue)
    !~ '^-?[0-9]+([.][0-9]+)?$';


/* ============================================================
   SECTION 12
   SERVICES NUMERIC RANGE PROFILING
   ============================================================ */

SELECT

    MIN(
        CASE
            WHEN TRIM(tenure_in_months) ~ '^[0-9]+$'
            THEN TRIM(tenure_in_months)::INTEGER
        END
    ) AS minimum_tenure,

    MAX(
        CASE
            WHEN TRIM(tenure_in_months) ~ '^[0-9]+$'
            THEN TRIM(tenure_in_months)::INTEGER
        END
    ) AS maximum_tenure,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(tenure_in_months) ~ '^[0-9]+$'
                THEN TRIM(tenure_in_months)::INTEGER
            END
        ),
        2
    ) AS average_tenure,

    MIN(
        CASE
            WHEN TRIM(monthly_charge)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(monthly_charge)::NUMERIC
        END
    ) AS minimum_monthly_charge,

    MAX(
        CASE
            WHEN TRIM(monthly_charge)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(monthly_charge)::NUMERIC
        END
    ) AS maximum_monthly_charge,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(monthly_charge)
                     ~ '^-?[0-9]+([.][0-9]+)?$'
                THEN TRIM(monthly_charge)::NUMERIC
            END
        ),
        2
    ) AS average_monthly_charge,

    MIN(
        CASE
            WHEN TRIM(total_revenue)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(total_revenue)::NUMERIC
        END
    ) AS minimum_total_revenue,

    MAX(
        CASE
            WHEN TRIM(total_revenue)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(total_revenue)::NUMERIC
        END
    ) AS maximum_total_revenue,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(total_revenue)
                     ~ '^-?[0-9]+([.][0-9]+)?$'
                THEN TRIM(total_revenue)::NUMERIC
            END
        ),
        2
    ) AS average_total_revenue

FROM staging.services_raw;


/* ============================================================
   SECTION 13
   SERVICE CONSISTENCY CHECKS
   ============================================================ */


/* 13.1 Referral flag versus number of referrals */

SELECT
    customer_id,
    referred_a_friend,
    number_of_referrals
FROM staging.services_raw
WHERE TRIM(number_of_referrals) ~ '^[0-9]+$'
AND (
       (
           TRIM(referred_a_friend) = 'No'
           AND TRIM(number_of_referrals)::INTEGER > 0
       )

       OR

       (
           TRIM(referred_a_friend) = 'Yes'
           AND TRIM(number_of_referrals)::INTEGER = 0
       )
    );


/* 13.2 Customers with Internet Service = No
   but Internet Type populated */

SELECT
    customer_id,
    internet_service,
    internet_type
FROM staging.services_raw
WHERE TRIM(internet_service) = 'No'
AND NULLIF(TRIM(internet_type), '') IS NOT NULL;


/* ============================================================
   SECTION 14
   STATUS / CHURN PROFILING
   ============================================================ */


/* 14.1 Customer Status */

SELECT
    customer_status,
    COUNT(*) AS customers
FROM staging.status_raw
GROUP BY customer_status
ORDER BY customers DESC;


/* 14.2 Churn Label */

SELECT
    churn_label,
    COUNT(*) AS customers
FROM staging.status_raw
GROUP BY churn_label
ORDER BY customers DESC;


/* 14.3 Churn Value */

SELECT
    churn_value,
    COUNT(*) AS customers
FROM staging.status_raw
GROUP BY churn_value
ORDER BY churn_value;


/* 14.4 Satisfaction Score */

SELECT
    satisfaction_score,
    COUNT(*) AS customers
FROM staging.status_raw
GROUP BY satisfaction_score
ORDER BY satisfaction_score;


/* 14.5 Churn Category */

SELECT
    churn_category,
    COUNT(*) AS customers
FROM staging.status_raw
GROUP BY churn_category
ORDER BY customers DESC;


/* 14.6 Churn Reason */

SELECT
    churn_reason,
    COUNT(*) AS customers
FROM staging.status_raw
GROUP BY churn_reason
ORDER BY customers DESC;


/* ============================================================
   SECTION 15
   STATUS NUMERIC VALIDATION
   ============================================================ */


/* 15.1 Invalid Satisfaction Score */

SELECT
    customer_id,
    satisfaction_score
FROM staging.status_raw
WHERE NULLIF(TRIM(satisfaction_score), '') IS NOT NULL
AND (
       TRIM(satisfaction_score) !~ '^[0-9]+$'

       OR

       CASE
           WHEN TRIM(satisfaction_score) ~ '^[0-9]+$'
           THEN TRIM(satisfaction_score)::INTEGER
       END NOT BETWEEN 1 AND 5
    );


/* 15.2 Invalid Churn Value */

SELECT
    customer_id,
    churn_value
FROM staging.status_raw
WHERE NULLIF(TRIM(churn_value), '') IS NOT NULL
AND TRIM(churn_value) NOT IN ('0', '1');


/* 15.3 Invalid Churn Score */

SELECT
    customer_id,
    churn_score
FROM staging.status_raw
WHERE NULLIF(TRIM(churn_score), '') IS NOT NULL
AND (
       TRIM(churn_score) !~ '^[0-9]+$'

       OR

       CASE
           WHEN TRIM(churn_score) ~ '^[0-9]+$'
           THEN TRIM(churn_score)::INTEGER
       END NOT BETWEEN 0 AND 100
    );


/* 15.4 Invalid CLTV */

SELECT
    customer_id,
    cltv
FROM staging.status_raw
WHERE NULLIF(TRIM(cltv), '') IS NOT NULL
AND TRIM(cltv) !~ '^-?[0-9]+([.][0-9]+)?$';


/* ============================================================
   SECTION 16
   STATUS RANGE PROFILING
   ============================================================ */

SELECT

    MIN(
        CASE
            WHEN TRIM(satisfaction_score) ~ '^[0-9]+$'
            THEN TRIM(satisfaction_score)::INTEGER
        END
    ) AS minimum_satisfaction,

    MAX(
        CASE
            WHEN TRIM(satisfaction_score) ~ '^[0-9]+$'
            THEN TRIM(satisfaction_score)::INTEGER
        END
    ) AS maximum_satisfaction,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(satisfaction_score) ~ '^[0-9]+$'
                THEN TRIM(satisfaction_score)::INTEGER
            END
        ),
        2
    ) AS average_satisfaction,

    MIN(
        CASE
            WHEN TRIM(churn_score) ~ '^[0-9]+$'
            THEN TRIM(churn_score)::INTEGER
        END
    ) AS minimum_churn_score,

    MAX(
        CASE
            WHEN TRIM(churn_score) ~ '^[0-9]+$'
            THEN TRIM(churn_score)::INTEGER
        END
    ) AS maximum_churn_score,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(churn_score) ~ '^[0-9]+$'
                THEN TRIM(churn_score)::INTEGER
            END
        ),
        2
    ) AS average_churn_score,

    MIN(
        CASE
            WHEN TRIM(cltv)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(cltv)::NUMERIC
        END
    ) AS minimum_cltv,

    MAX(
        CASE
            WHEN TRIM(cltv)
                 ~ '^-?[0-9]+([.][0-9]+)?$'
            THEN TRIM(cltv)::NUMERIC
        END
    ) AS maximum_cltv,

    ROUND(
        AVG(
            CASE
                WHEN TRIM(cltv)
                     ~ '^-?[0-9]+([.][0-9]+)?$'
                THEN TRIM(cltv)::NUMERIC
            END
        ),
        2
    ) AS average_cltv

FROM staging.status_raw;


/* ============================================================
   SECTION 17
   CHURN CONSISTENCY CHECKS
   ============================================================ */


/* 17.1 Churn Label versus Churn Value */

SELECT
    customer_id,
    churn_label,
    churn_value
FROM staging.status_raw
WHERE
      (
          TRIM(churn_label) = 'Yes'
          AND TRIM(churn_value) <> '1'
      )

   OR (
          TRIM(churn_label) = 'No'
          AND TRIM(churn_value) <> '0'
      );


/* 17.2 Customer Status versus Churn Value */

SELECT
    customer_id,
    customer_status,
    churn_label,
    churn_value
FROM staging.status_raw
WHERE
      (
          TRIM(customer_status) = 'Churned'
          AND TRIM(churn_value) <> '1'
      )

   OR (
          TRIM(customer_status) IN ('Stayed', 'Joined')
          AND TRIM(churn_value) <> '0'
      );


/* 17.3 Churned customers without Churn Category */

SELECT
    COUNT(*) AS churned_without_category
FROM staging.status_raw
WHERE TRIM(churn_value) = '1'
AND NULLIF(TRIM(churn_category), '') IS NULL;


/* 17.4 Churned customers without Churn Reason */

SELECT
    COUNT(*) AS churned_without_reason
FROM staging.status_raw
WHERE TRIM(churn_value) = '1'
AND NULLIF(TRIM(churn_reason), '') IS NULL;


/* 17.5 Non-churned customers with Churn Category or Reason */

SELECT
    customer_id,
    customer_status,
    churn_value,
    churn_category,
    churn_reason
FROM staging.status_raw
WHERE TRIM(churn_value) = '0'
AND (
       NULLIF(TRIM(churn_category), '') IS NOT NULL
       OR NULLIF(TRIM(churn_reason), '') IS NOT NULL
    );


/* ============================================================
   SECTION 18
   QUARTER CONSISTENCY
   ============================================================ */


/* 18.1 Services Quarter distribution */

SELECT
    quarter,
    COUNT(*) AS customers
FROM staging.services_raw
GROUP BY quarter
ORDER BY quarter;


/* 18.2 Status Quarter distribution */

SELECT
    quarter,
    COUNT(*) AS customers
FROM staging.status_raw
GROUP BY quarter
ORDER BY quarter;


/* 18.3 Quarter mismatches */

SELECT
    s.customer_id,
    s.quarter AS services_quarter,
    st.quarter AS status_quarter
FROM staging.services_raw s
JOIN staging.status_raw st
    ON TRIM(s.customer_id) = TRIM(st.customer_id)
WHERE COALESCE(TRIM(s.quarter), '')
   <> COALESCE(TRIM(st.quarter), '');


/* ============================================================
   SECTION 19
   CROSS-TABLE CUSTOMER COVERAGE
   ============================================================ */


/* 19.1 Demographics missing in Services */

SELECT
    COUNT(*) AS customers_missing_in_services
FROM staging.demographics_raw d
LEFT JOIN staging.services_raw s
    ON TRIM(d.customer_id) = TRIM(s.customer_id)
WHERE s.customer_id IS NULL;


/* 19.2 Demographics missing in Status */

SELECT
    COUNT(*) AS customers_missing_in_status
FROM staging.demographics_raw d
LEFT JOIN staging.status_raw st
    ON TRIM(d.customer_id) = TRIM(st.customer_id)
WHERE st.customer_id IS NULL;


/* 19.3 Demographics missing in Location */

SELECT
    COUNT(*) AS customers_missing_in_location
FROM staging.demographics_raw d
LEFT JOIN staging.location_raw l
    ON TRIM(d.customer_id) = TRIM(l.customer_id)
WHERE l.customer_id IS NULL;


/* 19.4 Services records missing from Demographics */

SELECT
    COUNT(*) AS services_missing_demographics
FROM staging.services_raw s
LEFT JOIN staging.demographics_raw d
    ON TRIM(s.customer_id) = TRIM(d.customer_id)
WHERE d.customer_id IS NULL;


/* 19.5 Status records missing from Demographics */

SELECT
    COUNT(*) AS status_missing_demographics
FROM staging.status_raw st
LEFT JOIN staging.demographics_raw d
    ON TRIM(st.customer_id) = TRIM(d.customer_id)
WHERE d.customer_id IS NULL;


/* 19.6 Location records missing from Demographics */

SELECT
    COUNT(*) AS location_missing_demographics
FROM staging.location_raw l
LEFT JOIN staging.demographics_raw d
    ON TRIM(l.customer_id) = TRIM(d.customer_id)
WHERE d.customer_id IS NULL;


/* ============================================================
   SECTION 20
   LOCATION TO POPULATION COVERAGE
   ============================================================ */


/* Customers with ZIP codes not found in Population table */

SELECT
    COUNT(*) AS location_rows_without_population_match
FROM staging.location_raw l
LEFT JOIN staging.population_raw p
    ON TRIM(l.zip_code) = TRIM(p.zip_code)
WHERE p.zip_code IS NULL;


/* Show unmatched ZIP codes */

SELECT DISTINCT
    l.zip_code
FROM staging.location_raw l
LEFT JOIN staging.population_raw p
    ON TRIM(l.zip_code) = TRIM(p.zip_code)
WHERE p.zip_code IS NULL
ORDER BY l.zip_code;


/* ============================================================
   SECTION 21
   FINAL JOIN RECONCILIATION
   ============================================================ */


/* 21.1 Customer tables only */

SELECT
    COUNT(*) AS joined_customer_rows
FROM staging.demographics_raw d

LEFT JOIN staging.services_raw s
    ON TRIM(d.customer_id) = TRIM(s.customer_id)

LEFT JOIN staging.status_raw st
    ON TRIM(d.customer_id) = TRIM(st.customer_id)

LEFT JOIN staging.location_raw l
    ON TRIM(d.customer_id) = TRIM(l.customer_id);


/* Expected:
   joined_customer_rows = 7043
*/


/* 21.2 Include Population */

SELECT
    COUNT(*) AS final_joined_rows
FROM staging.demographics_raw d

LEFT JOIN staging.services_raw s
    ON TRIM(d.customer_id) = TRIM(s.customer_id)

LEFT JOIN staging.status_raw st
    ON TRIM(d.customer_id) = TRIM(st.customer_id)

LEFT JOIN staging.location_raw l
    ON TRIM(d.customer_id) = TRIM(l.customer_id)

LEFT JOIN staging.population_raw p
    ON TRIM(l.zip_code) = TRIM(p.zip_code);


/* Expected:
   final_joined_rows = 7043
   if population ZIP codes are unique.
*/


/* ============================================================
   SECTION 22
   CORE ANALYTICAL FIELD COMPLETENESS
   ============================================================ */

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(d.gender), '') IS NULL
    ) AS missing_gender,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(d.age), '') IS NULL
    ) AS missing_age,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(s.tenure_in_months), '') IS NULL
    ) AS missing_tenure,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(s.contract), '') IS NULL
    ) AS missing_contract,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(s.monthly_charge), '') IS NULL
    ) AS missing_monthly_charge,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(s.total_revenue), '') IS NULL
    ) AS missing_total_revenue,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(st.satisfaction_score), '') IS NULL
    ) AS missing_satisfaction,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(st.churn_value), '') IS NULL
    ) AS missing_churn_value,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(st.cltv), '') IS NULL
    ) AS missing_cltv

FROM staging.demographics_raw d

LEFT JOIN staging.services_raw s
    ON TRIM(d.customer_id) = TRIM(s.customer_id)

LEFT JOIN staging.status_raw st
    ON TRIM(d.customer_id) = TRIM(st.customer_id);


/* ============================================================
   SECTION 23
   FINAL PROFILING SUMMARY
   ============================================================ */

SELECT

    (SELECT COUNT(*)
     FROM staging.demographics_raw)
        AS demographics_rows,

    (SELECT COUNT(DISTINCT TRIM(customer_id))
     FROM staging.demographics_raw)
        AS unique_demographic_customers,

    (SELECT COUNT(*)
     FROM staging.location_raw)
        AS location_rows,

    (SELECT COUNT(*)
     FROM staging.population_raw)
        AS population_rows,

    (SELECT COUNT(DISTINCT TRIM(zip_code))
     FROM staging.population_raw)
        AS unique_population_zip_codes,

    (SELECT COUNT(*)
     FROM staging.services_raw)
        AS services_rows,

    (SELECT COUNT(*)
     FROM staging.status_raw)
        AS status_rows,

    (SELECT COUNT(*)
     FROM staging.status_raw
     WHERE TRIM(churn_value) = '1')
        AS churned_customers,

    (SELECT COUNT(*)
     FROM staging.status_raw
     WHERE TRIM(churn_value) = '0')
        AS non_churned_customers;


/* ============================================================
   STEP 4 PROFILING DECISIONS
   ============================================================

   Based on the profiling results, the next analytics layer will:

   1. Preserve all staging tables unchanged.

   2. TRIM leading and trailing whitespace.

   3. Convert numeric TEXT fields into appropriate data types.

   4. Convert suitable Yes/No fields into clean categories or
      boolean-style analytical variables.

   5. Retain customer_id as the main customer-level key.

   6. Retain zip_code as TEXT, not INTEGER.

   7. Derive age bands from Age instead of relying only on
      Under 30.

   8. Derive tenure bands from Tenure in Months.

   9. Create customer service-count features.

   10. Retain Churn Score for reference only.

   11. EXCLUDE Churn Score from churn-driver analysis because
       it is already a predictive churn measure.

   12. Treat blank Churn Category / Churn Reason as expected
       for non-churned customers if confirmed by profiling.

   13. Join Demographics, Services, Status and Location using
       customer_id.

   14. Join Population using zip_code.

   15. Final analytics dataset must reconcile to exactly
       7,043 unique customers.

   ============================================================ */


/* ============================================================
   END OF 03_data_profiling.sql
   ============================================================ */