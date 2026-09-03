/* =========================================================
   PROJECT 3: CUSTOMER CHURN, RETENTION & REVENUE RISK
   SCRIPT: 06_churn_driver_analysis.sql

   PURPOSE:
   1. Establish overall churn baseline.
   2. Analyse churn across major customer dimensions.
   3. Calculate churn rate, churn-rate gap and churn lift.
   4. Analyse churn reasons.
   5. Create reusable Power BI reporting views.
   6. Identify elevated-risk customer segments.

   SOURCE:
   analytics.customer_churn_clean

   OUTPUT VIEWS:
   reporting.vw_churn_driver_summary
   reporting.vw_churn_reason_summary
   reporting.vw_top_churn_risk_segments
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
   OVERALL CHURN BASELINE
   ========================================================= */

SELECT

    COUNT(*) AS total_customers,

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
    ) AS overall_churn_rate_pct

FROM analytics.customer_churn_clean;


/* =========================================================
   SECTION 3
   CHURN BY CONTRACT
   ========================================================= */

SELECT
    contract,

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
        AVG(tenure_in_months),
        2
    ) AS avg_tenure_months,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge

FROM analytics.customer_churn_clean

GROUP BY contract

ORDER BY churn_rate_pct DESC;


/* =========================================================
   SECTION 4
   CHURN BY TENURE BAND
   ========================================================= */

SELECT
    tenure_band,
    tenure_band_sort,

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
    ) AS avg_cltv

FROM analytics.customer_churn_clean

GROUP BY
    tenure_band,
    tenure_band_sort

ORDER BY tenure_band_sort;


/* =========================================================
   SECTION 5
   CHURN BY EXACT TENURE MONTH
   ========================================================= */

SELECT
    tenure_in_months,

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
    ) AS churn_rate_pct

FROM analytics.customer_churn_clean

GROUP BY tenure_in_months

ORDER BY tenure_in_months;


/* =========================================================
   SECTION 6
   CHURN BY MONTHLY CHARGE BAND
   ========================================================= */

SELECT
    monthly_charge_band,
    monthly_charge_band_sort,

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
    ) AS avg_monthly_charge

FROM analytics.customer_churn_clean

GROUP BY
    monthly_charge_band,
    monthly_charge_band_sort

ORDER BY monthly_charge_band_sort;


/* =========================================================
   SECTION 7
   AVERAGE MONTHLY CHARGE:
   CHURNED VS NOT CHURNED
   ========================================================= */

SELECT

    CASE
        WHEN churn_value = 1
            THEN 'Churned'
        WHEN churn_value = 0
            THEN 'Not Churned'
        ELSE 'Unknown'
    END AS churn_status,

    COUNT(*) AS customers,

    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge

FROM analytics.customer_churn_clean

GROUP BY churn_value

ORDER BY churn_value;


/* =========================================================
   SECTION 8
   CHURN BY PAYMENT METHOD
   ========================================================= */

SELECT
    payment_method,

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
    ) AS avg_monthly_charge

FROM analytics.customer_churn_clean

GROUP BY payment_method

ORDER BY churn_rate_pct DESC;


/* =========================================================
   SECTION 9
   CHURN BY INTERNET TYPE
   ========================================================= */

SELECT
    internet_type,

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
    ) AS avg_monthly_charge

FROM analytics.customer_churn_clean

GROUP BY internet_type

ORDER BY churn_rate_pct DESC;


/* =========================================================
   SECTION 10
   CHURN BY PREMIUM TECH SUPPORT
   ========================================================= */

SELECT
    premium_tech_support,

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
    ) AS churn_rate_pct

FROM analytics.customer_churn_clean

GROUP BY premium_tech_support

ORDER BY churn_rate_pct DESC;


/* =========================================================
   SECTION 11
   CHURN BY REFERRAL STATUS
   ========================================================= */

SELECT

    CASE
        WHEN referred_a_friend IS TRUE
            THEN 'Referred Friend'
        WHEN referred_a_friend IS FALSE
            THEN 'No Referral'
        ELSE 'Unknown'
    END AS referral_status,

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
    ) AS churn_rate_pct

FROM analytics.customer_churn_clean

GROUP BY referred_a_friend

ORDER BY churn_rate_pct DESC;


/* =========================================================
   SECTION 12
   CHURN BY REFERRAL BAND
   ========================================================= */

WITH referral_groups AS (

    SELECT

        CASE
            WHEN number_of_referrals = 0
                THEN '0 Referrals'

            WHEN number_of_referrals = 1
                THEN '1 Referral'

            WHEN number_of_referrals BETWEEN 2 AND 3
                THEN '2-3 Referrals'

            WHEN number_of_referrals >= 4
                THEN '4+ Referrals'

            ELSE 'Unknown'
        END AS referral_band,


        CASE
            WHEN number_of_referrals = 0 THEN 1
            WHEN number_of_referrals = 1 THEN 2
            WHEN number_of_referrals BETWEEN 2 AND 3 THEN 3
            WHEN number_of_referrals >= 4 THEN 4
            ELSE 99
        END AS referral_band_sort,


        churn_value

    FROM analytics.customer_churn_clean

)

SELECT
    referral_band,
    referral_band_sort,

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
    ) AS churn_rate_pct

FROM referral_groups

GROUP BY
    referral_band,
    referral_band_sort

ORDER BY referral_band_sort;


/* =========================================================
   SECTION 13
   CHURN BY SERVICE COUNT
   ========================================================= */

SELECT
    service_count,

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
    ) AS churn_rate_pct

FROM analytics.customer_churn_clean

GROUP BY service_count

ORDER BY service_count;


/* =========================================================
   SECTION 14
   CHURN BY SERVICE COUNT BAND
   ========================================================= */

WITH service_groups AS (

    SELECT

        CASE
            WHEN service_count BETWEEN 0 AND 2
                THEN '0-2 Services'

            WHEN service_count BETWEEN 3 AND 5
                THEN '3-5 Services'

            WHEN service_count BETWEEN 6 AND 8
                THEN '6-8 Services'

            WHEN service_count >= 9
                THEN '9+ Services'

            ELSE 'Unknown'
        END AS service_count_band,


        CASE
            WHEN service_count BETWEEN 0 AND 2 THEN 1
            WHEN service_count BETWEEN 3 AND 5 THEN 2
            WHEN service_count BETWEEN 6 AND 8 THEN 3
            WHEN service_count >= 9 THEN 4
            ELSE 99
        END AS service_count_band_sort,


        churn_value

    FROM analytics.customer_churn_clean

)

SELECT
    service_count_band,
    service_count_band_sort,

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
    ) AS churn_rate_pct

FROM service_groups

GROUP BY
    service_count_band,
    service_count_band_sort

ORDER BY service_count_band_sort;


/* =========================================================
   SECTION 15
   CHURN BY AGE BAND
   ========================================================= */

SELECT
    age_band,
    age_band_sort,

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
    ) AS churn_rate_pct

FROM analytics.customer_churn_clean

GROUP BY
    age_band,
    age_band_sort

ORDER BY age_band_sort;


/* =========================================================
   SECTION 16
   CHURN BY SENIOR CITIZEN STATUS
   ========================================================= */

SELECT

    CASE
        WHEN senior_citizen IS TRUE
            THEN 'Senior Citizen'

        WHEN senior_citizen IS FALSE
            THEN 'Not Senior Citizen'

        ELSE 'Unknown'
    END AS senior_status,

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
    ) AS churn_rate_pct

FROM analytics.customer_churn_clean

GROUP BY senior_citizen

ORDER BY churn_rate_pct DESC;


/* =========================================================
   SECTION 17
   CHURN BY GENDER
   ========================================================= */

SELECT
    gender,

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
    ) AS churn_rate_pct

FROM analytics.customer_churn_clean

GROUP BY gender

ORDER BY churn_rate_pct DESC;


/* =========================================================
   SECTION 18
   CHURN BY SATISFACTION SCORE
   ========================================================= */

SELECT
    satisfaction_score,

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
    ) AS churn_rate_pct

FROM analytics.customer_churn_clean

GROUP BY satisfaction_score

ORDER BY satisfaction_score;


/* =========================================================
   SECTION 19
   AVERAGE SATISFACTION:
   CHURNED VS NOT CHURNED
   ========================================================= */

SELECT

    CASE
        WHEN churn_value = 1
            THEN 'Churned'
        WHEN churn_value = 0
            THEN 'Not Churned'
        ELSE 'Unknown'
    END AS churn_status,

    COUNT(*) AS customers,

    ROUND(
        AVG(satisfaction_score),
        2
    ) AS avg_satisfaction_score

FROM analytics.customer_churn_clean

GROUP BY churn_value

ORDER BY churn_value;


/* =========================================================
   SECTION 20
   CHURN CATEGORY ANALYSIS
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
    ) AS share_of_churn_pct

FROM analytics.customer_churn_clean

WHERE churn_value = 1

GROUP BY churn_category

ORDER BY churned_customers DESC;


/* =========================================================
   SECTION 21
   DETAILED CHURN REASON ANALYSIS
   ========================================================= */

SELECT
    churn_reason,

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
        AVG(cltv),
        2
    ) AS avg_cltv

FROM analytics.customer_churn_clean

WHERE churn_value = 1

GROUP BY churn_reason

ORDER BY churned_customers DESC;


/* =========================================================
   SECTION 22
   CREATE UNIVERSAL CHURN DRIVER VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_churn_driver_summary AS

WITH baseline AS (

    SELECT

        100.0 *
        COUNT(*) FILTER (
            WHERE churn_value = 1
        )
        /
        NULLIF(COUNT(*), 0)
        AS overall_churn_rate

    FROM analytics.customer_churn_clean

),


driver_data AS (


/* ---------------------------------------------------------
   CONTRACT
   --------------------------------------------------------- */

SELECT

    'Contract'::TEXT AS driver_name,

    COALESCE(contract, 'Unknown')::TEXT AS driver_value,

    CASE
        WHEN contract = 'Month-to-Month' THEN 1
        WHEN contract = 'One Year' THEN 2
        WHEN contract = 'Two Year' THEN 3
        ELSE 99
    END AS driver_sort,

    COUNT(*) AS customers,

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ) AS churned_customers,

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ) AS active_customers,

    AVG(monthly_charge) AS avg_monthly_charge,

    AVG(tenure_in_months) AS avg_tenure_months,

    AVG(satisfaction_score) AS avg_satisfaction_score,

    AVG(cltv) AS avg_cltv

FROM analytics.customer_churn_clean

GROUP BY contract


UNION ALL


/* ---------------------------------------------------------
   TENURE BAND
   --------------------------------------------------------- */

SELECT

    'Tenure Band',

    COALESCE(tenure_band, 'Unknown'),

    tenure_band_sort,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY
    tenure_band,
    tenure_band_sort


UNION ALL


/* ---------------------------------------------------------
   MONTHLY CHARGE BAND
   --------------------------------------------------------- */

SELECT

    'Monthly Charge Band',

    COALESCE(monthly_charge_band, 'Unknown'),

    monthly_charge_band_sort,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY
    monthly_charge_band,
    monthly_charge_band_sort


UNION ALL


/* ---------------------------------------------------------
   PAYMENT METHOD
   --------------------------------------------------------- */

SELECT

    'Payment Method',

    COALESCE(payment_method, 'Unknown'),

    ROW_NUMBER() OVER (
        ORDER BY COALESCE(payment_method, 'Unknown')
    )::INTEGER,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY payment_method


UNION ALL


/* ---------------------------------------------------------
   INTERNET TYPE
   --------------------------------------------------------- */

SELECT

    'Internet Type',

    COALESCE(internet_type, 'Unknown'),

    ROW_NUMBER() OVER (
        ORDER BY COALESCE(internet_type, 'Unknown')
    )::INTEGER,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY internet_type


UNION ALL


/* ---------------------------------------------------------
   PREMIUM TECH SUPPORT
   --------------------------------------------------------- */

SELECT

    'Premium Tech Support',

    COALESCE(premium_tech_support, 'Unknown'),

    CASE
        WHEN LOWER(premium_tech_support) = 'yes' THEN 1
        WHEN LOWER(premium_tech_support) = 'no' THEN 2
        ELSE 3
    END,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY premium_tech_support


UNION ALL


/* ---------------------------------------------------------
   REFERRAL STATUS
   --------------------------------------------------------- */

SELECT

    'Referral Status',

    CASE
        WHEN referred_a_friend IS TRUE
            THEN 'Referred Friend'
        WHEN referred_a_friend IS FALSE
            THEN 'No Referral'
        ELSE 'Unknown'
    END,

    CASE
        WHEN referred_a_friend IS TRUE THEN 1
        WHEN referred_a_friend IS FALSE THEN 2
        ELSE 99
    END,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY referred_a_friend


UNION ALL


/* ---------------------------------------------------------
   REFERRAL BAND
   --------------------------------------------------------- */

SELECT

    'Referral Band',

    CASE
        WHEN number_of_referrals = 0
            THEN '0 Referrals'

        WHEN number_of_referrals = 1
            THEN '1 Referral'

        WHEN number_of_referrals BETWEEN 2 AND 3
            THEN '2-3 Referrals'

        WHEN number_of_referrals >= 4
            THEN '4+ Referrals'

        ELSE 'Unknown'
    END,

    CASE
        WHEN number_of_referrals = 0 THEN 1
        WHEN number_of_referrals = 1 THEN 2
        WHEN number_of_referrals BETWEEN 2 AND 3 THEN 3
        WHEN number_of_referrals >= 4 THEN 4
        ELSE 99
    END,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY
    CASE
        WHEN number_of_referrals = 0
            THEN '0 Referrals'
        WHEN number_of_referrals = 1
            THEN '1 Referral'
        WHEN number_of_referrals BETWEEN 2 AND 3
            THEN '2-3 Referrals'
        WHEN number_of_referrals >= 4
            THEN '4+ Referrals'
        ELSE 'Unknown'
    END,

    CASE
        WHEN number_of_referrals = 0 THEN 1
        WHEN number_of_referrals = 1 THEN 2
        WHEN number_of_referrals BETWEEN 2 AND 3 THEN 3
        WHEN number_of_referrals >= 4 THEN 4
        ELSE 99
    END


UNION ALL


/* ---------------------------------------------------------
   SERVICE COUNT BAND
   --------------------------------------------------------- */

SELECT

    'Service Count Band',

    CASE
        WHEN service_count BETWEEN 0 AND 2
            THEN '0-2 Services'

        WHEN service_count BETWEEN 3 AND 5
            THEN '3-5 Services'

        WHEN service_count BETWEEN 6 AND 8
            THEN '6-8 Services'

        WHEN service_count >= 9
            THEN '9+ Services'

        ELSE 'Unknown'
    END,

    CASE
        WHEN service_count BETWEEN 0 AND 2 THEN 1
        WHEN service_count BETWEEN 3 AND 5 THEN 2
        WHEN service_count BETWEEN 6 AND 8 THEN 3
        WHEN service_count >= 9 THEN 4
        ELSE 99
    END,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY
    CASE
        WHEN service_count BETWEEN 0 AND 2
            THEN '0-2 Services'
        WHEN service_count BETWEEN 3 AND 5
            THEN '3-5 Services'
        WHEN service_count BETWEEN 6 AND 8
            THEN '6-8 Services'
        WHEN service_count >= 9
            THEN '9+ Services'
        ELSE 'Unknown'
    END,

    CASE
        WHEN service_count BETWEEN 0 AND 2 THEN 1
        WHEN service_count BETWEEN 3 AND 5 THEN 2
        WHEN service_count BETWEEN 6 AND 8 THEN 3
        WHEN service_count >= 9 THEN 4
        ELSE 99
    END


UNION ALL


/* ---------------------------------------------------------
   AGE BAND
   --------------------------------------------------------- */

SELECT

    'Age Band',

    COALESCE(age_band, 'Unknown'),

    age_band_sort,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY
    age_band,
    age_band_sort


UNION ALL


/* ---------------------------------------------------------
   SENIOR CITIZEN
   --------------------------------------------------------- */

SELECT

    'Senior Citizen',

    CASE
        WHEN senior_citizen IS TRUE
            THEN 'Senior Citizen'
        WHEN senior_citizen IS FALSE
            THEN 'Not Senior Citizen'
        ELSE 'Unknown'
    END,

    CASE
        WHEN senior_citizen IS TRUE THEN 1
        WHEN senior_citizen IS FALSE THEN 2
        ELSE 99
    END,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY senior_citizen


UNION ALL


/* ---------------------------------------------------------
   GENDER
   --------------------------------------------------------- */

SELECT

    'Gender',

    COALESCE(gender, 'Unknown'),

    ROW_NUMBER() OVER (
        ORDER BY COALESCE(gender, 'Unknown')
    )::INTEGER,

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY gender


UNION ALL


/* ---------------------------------------------------------
   SATISFACTION SCORE
   --------------------------------------------------------- */

SELECT

    'Satisfaction Score',

    COALESCE(
        satisfaction_score::TEXT,
        'Unknown'
    ),

    COALESCE(
        satisfaction_score,
        99
    ),

    COUNT(*),

    COUNT(*) FILTER (
        WHERE churn_value = 1
    ),

    COUNT(*) FILTER (
        WHERE churn_value = 0
    ),

    AVG(monthly_charge),

    AVG(tenure_in_months),

    AVG(satisfaction_score),

    AVG(cltv)

FROM analytics.customer_churn_clean

GROUP BY satisfaction_score

),


calculated AS (

    SELECT

        d.driver_name,

        d.driver_value,

        d.driver_sort,

        d.customers,

        d.churned_customers,

        d.active_customers,


        100.0 *
        d.churned_customers
        /
        NULLIF(d.customers, 0)
        AS segment_churn_rate,


        b.overall_churn_rate,


        d.avg_monthly_charge,

        d.avg_tenure_months,

        d.avg_satisfaction_score,

        d.avg_cltv


    FROM driver_data d

    CROSS JOIN baseline b

)


SELECT

    driver_name,

    driver_value,

    driver_sort,

    customers,

    churned_customers,

    active_customers,


    ROUND(
        segment_churn_rate,
        2
    ) AS churn_rate_pct,


    ROUND(
        overall_churn_rate,
        2
    ) AS overall_churn_rate_pct,


    ROUND(
        segment_churn_rate
        -
        overall_churn_rate,
        2
    ) AS churn_rate_gap_pp,


    ROUND(
        segment_churn_rate
        /
        NULLIF(overall_churn_rate, 0),
        2
    ) AS churn_lift,


    ROUND(
        avg_monthly_charge,
        2
    ) AS avg_monthly_charge,


    ROUND(
        avg_tenure_months,
        2
    ) AS avg_tenure_months,


    ROUND(
        avg_satisfaction_score,
        2
    ) AS avg_satisfaction_score,


    ROUND(
        avg_cltv,
        2
    ) AS avg_cltv


FROM calculated;


/* =========================================================
   SECTION 23
   CREATE CHURN REASON SUMMARY VIEW
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_churn_reason_summary AS

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
    ) AS share_of_total_churn_pct,


    ROUND(
        AVG(monthly_charge),
        2
    ) AS avg_monthly_charge,


    ROUND(
        AVG(tenure_in_months),
        2
    ) AS avg_tenure_months,


    ROUND(
        AVG(cltv),
        2
    ) AS avg_cltv,


    ROUND(
        SUM(total_revenue),
        2
    ) AS historical_revenue


FROM analytics.customer_churn_clean

WHERE churn_value = 1

GROUP BY
    churn_category,
    churn_reason;


/* =========================================================
   SECTION 24
   CREATE TOP ELEVATED-RISK SEGMENT VIEW

   Minimum segment size = 100 customers.
   Only segments above the overall churn rate are retained.

   This is an exploratory prioritisation rule, not a
   predictive risk model.
   ========================================================= */

CREATE OR REPLACE VIEW reporting.vw_top_churn_risk_segments AS

SELECT

    driver_name,

    driver_value,

    driver_sort,

    customers,

    churned_customers,

    churn_rate_pct,

    overall_churn_rate_pct,

    churn_rate_gap_pp,

    churn_lift,

    avg_monthly_charge,

    avg_tenure_months,

    avg_satisfaction_score,

    avg_cltv,


    ROW_NUMBER() OVER (

        ORDER BY
            churn_lift DESC,
            customers DESC

    ) AS risk_rank


FROM reporting.vw_churn_driver_summary

WHERE customers >= 100
  AND churn_lift > 1;


/* =========================================================
   SECTION 25
   TEST DRIVER SUMMARY VIEW
   ========================================================= */

SELECT *
FROM reporting.vw_churn_driver_summary
ORDER BY
    driver_name,
    driver_sort;


/* =========================================================
   SECTION 26
   TOP 15 ELEVATED-RISK SEGMENTS
   ========================================================= */

SELECT
    risk_rank,
    driver_name,
    driver_value,
    customers,
    churned_customers,
    churn_rate_pct,
    overall_churn_rate_pct,
    churn_rate_gap_pp,
    churn_lift

FROM reporting.vw_top_churn_risk_segments

ORDER BY risk_rank

LIMIT 15;


/* =========================================================
   SECTION 27
   LOWEST-CHURN SEGMENTS

   Minimum size = 100 customers.
   ========================================================= */

SELECT
    driver_name,
    driver_value,
    customers,
    churned_customers,
    churn_rate_pct,
    overall_churn_rate_pct,
    churn_rate_gap_pp,
    churn_lift

FROM reporting.vw_churn_driver_summary

WHERE customers >= 100

ORDER BY
    churn_lift ASC,
    customers DESC

LIMIT 15;


/* =========================================================
   SECTION 28
   TOP CHURN CATEGORIES
   ========================================================= */

SELECT
    churn_category,

    SUM(churned_customers) AS churned_customers,

    ROUND(
        SUM(share_of_total_churn_pct),
        2
    ) AS share_of_total_churn_pct

FROM reporting.vw_churn_reason_summary

GROUP BY churn_category

ORDER BY churned_customers DESC;


/* =========================================================
   SECTION 29
   TOP DETAILED CHURN REASONS
   ========================================================= */

SELECT
    churn_category,
    churn_reason,
    churned_customers,
    share_of_total_churn_pct,
    avg_monthly_charge,
    avg_cltv

FROM reporting.vw_churn_reason_summary

ORDER BY churned_customers DESC

LIMIT 15;


/* =========================================================
   SECTION 30
   RECONCILE CHURN REASON VIEW
   ========================================================= */

SELECT
    SUM(churned_customers)
        AS churned_customers_from_reason_view
FROM reporting.vw_churn_reason_summary;


/* Compare with: */

SELECT
    COUNT(*) AS churned_customers_from_source
FROM analytics.customer_churn_clean
WHERE churn_value = 1;


/* The two totals should match.
*/


/* =========================================================
   SECTION 31
   CHECK REPORTING VIEWS
   ========================================================= */

SELECT
    table_schema,
    table_name
FROM information_schema.views

WHERE table_schema = 'reporting'

ORDER BY table_name;


/* Step 7 should add:

   vw_churn_driver_summary
   vw_churn_reason_summary
   vw_top_churn_risk_segments
*/


/* =========================================================
   SECTION 32
   METHODOLOGY NOTES

   1. Results are descriptive associations, not proof of
      causality.

   2. Churn rate is calculated within each segment.

   3. Churn-rate gap is measured in percentage points
      relative to portfolio churn.

   4. Churn lift =
      segment churn rate / overall churn rate.

   5. Risk ranking uses segments with at least 100 customers
      to reduce the influence of very small groups.

   6. The 100-customer threshold is an exploratory business
      rule, not a formal statistical significance threshold.

   7. Satisfaction is treated as an association with churn,
      not necessarily an independent causal predictor.

   8. Churn Score is deliberately excluded from driver
      analysis because it is already a predictive score in
      the source dataset.

   9. Churn Category and Churn Reason are analysed only
      among customers with churn_value = 1.

   ========================================================= */


/* =========================================================
   END OF SCRIPT
   ========================================================= */