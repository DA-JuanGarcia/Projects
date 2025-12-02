-- Create a final deduplicated table
SET search_path TO googleplay;

DROP TABLE IF EXISTS apps_final;

CREATE TABLE apps_final AS
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY app_name
               ORDER BY reviews DESC, last_updated DESC
           ) AS rn
    FROM googleplay.apps_clean
)
SELECT
    id,
    app_name,
    category,
    rating,
    reviews,
    size_mb,
    installs,
    type,
    price,
    content_rating,
    genres,
    last_updated,
    current_ver,
    android_ver
FROM ranked
WHERE rn = 1;




