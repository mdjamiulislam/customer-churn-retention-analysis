CREATE SCHEMA staging;
CREATE SCHEMA analytics;
CREATE SCHEMA reporting;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('staging','analytics','reporting')
ORDER BY schema_name;

CREATE TABLE staging.demographics_raw (
    customer_id TEXT,
    count TEXT,
    gender TEXT,
    age TEXT,
    under_30 TEXT,
    senior_citizen TEXT,
    married TEXT,
    dependents TEXT,
    number_of_dependents TEXT
);

CREATE TABLE staging.location_raw (
    customer_id TEXT,
    count TEXT,
    country TEXT,
    state TEXT,
    city TEXT,
    zip_code TEXT,
    lat_long TEXT,
    latitude TEXT,
    longitude TEXT
);

CREATE TABLE staging.population_raw (
    population_id TEXT,
    zip_code TEXT,
    population TEXT
);

CREATE TABLE staging.services_raw (
    customer_id TEXT,
    count TEXT,
    quarter TEXT,
    referred_a_friend TEXT,
    number_of_referrals TEXT,
    tenure_in_months TEXT,
    offer TEXT,
    phone_service TEXT,
    avg_monthly_long_distance_charges TEXT,
    multiple_lines TEXT,
    internet_service TEXT,
    internet_type TEXT,
    avg_monthly_gb_download TEXT,
    online_security TEXT,
    online_backup TEXT,
    device_protection_plan TEXT,
    premium_tech_support TEXT,
    streaming_tv TEXT,
    streaming_movies TEXT,
    streaming_music TEXT,
    unlimited_data TEXT,
    contract TEXT,
    paperless_billing TEXT,
    payment_method TEXT,
    monthly_charge TEXT,
    total_charges TEXT,
    total_refunds TEXT,
    total_extra_data_charges TEXT,
    total_long_distance_charges TEXT,
    total_revenue TEXT
);

CREATE TABLE staging.status_raw (
    customer_id TEXT,
    count TEXT,
    quarter TEXT,
    satisfaction_score TEXT,
    customer_status TEXT,
    churn_label TEXT,
    churn_value TEXT,
    churn_score TEXT,
    cltv TEXT,
    churn_category TEXT,
    churn_reason TEXT
);

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'staging'
ORDER BY table_name;

SELECT
    table_name,
    COUNT(*) AS number_of_columns
FROM information_schema.columns
WHERE table_schema = 'staging'
GROUP BY table_name
ORDER BY table_name;

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'services_raw'
ORDER BY ordinal_position;