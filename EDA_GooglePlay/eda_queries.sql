--------------------------------------------------------------------------
-- Start of eda_queries.sql
--------------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Quick sanity checks (counts, null stats)
-- -------------------------------------------------------------------
-- Total rows
SELECT COUNT(*) AS total_rows 
FROM googleplay.apps_final;

-- Count of apps with non-null rating / installs
-- Result: pct_rating_null is 15.16%
-- Action: For analysis, filter out null ratings where needed
SELECT
  COUNT(*) FILTER (WHERE rating IS NOT NULL) AS rated_count,
  COUNT(*) FILTER (WHERE installs IS NOT NULL) AS installs_count,
  ROUND(100.0 * COUNT(*) FILTER (WHERE rating IS NULL) / COUNT(installs), 2) AS pct_rating_null
FROM googleplay.apps_final;

-- -------------------------------------------------------------------
-- Question 1: Which categories have the most apps?
-- -------------------------------------------------------------------
-- Result: FAMILY has the most apps (1876), followed by GAME (946) and TOOLS (829)
-- Result: Top 3 categories represent 40% of all apps
SELECT
  category,
  COUNT(*) AS apps_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_apps,
  ROUND(AVG(rating), 2) AS avg_rating,
  ROUND(AVG(size_mb), 2) AS avg_size_mb,
  SUM(installs) AS total_installs
FROM googleplay.apps_final
WHERE rating IS NOT NULL AND installs IS NOT NULL
GROUP BY category
ORDER BY apps_count DESC
LIMIT 20;

-- Ordered by total installs
-- Result: GAME has the highest total installs (13B), followed by COMMUNICATION (11B) and TOOLS (8B)
SELECT
  category,
  COUNT(*) AS apps_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_apps,
  ROUND(AVG(rating), 2) AS avg_rating,
  ROUND(AVG(size_mb), 2) AS avg_size_mb,
  SUM(installs) AS total_installs
FROM googleplay.apps_final
WHERE rating IS NOT NULL AND installs IS NOT NULL
GROUP BY category
ORDER BY total_installs DESC
LIMIT 20;

-- -------------------------------------------------------------------
-- Question 2: How are ratings distributed and which categories have higher average ratings?
-- -------------------------------------------------------------------
-- rating distribution buckets
-- Result: 45.6% of apps have ratings between 4.0 and 4.40, 31.11% between 4.5 and 5
SELECT
  width_bucket(rating, 0.99, 5.001, 8) AS bucket,
  MIN(rating)::NUMERIC(4,2) AS bucket_min,
  MAX(rating)::NUMERIC(4,2) AS bucket_max,
  COUNT(*) AS num_apps,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_apps
FROM googleplay.apps_final
WHERE rating IS NOT NULL
GROUP BY bucket
ORDER BY bucket;

-- Categories with highest avg rating (min 20 apps to avoid small-sample noise)
-- Result: Events 4.44, Art and Design 4.36, Education 4.35
SELECT
  category,
  ROUND(AVG(rating)::numeric,2) AS avg_rating,
  COUNT(*) AS n_apps
FROM googleplay.apps_final
WHERE rating IS NOT NULL
GROUP BY category
HAVING COUNT(*) >= 20
ORDER BY avg_rating DESC
LIMIT 20;

-- -------------------------------------------------------------------
-- Question 3: Do more-downloaded apps have better ratings?
-- -------------------------------------------------------------------
-- Correlation installs vs rating
-- Result: corr_installs_rating is around 0.04, indicating a very weak positive correlation
SELECT corr(installs::double precision, rating::double precision) AS corr_installs_rating
FROM googleplay.apps_final
WHERE installs IS NOT NULL AND rating IS NOT NULL;
-- Double precision: Is an inexact, variable-precision floating-point type that uses 8 bytes of storage and provides a precision of at least 15 decimal digits 
-- Double precision: Used for scientific calculations where high precision is needed but exactness is not critical, as floating-point arithmetic can introduce small rounding errors

-- Number of installs and average rating
-- Result: Apps with less than 1k installs have the highest avg rating with 4.35, followed by 10M+ installs with 4.31
-- Result: Higher number of installs don't translate to higher ratings
SELECT
CASE
  WHEN installs < 1000 THEN '<1k'
  WHEN installs < 10000 THEN '1k-10k'
  WHEN installs < 100000 THEN '10k-100k'
  WHEN installs < 1000000 THEN '100k-1M'
  WHEN installs < 10000000 THEN '1M-10M'
  ELSE '10M+'
  END AS num_installs,
  COUNT(installs) as num_apps,
  MIN(installs) AS min_bucket,
  MAX(installs) AS max_bucket,
  ROUND(AVG(rating)::NUMERIC,2) as avg_rating,
  ROUND(100 * COUNT(installs) / SUM(COUNT(installs)) OVER(), 2) AS pct_of_installs
FROM googleplay.apps_final
WHERE rating IS NOT NULL AND size_mb IS NOT NULL
GROUP BY num_installs
ORDER BY min_bucket;

-- -------------------------------------------------------------------
-- Question 4: Do Paid apps have higher ratings than Free apps?
-- -------------------------------------------------------------------
-- Result: Paid apps have avg rating of 4.26, Free apps have avg rating of 4.17
-- Result: Avg price of Paid apps is $14.10 
SELECT
  type,
  COUNT(*) AS n_apps,
  ROUND(AVG(rating)::numeric,2) AS avg_rating,
  ROUND(AVG(price)::numeric,2) AS avg_price
FROM googleplay.apps_final
WHERE type IS NOT NULL 
  AND rating IS NOT NULL 
  AND price IS NOT NULL
GROUP BY type;

-- Breakdown Paid vs Free by installs average, count, and pct of total apps
-- Result: Free apps represent 92.19% of total apps, Paid apps 7.81%
-- Result: Free apps are 99.92% of total installs, Paid apps 0.08%
SELECT 
  type,
  ROUND(AVG(installs)::numeric, 0) AS avg_installs, 
  COUNT(*) AS n_apps,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_apps,
  SUM(installs) AS total_installs,
  ROUND(100.0 * SUM(installs) / SUM(SUM(installs)) OVER(), 2) AS pct_of_installs
FROM googleplay.apps_final
WHERE installs IS NOT NULL
  AND type IS NOT NULL
GROUP BY type;

-- -------------------------------------------------------------------
-- Question 5: Does app size influence rating or installs?
-- -------------------------------------------------------------------
-- Correlation size vs rating and installs
-- Result: Size-rating corr is 0.063 (very weak positive), size installs corr is 0.132 (weak positive)
-- Result: Bigger apps don't necessarily have higher ratings or installs
SELECT
  corr(size_mb::double precision, rating::double precision) AS corr_size_rating,
  corr(size_mb::double precision, installs::double precision) AS corr_size_installs
FROM googleplay.apps_final
WHERE size_mb IS NOT NULL AND rating IS NOT NULL AND installs IS NOT NULL;

-- Size buckets and average rating / installs
-- Result: <5MB average rating is 4.11, 5-20MB is 4.16, 20-50MB is 4.16, 50-200MB is 4.25
-- Result: Bigger apps have slightly higher average ratings, for reasons such as more features or better quality
SELECT
  CASE
    WHEN size_mb < 5 THEN '<5MB'
    WHEN size_mb < 20 THEN '5-20MB'
    WHEN size_mb < 50 THEN '20-50MB'
    WHEN size_mb < 200 THEN '50-200MB'
    WHEN size_mb IS NULL THEN 'unknown'
    ELSE '200+MB'
  END AS size_bucket,
  COUNT(*) AS n_apps,
  ROUND(AVG(rating)::numeric,2) AS avg_rating,
  ROUND(AVG(installs)::numeric,0) AS avg_installs,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_apps,
  MIN(size_mb) AS min_size  -- This creates a natural sort order
FROM googleplay.apps_final
WHERE size_mb IS NOT NULL 
  AND installs IS NOT NULL 
  AND rating IS NOT NULL
GROUP BY size_bucket
ORDER BY min_size;

-- Count how many nulls in size_mb column
-- Result: 1229 nulls in size_mb
SELECT COUNT(*) AS null_size_mb_count
FROM googleplay.apps_final
WHERE size_mb IS NULL;

--------------------------------------------------------------------------
-- End of eda_queries.sql
--------------------------------------------------------------------------