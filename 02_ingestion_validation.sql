/* ============================================================
   PROJECT 3: CUSTOMER CHURN, RETENTION & REVENUE RISK ANALYSIS
   ============================================================

   SCRIPT:
   01_database_setup.sql

   PURPOSE:
   Create the PostgreSQL schema structure and raw staging tables
   required for the IBM Telco Customer Churn project.

   DATABASE:
   customer_churn

   SOURCE TABLES:
   1. Demographics
   2. Location
   3. Population
   4. Services
   5. Status

   ARCHITECTURE:
   Raw Excel/CSV Files
          ↓
       staging
          ↓
       analytics
          ↓
       reporting
          ↓
       Power BI

   DESIGN PRINCIPLE:
   All source columns are initially stored as TEXT in the
   staging schema. Data types, cleaning rules and derived fields
   will be applied later in the analytics layer.

   ============================================================ */


/* ============================================================
   SECTION 1: CREATE PROJECT SCHEMAS
   ============================================================ */

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS reporting;


/* ============================================================
   SECTION 2: VERIFY SCHEMAS
   ============================================================ */

SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN (
    'staging',
    'analytics',
    'reporting'
)
ORDER BY schema_name;


/* ============================================================
   SECTION 3: REMOVE OLD STAGING TABLES
   ============================================================

   WARNING:
   Running these DROP statements will delete any data already
   imported into these staging tables.

   Use this section only when intentionally rebuilding the
   staging layer from scratch.
   ============================================================ */

DROP TABLE IF EXISTS staging.demographics_raw;
DROP TABLE IF EXISTS staging.location_raw;
DROP TABLE IF EXISTS staging.population_raw;
DROP TABLE IF EXISTS staging.services_raw;
DROP TABLE IF EXISTS staging.status_raw;


/* ============================================================
   SECTION 4: CREATE DEMOGRAPHICS STAGING TABLE
   ============================================================

   SOURCE FILE:
   Telco_customer_churn_demographics.xlsx

   EXPECTED COLUMNS: 9

   CUSTOMER-LEVEL JOIN KEY:
   customer_id
   ============================================================ */

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


/* ============================================================
   SECTION 5: CREATE LOCATION STAGING TABLE
   ============================================================

   SOURCE FILE:
   Telco_customer_churn_location.xlsx

   EXPECTED COLUMNS: 10

   SOURCE RECORD IDENTIFIER:
   location_id

   CUSTOMER-LEVEL JOIN KEY:
   customer_id

   POPULATION JOIN KEY:
   zip_code
   ============================================================ */

CREATE TABLE staging.location_raw (
    location_id TEXT,
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


/* ============================================================
   SECTION 6: CREATE POPULATION STAGING TABLE
   ============================================================

   SOURCE FILE:
   Telco_customer_churn_population.xlsx

   EXPECTED COLUMNS: 3

   SOURCE IDENTIFIER:
   population_id

   JOIN KEY:
   zip_code

   NOTE:
   Population is a ZIP-code-level table rather than a
   customer-level table.
   ============================================================ */

CREATE TABLE staging.population_raw (
    population_id TEXT,
    zip_code TEXT,
    population TEXT
);


/* ============================================================
   SECTION 7: CREATE SERVICES STAGING TABLE
   ============================================================

   SOURCE FILE:
   Telco_customer_churn_services.xlsx

   EXPECTED COLUMNS: 31

   SOURCE RECORD IDENTIFIER:
   service_id

   CUSTOMER-LEVEL JOIN KEY:
   customer_id

   This table contains the main service, contract, tenure,
   billing, charge and revenue variables.
   ============================================================ */

CREATE TABLE staging.services_raw (
    service_id TEXT,
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


/* ============================================================
   SECTION 8: CREATE STATUS STAGING TABLE
   ============================================================

   SOURCE FILE:
   Telco_customer_churn_status.xlsx

   EXPECTED COLUMNS: 12

   SOURCE RECORD IDENTIFIER:
   status_id

   CUSTOMER-LEVEL JOIN KEY:
   customer_id

   This table contains churn outcome, satisfaction, CLTV and
   churn-reason information.

   IMPORTANT:
   churn_score will be retained in staging, but it will NOT be
   treated as an independent churn driver because it is already
   a model-generated predictive score.
   ============================================================ */

CREATE TABLE staging.status_raw (
    status_id TEXT,
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


/* ============================================================
   SECTION 9: VERIFY THAT ALL FIVE STAGING TABLES EXIST
   ============================================================ */

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'staging'
ORDER BY table_name;


/* ============================================================
   SECTION 10: VERIFY COLUMN COUNTS
   ============================================================ */

SELECT
    table_name,
    COUNT(*) AS number_of_columns
FROM information_schema.columns
WHERE table_schema = 'staging'
GROUP BY table_name
ORDER BY table_name;


/* Expected results:

   demographics_raw    9
   location_raw       10
   population_raw      3
   services_raw       31
   status_raw         12

*/


/* ============================================================
   SECTION 11: VERIFY DEMOGRAPHICS TABLE STRUCTURE
   ============================================================ */

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'demographics_raw'
ORDER BY ordinal_position;


/* ============================================================
   SECTION 12: VERIFY LOCATION TABLE STRUCTURE
   ============================================================ */

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'location_raw'
ORDER BY ordinal_position;


/* ============================================================
   SECTION 13: VERIFY POPULATION TABLE STRUCTURE
   ============================================================ */

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'population_raw'
ORDER BY ordinal_position;


/* ============================================================
   SECTION 14: VERIFY SERVICES TABLE STRUCTURE
   ============================================================ */

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'services_raw'
ORDER BY ordinal_position;


/* ============================================================
   SECTION 15: VERIFY STATUS TABLE STRUCTURE
   ============================================================ */

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'status_raw'
ORDER BY ordinal_position;


/* ============================================================
   SECTION 16: FINAL DATABASE SETUP SUMMARY
   ============================================================

   STAGING TABLE STRUCTURE

   staging.demographics_raw
       9 columns
       customer-level key = customer_id

   staging.location_raw
       10 columns
       record ID = location_id
       customer-level key = customer_id
       geography key = zip_code

   staging.population_raw
       3 columns
       record ID = population_id
       geography key = zip_code

   staging.services_raw
       31 columns
       record ID = service_id
       customer-level key = customer_id

   staging.status_raw
       12 columns
       record ID = status_id
       customer-level key = customer_id

   ============================================================ */


/* ============================================================
   SECTION 17: PLANNED TABLE RELATIONSHIPS
   ============================================================

   These relationships will be validated AFTER data import.

   demographics.customer_id
            =
   services.customer_id

   demographics.customer_id
            =
   status.customer_id

   demographics.customer_id
            =
   location.customer_id

   location.zip_code
            =
   population.zip_code


   IMPORTANT:
   Primary-key and foreign-key constraints are deliberately NOT
   being created yet.

   We will first verify:
       - NULL keys
       - duplicate IDs
       - distinct customer counts
       - ZIP-code uniqueness
       - cross-table join coverage

   ============================================================ */


/* ============================================================
   END OF SCRIPT
   01_database_setup.sql
   ============================================================ */