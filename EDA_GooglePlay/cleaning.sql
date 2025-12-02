--------------------------------------------------------------------------
-- Final query to insert cleaned data into apps_clean table
--------------------------------------------------------------------------
SET search_path TO googleplay;

DROP TABLE IF EXISTS apps_clean;

CREATE TABLE apps_clean (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- GENERATED ALWAYS AS IDENTITY (Starts id at 1)
  app_name TEXT,
  category TEXT,
  rating NUMERIC(3,2),
  reviews BIGINT,
  size_mb NUMERIC(8,2), -- size in megabytes
  installs BIGINT,
  type TEXT,
  price NUMERIC(10,2),
  content_rating TEXT,
  genres TEXT,
  last_updated DATE,
  current_ver TEXT,
  android_ver TEXT
);

INSERT INTO googleplay.apps_clean (app_name, category, rating, reviews, size_mb, installs, type, price, content_rating, genres, last_updated, current_ver, android_ver)
SELECT
  NULLIF(TRIM(app), '') AS app_name,
  NULLIF(TRIM(category), '') AS category,
  CASE
    WHEN rating ~ '^[1-5](\.[0-9]+)?$' THEN rating::NUMERIC
    ELSE NULL
  END AS rating,
  CASE
    WHEN reviews ~ '^[0-9]+$' THEN reviews::BIGINT -- BIGINT to avoid overflow when aggregating
    ELSE NULL
  END AS reviews,
  CASE
      WHEN size ~ '^[0-9]+(\.[0-9]+)?M$' THEN (regexp_replace(size, 'M$', '')::NUMERIC)
      WHEN size ~ '^[0-9]+(\.[0-9]+)?k$' THEN (regexp_replace(size, 'k$', '')::NUMERIC / 1000.0)
      WHEN size ~ '^[0-9]+(\.[0-9]+)?$' THEN (size::NUMERIC)
      WHEn lower(size) ILIKE '%varies%' THEN NULL
      ELSE NULL
  END AS size_mb,
  CASE
      WHEN installs ~ '^(0|[0-9,]+(\+)?)$'THEN regexp_replace(installs, '\+|,', '', 'g')::BIGINT
      ELSE NULL
  END AS installs,
  CASE
      WHEN lower(type) = 'free' THEN 'Free'::TEXT
      WHEN lower(type) = 'paid' THEN 'Paid'::TEXT
      ELSE NULL
  END AS type,
  CASE
      WHEN price LIKE '%$%' THEN regexp_replace(price, '\$', '', 'g')::NUMERIC
      WHEN price ~ '^[0-9]+$' THEN price::NUMERIC
      WHEN price = '' THEN 0::NUMERIC
      ELSE NULL
  END AS price,
  NULLIF(trim(content_rating), '') AS content_rating,
  NULLIF(trim(genres), '') AS genres,
  CASE
      WHEN last_updated IS NULL OR trim(last_updated) = '' THEN NULL
      WHEN last_updated ~ '^[A-Za-z]+ [0-9]+\, [0-9]+$' THEN to_timestamp(last_updated, 'FMMonth DD, YYYY')::DATE
  END AS last_updated,
  NULLIF(trim(current_ver), '') AS current_ver,
  NULLIF(trim(android_ver), '') AS android_ver
FROM googleplay.apps_raw;


--------------------------------------------------------------------------
-- Thought process and helper queries used during data cleaning
--------------------------------------------------------------------------

-- Step 1: Understand raw data
-- Step 2: Create cleaned table with proper types
-- Step 3: Data cleaning and transformation
-- Step 4: Decide on handling of null values
-- Step 5: Additional helper queries

-- Step 1: Check raw data and identify issues
-- Preview raw data
SELECT *
FROM googleplay.apps_raw
LIMIT 20;

-- Extract non-numeric characters only from numeric columns
SELECT DISTINCT 
  regexp_replace(rating, '[0-9.]','','g') AS non_numeric_rating,
  regexp_replace(reviews, '[0-9.]','','g') AS non_numeric_reviews,
  regexp_replace(size, '[0-9.]','','g') AS non_numeric_size,    
  regexp_replace(installs, '[0-9.]','','g') AS non_numeric_installs,
  regexp_replace(price, '[0-9.]','','g') AS non_numeric_price
FROM googleplay.apps_raw;

-- Check rating column for 'NaN' values
-- Result: 1474 are 'NaN', missing values (13.60%)
SELECT 
CASE 
    WHEN rating = 'NaN' THEN 'Missing'
    ELSE 'Present'
  END AS rating_status,
COUNT(*) AS n_ratings,
ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_ratings
FROM googleplay.apps_raw
GROUP BY rating_status
ORDER BY rating_status DESC;

-- Identify min/max values for rating
SELECT MAX(rating), MIN(rating)
FROM googleplay.apps_raw
WHERE rating <> 'NaN';

-- Check for NULL values
-- Count nulls per column using jsonb
SELECT 
  key as column_name,
  SUM(CASE WHEN value IS NULL THEN 1 ELSE 0 END) as null_count
FROM 
  googleplay.apps_raw t,
  LATERAL jsonb_each_text(to_jsonb(t)) 
GROUP BY key
ORDER BY null_count DESC;

-- Check rows with null values
-- Note: Don't delete rows using ctid. Search by the id (SERIAL, Primary Key) instead
SELECT ctid, * 
FROM googleplay.apps_raw ar
WHERE to_jsonb(ar)::text LIKE '%null%';

-- Step 2: New clean data, type table
-- Create cleaned, typed table
SET search_path TO googleplay;

DROP TABLE IF EXISTS apps_clean;

CREATE TABLE apps_clean (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- GENERATED ALWAYS AS IDENTITY (Starts at 1)
  app_name TEXT,
  category TEXT,
  rating NUMERIC(3,2),
  reviews BIGINT,
  size_mb NUMERIC(8,2), -- size in megabytes
  installs BIGINT,
  type TEXT,
  price NUMERIC(10,2),
  content_rating TEXT,
  genres TEXT,
  last_updated DATE,
  current_ver TEXT,
  android_ver TEXT
);

-- Step 3: Data Cleaning and transformation
-- rating: Set numeric or NULL
SELECT
  CASE 
    WHEN rating ~ '^[1-5](\.[0-9]+)?$' THEN rating::NUMERIC
    ELSE NULL
  END AS rating
FROM googleplay.apps_raw;

-- reviews: Check min/max reviews
SELECT MAX(reviews), MIN(reviews) 
FROM googleplay.apps_raw;

-- reviews: Set numeric or NULL
SELECT
  CASE 
    WHEN reviews ~ '^[0-9]+$' THEN reviews::BIGINT -- BIGINT to avoid overflow when aggregating
    ELSE NULL 
  END AS reviews
FROM googleplay.apps_raw;

-- size: Remove M and k (convert k to MB), else NULL
SELECT
  CASE
    WHEN size ~ '^[0-9]+(\.[0-9]+)?M$' THEN (regexp_replace(size, 'M$', '')::NUMERIC)
    WHEN size ~ '^[0-9]+(\.[0-9]+)?k$' THEN (regexp_replace(size, 'k$', '')::NUMERIC / 1000.0) -- convert k to MB
    WHEN size ~ '^[0-9]+(\.[0-9]+)?$' THEN (size::NUMERIC)
    WHEN lower(size) ILIKE '%varies%' THEN NULL
    ELSE NULL
  END AS size_mb
FROM googleplay.apps_raw;

-- installs: Check max length of installs
SELECT 
  MAX(LENGTH(installs)),
  installs
FROM googleplay.apps_raw
WHERE installs <> 'Free'
GROUP BY installs
ORDER BY MAX(LENGTH(installs)) DESC;

-- installs: Remove '+' and commas, else NULL
SELECT
  CASE
    WHEN installs ~ '^(0|[0-9,]+(\+)?)$'THEN regexp_replace(installs, '\+|,', '', 'g')::BIGINT
    ELSE NULL
  END AS installs_clean
FROM googleplay.apps_raw;

-- type normalization. Only Free and Paid, else NULL
SELECT
  CASE
    WHEN lower(type) = 'free' THEN 'Free'
    WHEN lower(type) = 'paid' THEN 'Paid'
    ELSE NULL
  END AS type
FROM googleplay.apps_raw;

-- price: remove '$', default is 0 if blank
SELECT
  CASE
    WHEN price ILIKE '%$%' THEN regexp_replace(price, '\$', '', 'g')::NUMERIC
    WHEN price ~ '^[0-9]+$' THEN price::NUMERIC
    WHEN price = '' THEN 0::NUMERIC
    ELSE NULL
  END AS price
FROM googleplay.apps_raw;

-- last_updated: parse date
SELECT to_timestamp(last_updated, 'FMMonth DD, YYYY')::DATE
FROM googleplay.apps_raw
WHERE last_updated IS NOT NULL;

-- Check problematic last_updated values
SELECT last_updated
FROM googleplay.apps_raw
WHERE last_updated LIKE '1.0.19';

-- CTE to check last_updated parsing
WITH cd AS (
SELECT
  CASE
    WHEN last_updated IS NULL OR trim(last_updated) = '' THEN NULL
    WHEN last_updated ~ '^[A-Za-z]+ [0-9]+\, [0-9]+$' THEN to_timestamp(last_updated, 'FMMonth DD, YYYY')::DATE
  END AS last_updated
FROM googleplay.apps_raw
)
SELECT last_updated
FROM cd
WHERE last_updated IS NOT NULL;

-- Current ver
-- Check non-numeric current_ver values
-- Result: Many versions have letters, not relevant info, keep as is
SELECT DISTINCT current_ver
FROM googleplay.apps_raw
WHERE current_ver ~* '[a-zA-Z]';

-- Step 4: Delete rows with nulls?
-- Check how many nulls per column in new cleaned table
-- Result: size_mb = 1696, rating = 1475
SELECT 
  key as column_name,
  SUM(CASE WHEN value IS NULL THEN 1 ELSE 0 END) as null_count
FROM 
  googleplay.apps_clean t,
  LATERAL jsonb_each_text(to_jsonb(t)) 
GROUP BY key
ORDER BY null_count DESC;

-- Check why size_mb and rating have many nulls. Compare raw vs clean using JOIN
SELECT 
  googleplay.apps_raw.size AS raw_size,
  googleplay.apps_clean.size_mb AS size_mb,
  googleplay.apps_raw.rating AS raw_rating, 
  googleplay.apps_clean.rating AS rating
FROM googleplay.apps_raw
JOIN googleplay.apps_clean
ON googleplay.apps_raw.app = googleplay.apps_clean.app_name
WHERE googleplay.apps_clean.size_mb IS NULL
   OR googleplay.apps_clean.rating IS NULL; 

-- Check how many "Varies with device" in size and "NaN" in rating
-- Result: All nulls are correctly set during cleaning. 
-- Result: 1695 nulls
SELECT COUNT(size) as size_count
FROM googleplay.apps_raw
WHERE size ILIKE '%varies%' OR rating IS NULL;

-- Result: 1474 nulls
SELECT COUNT(rating) as rating_count
FROM googleplay.apps_raw
WHERE rating ILIKE '%NaN%' OR rating IS NULL;

-- Get % of nulls in each column
-- Result: size_mb = 15.64% nulls, rating = 13.61% nulls
-- Action: Keep nulls as is, do not delete rows
SELECT 
  key as column_name,
  ROUND(100.0 * COUNT(*) FILTER (WHERE value IS NULL) / COUNT(*), 2) AS null_percentage
  FROM 
  googleplay.apps_clean t,
  LATERAL jsonb_each_text(to_jsonb(t)) 
GROUP BY key
ORDER BY null_percentage DESC;


-- Additional helper queries
-- Quick script to search for any value in all the dataset
SELECT ctid, * 
FROM googleplay.apps_raw ar
WHERE to_jsonb(ar)::text LIKE '%Surf%';

-- Check if there are any spaces before or after values in rating column
SELECT 
  DISTINCT rating, 
  LENGTH(rating), 
  LENGTH(TRIM(rating)) AS trimmed_length
FROM googleplay.apps_raw  
WHERE LENGTH(rating) <> LENGTH(TRIM(rating));   

/*
-- If necessary, how to delete rows with null values
-- Delete rows with null values using id
DELETE FROM your_table_name 
WHERE id = [the_actual_id_value];
*/

--------------------------------------------------------------------------
-- End of cleaning.sql
--------------------------------------------------------------------------