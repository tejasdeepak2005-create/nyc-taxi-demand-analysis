-- ============================================================
-- NYC Taxi Demand Analysis | 02_data_exploration.sql
-- First look at the raw data (yellow_trips, taxi_zones).
-- ============================================================

-- 1. Preview rows
SELECT * FROM yellow_trips LIMIT 10;

-- 2. Date range of pickups
-- Result: 2025-12-31 23:57:29 to 2026-02-01 00:45:01 (month-boundary trips)
SELECT MIN(pickup_datetime) AS earliest_pickup,
       MAX(pickup_datetime) AS latest_pickup
FROM yellow_trips;

-- 3. Trips outside January 2026
-- Result: 7 rows
SELECT COUNT(*)
FROM yellow_trips
WHERE pickup_datetime < '2026-01-01'
   OR pickup_datetime >= '2026-02-01';

-- 4. Trips per payment type
-- Insight: credit card (1) is about 60% of trips; cash (2) about 8%.
-- Codes: 0 Flex Fare, 1 Credit card, 2 Cash, 3 No charge, 4 Dispute
SELECT payment_type, COUNT(*) AS trips_count
FROM yellow_trips
GROUP BY payment_type
ORDER BY trips_count DESC;

-- 5. Top 5 pickup zones (raw IDs)
SELECT pu_location_id, COUNT(*) AS trip_count
FROM yellow_trips
GROUP BY pu_location_id
ORDER BY trip_count DESC
LIMIT 5;

-- 6. Top 5 pickup zones with names (first JOIN)
SELECT z.zone, z.borough, COUNT(*) AS trip_count
FROM yellow_trips AS t
JOIN taxi_zones AS z
  ON t.pu_location_id = z.location_id
GROUP BY z.zone, z.borough
ORDER BY trip_count DESC
LIMIT 5;

-- 7. Top 5 drop-off zones with names
SELECT z.zone, z.borough, COUNT(*) AS trip_count
FROM yellow_trips AS t
JOIN taxi_zones AS z
  ON t.do_location_id = z.location_id
GROUP BY z.zone, z.borough
ORDER BY trip_count DESC
LIMIT 5;

-- 8. Does the INNER JOIN lose any trips?
-- Result: 3,724,889 (no rows lost)
SELECT COUNT(*) AS joined_trips
FROM yellow_trips AS t
JOIN taxi_zones AS z
  ON t.pu_location_id = z.location_id;

-- LEFT JOIN proof: trips with no matching zone
-- Result: no rows
SELECT t.pu_location_id, COUNT(*) AS trip_count
FROM yellow_trips AS t
LEFT JOIN taxi_zones AS z
  ON t.pu_location_id = z.location_id
WHERE z.location_id IS NULL
GROUP BY t.pu_location_id;
