-- ============================================================
-- NYC Taxi Demand Analysis | 03_data_cleaning.sql
-- Investigates data quality, then builds yellow_trips_clean.
-- The raw table yellow_trips is never modified.
-- ============================================================

-- 1. Missing values
-- Result: 1,088,058 NULLs (29.2%) in passenger_count, ratecode_id
-- and store_and_fwd_flag.
SELECT COUNT(*) AS total_rows,
       COUNT(passenger_count) AS passenger_not_null
FROM yellow_trips;

SELECT COUNT(*) - COUNT(ratecode_id) AS ratecode_nulls
FROM yellow_trips;

SELECT COUNT(*) - COUNT(store_and_fwd_flag) AS store_nulls
FROM yellow_trips;

-- Test: which payment type do the NULL rows belong to?
-- Result: all 1,088,058 are payment_type = 0 (Flex Fare).
-- Decision #1: KEEP these rows (NULLs are by design; time and zone are complete).
SELECT payment_type, COUNT(*) AS trips
FROM yellow_trips
WHERE passenger_count IS NULL
GROUP BY payment_type;

-- 2. Invalid distances and fares
-- Result: 125,738 distance <= 0 | 41,545 fare <= 0 | 40,417 total <= 0
SELECT
  COUNT(*) FILTER (WHERE trip_distance <= 0) AS zero_or_negative_distance,
  COUNT(*) FILTER (WHERE fare_amount <= 0)   AS zero_or_negative_fare,
  COUNT(*) FILTER (WHERE total_amount <= 0)  AS zero_or_negative_total
FROM yellow_trips;

-- Bad fares by payment type
-- Result: Dispute 26,212 | Cash 9,840 | No charge 4,636 | Flex 567 | Card 290
-- Decision #2: keep for demand analysis; exclude for revenue analysis.
SELECT payment_type, COUNT(*) AS trips
FROM yellow_trips
WHERE fare_amount <= 0
GROUP BY payment_type
ORDER BY trips DESC;

-- Zero-distance trips: 97% were charged a fare (distance-recording issue)
-- Decision #4: keep for demand; exclude for distance/speed analysis.
SELECT
  COUNT(*) FILTER (WHERE fare_amount > 0)  AS zero_dist_with_fare,   -- 122,482
  COUNT(*) FILTER (WHERE fare_amount <= 0) AS zero_dist_no_fare      -- 3,256
FROM yellow_trips
WHERE trip_distance = 0;

-- 3. Timestamp problems
-- Result: 1 drop-off before pickup | 45,069 same time | 35 over 24 hours
-- Decision #3: exclude the 1 backwards trip and the 35 trips over 24 hours.
SELECT
  COUNT(*) FILTER (WHERE dropoff_datetime < pickup_datetime) AS dropoff_before_pickup,
  COUNT(*) FILTER (WHERE dropoff_datetime = pickup_datetime) AS same_time,
  COUNT(*) FILTER (WHERE dropoff_datetime - pickup_datetime > INTERVAL '24 hours') AS over_24_hours
FROM yellow_trips;

-- 4. Zero passengers (recorded as 0, not NULL)
-- Result: 14,787 rows. Decision #5: keep for demand analysis.
SELECT COUNT(*) AS zero_passenger_trips
FROM yellow_trips
WHERE passenger_count = 0;

-- 5. Duplicates
-- Result: 1 candidate pair
SELECT vendor_id, pickup_datetime, dropoff_datetime,
       pu_location_id, do_location_id, total_amount,
       COUNT(*) AS copies
FROM yellow_trips
GROUP BY vendor_id, pickup_datetime, dropoff_datetime,
         pu_location_id, do_location_id, total_amount
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 10;

-- Full-row check: the two rows differ in trip_distance (1.2 vs 1.09),
-- so they are NOT exact duplicates. Decision #6: keep both.
SELECT *
FROM yellow_trips
WHERE vendor_id = 2
  AND pickup_datetime = '2026-01-22 18:15:54'
  AND pu_location_id = 161
  AND do_location_id = 142;

-- 6. Build the clean table
-- Excludes: 7 trips outside January 2026, 1 backwards trip, 35 trips over 24 hours.
CREATE TABLE yellow_trips_clean AS
SELECT *
FROM yellow_trips
WHERE pickup_datetime >= '2026-01-01'
  AND pickup_datetime <  '2026-02-01'
  AND dropoff_datetime >= pickup_datetime
  AND dropoff_datetime - pickup_datetime <= INTERVAL '24 hours';

-- Verify: must return 3,724,846
SELECT COUNT(*) FROM yellow_trips_clean;
