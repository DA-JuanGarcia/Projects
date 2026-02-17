-------------------------------------------------------------
-- Final Cleaning and Validation Script
-- Create table and Insert cleaned data from raw tables
-------------------------------------------------------------
SET search_path TO insurance;

DROP TABLE IF EXISTS cust_clean;
CREATE TABLE cust_clean (
    customer_id INT PRIMARY KEY,
    acquisition_campaign_id INT,
    acquisition_channel TEXT,
    acquisition_date DATE,
    first_product TEXT,
    second_product TEXT,
    initial_premium_euro NUMERIC(10,2),
    current_premium_euro NUMERIC(10,2),
    status TEXT,
    churn_date DATE,
    churn_reason TEXT,
    total_premium_paid_euro NUMERIC(10,2),
    claims_count INT,
    claims_total_euro NUMERIC(10,2),
    last_renewal_date DATE,
    next_renewal_date DATE,
    segment TEXT,
    lifetime_months INT,
    customer_value_score INT
);

DROP TABLE IF EXISTS camp_clean;
CREATE TABLE camp_clean (
    campaign_id INT PRIMARY KEY,
    campaign_name TEXT,
    channel TEXT,
    subchannel TEXT,
    start_date DATE,
    end_date DATE,
    budget_euro NUMERIC(10,2),
    impressions INT,
    clicks INT,
    leads_generated INT,
    cost_per_click NUMERIC(10,2),
    cost_per_lead NUMERIC(10,2) 
);


INSERT INTO insurance.cust_clean (customer_id, acquisition_campaign_id, acquisition_channel, acquisition_date, first_product, second_product, initial_premium_euro, current_premium_euro, status, churn_date, churn_reason, total_premium_paid_euro, claims_count, claims_total_euro, last_renewal_date, next_renewal_date, segment, lifetime_months, customer_value_score)
SELECT 
    NULLIF(trim(customer_id), '')::INT AS customer_id,
    NULLIF(trim(acquisition_campaign_id), '')::INT AS acquisition_campaign_id,
    CASE
        WHEN acquisition_channel ~ '(\,[A-Za-z]+)' THEN regexp_replace(acquisition_channel, ',','','g')::TEXT -- 'g' means global (replace all, not just first)
        WHEN acquisition_channel ~ '([A-Za-z]+)\.' THEN rtrim(acquisition_channel, '.')::TEXT -- rtrim removes chars ONLY at the end of string
        WHEN acquisition_channel ~ '[A-Za-z]+' THEN acquisition_channel::TEXT
        ELSE NULL
    END AS acquisition_channel,
    CASE
        WHEN acquisition_date ~ '^[0-9]+\/[0-9]+\/[0-9]+$' THEN acquisition_date::DATE
        ELSE NULL
    END AS acquisition_date,
    NULLIF(trim(first_product), '') AS first_product,
    NULLIF(trim(second_product), '') AS second_product,
    CASE
        WHEN initial_premium_euro ~ '^[0-9.]+(\ €)$' THEN regexp_replace(initial_premium_euro, '\ €', '')::NUMERIC(10,2)
        WHEN initial_premium_euro ~ '^[0-9.]+$' THEN (initial_premium_euro::NUMERIC (10,2))
        ELSE NULL
    END AS initial_premium_euro,
    NULLIF(trim(current_premium_euro), '')::NUMERIC(10,2) AS current_premium_euro,
    NULLIF(trim(status), '') AS status,
    CASE
        WHEN churn_date ~ '^[0-9]+\/[0-9]+\/[0-9]+$' THEN churn_date::DATE
        ELSE NULL
    END AS churn_date,
    NULLIF(trim(churn_reason), '') AS churn_reason,
    NULLIF(trim(total_premium_paid_euro), '')::NUMERIC(10,2) AS total_premium_paid_euro,
    NULLIF(trim(claims_count), '')::INT AS claims_count,
    NULLIF(trim(claims_total_euro), '')::NUMERIC(10,2) AS claims_total_euro,
     CASE
        WHEN last_renewal_date ~ '^[0-9]+\/[0-9]+\/[0-9]+$' THEN last_renewal_date::DATE
        ELSE NULL
    END AS last_renewal_date,
    CASE
        WHEN next_renewal_date ~ '^[0-9]+\/[0-9]+\/[0-9]+$' THEN next_renewal_date::DATE
        ELSE NULL
    END AS next_renewal_date,
    NULLIF(trim(segment), '') AS segment,
    NULLIF(trim(lifetime_months), '')::INT AS lifetime_months,
    NULLIF(trim(customer_value_score), '')::INT AS customer_value_score
FROM insurance.cust_raw;


INSERT INTO insurance.camp_clean (campaign_id, campaign_name, channel, subchannel, start_date, end_date, budget_euro, impressions, clicks, leads_generated, cost_per_click, cost_per_lead)
SELECT 
    campaign_id::INT,
    campaign_name::TEXT,
    channel::TEXT,
    subchannel::TEXT,
    start_date::DATE,
    end_date::DATE,
    budget_euro::NUMERIC(10,2),
    impressions::INT,
    clicks::INT,
    leads_generated::INT,
    cost_per_click::NUMERIC(10,2),
    cost_per_lead::NUMERIC(10,2)
FROM insurance.camp_raw;



-----------------------------------------------
-- Validation Queries
-- insurance.cust_raw table
-----------------------------------------------

SELECT *
FROM insurance.cust_raw
LIMIT 10;

-- customer_id: Check Primary Key uniqueness
-- ERROR detected. Duplicates in customer_id
SELECT 
    customer_id,
    COUNT(*)
FROM insurance.cust_raw
GROUP by customer_id
HAVING COUNT(*) > 1;

SELECT *
FROM insurance.cust_raw
WHERE customer_id = '4057';

-- WINDOW function to show all duplicates
WITH id_dup AS (
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY customer_id) AS dup_count
    FROM insurance.cust_raw
)
SELECT *
FROM id_dup
WHERE dup_count > 1
AND acquisition_date ~ '^[0-9]+$'
ORDER BY customer_id;
-- FIX
-- I'm deleting those duplicated rows where acquisition_date are numbers, keeping the good ones where data is correct
-- ** NOT RECOMMENDED when dealing with real data **
-- ** Rows deleted **
SELECT * 
FROM insurance.cust_raw
WHERE acquisition_date ~ '^[0-9]+$';

DELETE FROM insurance.cust_raw
WHERE acquisition_date ~ '^[0-9]+$';

-- acquisition_campaign_id: Check campaign numbers 
-- There are 20 campaigns and 20 unique values. All good.
SELECT COUNT(DISTINCT acquisition_campaign_id)
FROM insurance.cust_raw;

-- acquisition_channel: Quality check
-- ERROR detected. Commas and periods before and after some values
SELECT DISTINCT acquisition_channel
FROM insurance.cust_raw;
-- FIX
-- Note: The dot (.) in regex means "any single character", reason why we use rtrim better
SELECT DISTINCT
CASE
    WHEN acquisition_channel ~ '(\,[A-Za-z]+)' THEN regexp_replace(acquisition_channel, ',','','g')::TEXT -- 'g' means global (replace all, not just first ocurrance)
    WHEN acquisition_channel ~ '([A-Za-z]+)\.' THEN rtrim(acquisition_channel, '.')::TEXT -- rtrim removes chars ONLY at the end of string
    WHEN acquisition_channel ~ '[A-Za-z]+' THEN acquisition_channel::TEXT
    ELSE NULL
END AS acquisition_channel
FROM insurance.cust_raw;

-- [:alpha:] Match any letter (including accented)
/*
SELECT DISTINCT acquisition_channel
FROM insurance.cust_raw
WHERE acquisition_channel ~ '^[[:alpha:]]+$';
*/

SELECT DISTINCT churn_reason
FROM insurance.cust_clean

-- acquisition_date: Quality check
-- ERROR detected. Some dates are numbers, NULL them.
SELECT DISTINCT acquisition_date
FROM insurance.cust_raw
ORDER BY acquisition_date DESC;
-- FIX
SELECT
    CASE
        WHEN acquisition_date ~ '^[0-9]+\/[0-9]+\/[0-9]+$' THEN acquisition_date::DATE
        ELSE NULL
    END AS acquisition_date
FROM insurance.cust_raw;

-- first_product: Quality check
SELECT DISTINCT first_product
FROM insurance.cust_raw;

-- second_product: Quality check
-- Some NULLs, empty values, no second product acquired.
SELECT DISTINCT second_product
FROM insurance.cust_raw;

-- initial_premium_euro: Quality check
-- ERROR detected. Some values have € char.
SELECT DISTINCT initial_premium_euro
FROM insurance.cust_raw
WHERE initial_premium_euro ~ '[^0-9.]'; -- returns values that are not just numbers

SELECT DISTINCT regexp_matches(initial_premium_euro, '[^0-9.]+','g') -- returns the char that is not just numbers
FROM insurance.cust_raw;

-- FIX
SELECT
    CASE
        WHEN initial_premium_euro ~ '^[0-9.]+(\ €)$' THEN regexp_replace(initial_premium_euro, '\ €', '')::NUMERIC(10,2)
        WHEN initial_premium_euro ~ '^[0-9.]+$' THEN (initial_premium_euro::NUMERIC (10,2))
        ELSE NULL
    END AS initial_premium_euro
FROM insurance.cust_raw;

-- current_premium_euro: Quality check
SELECT DISTINCT current_premium_euro
FROM insurance.cust_raw
WHERE current_premium_euro ~ '[^0-9.]'; -- returns values that are not just numbers

-- status: Quality check
SELECT DISTINCT status
FROM insurance.cust_raw;

-- churn_date: Quality check
-- ERROR detected. Some numbers instead of date
SELECT churn_date
FROM insurance.cust_raw
WHERE churn_date IS NOT NULL
ORDER BY churn_date DESC;
-- FIX
SELECT
    CASE
        WHEN churn_date ~ '^[0-9]+\/[0-9]+\/[0-9]+$' THEN churn_date::DATE
        ELSE NULL
    END AS churn_date
FROM insurance.cust_raw;

-- churn_reason: Quality check
SELECT DISTINCT churn_reason
FROM insurance.cust_raw;

-- total_premium_paid_euro: Quality check
SELECT total_premium_paid_euro
FROM insurance.cust_raw
WHERE total_premium_paid_euro ~'[^0-9.]+';

SELECT regexp_matches (total_premium_paid_euro,'[^0-9.]+','g')
FROM insurance.cust_raw;

-- claims_count
SELECT claims_count
FROM insurance.cust_raw
WHERE claims_count ~ '[^0-9]+';

-- claims_total_euro
SELECT claims_total_euro
FROM insurance.cust_raw
WHERE claims_total_euro ~ '[^0-9.]+';

-- last_renewal_date
-- ERROR detected. Some dates are numbers, NULL them.
SELECT last_renewal_date
FROM insurance.cust_raw
WHERE last_renewal_date IS NOT NULL
ORDER BY last_renewal_date DESC;
-- FIX
SELECT
    CASE
        WHEN last_renewal_date ~ '^[0-9]+\/[0-9]+\/[0-9]+$' THEN last_renewal_date::DATE
        ELSE NULL
    END AS last_renewal_date
FROM insurance.cust_raw;

-- next_renewal_date
-- ERROR detected. Some dates are numbers, NULL them.
SELECT next_renewal_date
FROM insurance.cust_raw
WHERE next_renewal_date IS NOT NULL
ORDER BY next_renewal_date DESC;
-- FIX
SELECT
    CASE
        WHEN next_renewal_date ~ '^[0-9]+\/[0-9]+\/[0-9]+$' THEN next_renewal_date::DATE
        ELSE NULL
    END AS next_renewal_date
FROM insurance.cust_raw;

-- segment: Quality check
SELECT DISTINCT segment
FROM insurance.cust_raw;

-- lifetime_months: Quality check
SELECT lifetime_months
FROM insurance.cust_raw
WHERE lifetime_months ~ '[^0-9]+';

-- customer_value_score: Quality check
-- ERROR detected. There are negative scores (-700) and scores over 100
SELECT customer_value_score
FROM insurance.cust_raw
-- WHERE customer_value_score ~ '[^0-9]+'
ORDER BY customer_value_score DESC;
-- FIX
-- As it is a synthetic dataset, I'll update the values, giving 0 to negative scores and 100 to those higher
-- ** Update applied ** --
UPDATE insurance.cust_raw
SET customer_value_score = 
    CASE 
        WHEN customer_value_score::INT < 0 THEN '0'
        WHEN customer_value_score::INT > 100 THEN '100'
        ELSE customer_value_score
    END::TEXT;


-----------------------------------------------
-- Validation Queries
-- insurance.camp_raw table
-----------------------------------------------

-- Quality check
-- Small table, no discrepancies found
SELECT *
FROM insurance.camp_raw;


--------------------------------------------------------------------------
-- End of cleaning.sql
--------------------------------------------------------------------------

