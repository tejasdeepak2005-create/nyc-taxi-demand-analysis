-- ============================================================
-- NYC Taxi Demand Analysis | 04_analysis_queries.sql
-- Business analysis on yellow_trips_clean (3,724,846 trips, January 2026).
-- ============================================================

-- Q1: Busiest pickup hours
-- Insight: demand peaks at 6 PM (265,573 trips) and is lowest at 4 AM (28,673).
SELECT EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour,
       COUNT(*) AS trip_count
FROM yellow_trips_clean
GROUP BY EXTRACT(HOUR FROM pickup_datetime)
ORDER BY pickup_hour;

-- Q2: Demand by day of week (average per day, so months with 5 of a
-- weekday do not distort the result)
-- Insight: Saturday averages about 134K trips/day, Sunday about 93K.
SELECT EXTRACT(DOW FROM pickup_datetime) AS day_num,
       TRIM(TO_CHAR(pickup_datetime, 'Day')) AS day_name,
       COUNT(*) AS trip_count,
       ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT pickup_datetime::date)) AS avg_trips_per_day
FROM yellow_trips_clean
GROUP BY day_num, day_name
ORDER BY day_num;

-- Q3: Weekday vs weekend
-- Totals: Weekday 2,679,061 (22 days = about 121.8K/day)
--         Weekend 1,045,785 (9 days = about 116.2K/day)
SELECT CASE WHEN EXTRACT(DOW FROM pickup_datetime) IN (0, 6)
            THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       COUNT(*) AS trip_count
FROM yellow_trips_clean
GROUP BY day_type;

-- Q4: Top 10 pickup zones (CTE + RANK window function)
-- Insight: 9 of the top 10 zones are in Manhattan; JFK Airport is #3.
WITH zone_trips AS (
    SELECT z.zone, z.borough, COUNT(*) AS trip_count
    FROM yellow_trips_clean AS t
    JOIN taxi_zones AS z ON t.pu_location_id = z.location_id
    GROUP BY z.zone, z.borough
)
SELECT RANK() OVER (ORDER BY trip_count DESC) AS zone_rank,
       zone, borough, trip_count
FROM zone_trips
ORDER BY zone_rank
LIMIT 10;

-- Q5: Top 5 drop-off zones
SELECT z.zone, z.borough, COUNT(*) AS trip_count
FROM yellow_trips_clean AS t
JOIN taxi_zones AS z ON t.do_location_id = z.location_id
GROUP BY z.zone, z.borough
ORDER BY trip_count DESC
LIMIT 5;

-- Q6 (optional, for the heatmap): demand by day of week and hour
SELECT EXTRACT(DOW FROM pickup_datetime) AS day_num,
       TRIM(TO_CHAR(pickup_datetime, 'Day')) AS day_name,
       EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour,
       COUNT(*) AS trip_count
FROM yellow_trips_clean
GROUP BY day_num, day_name, pickup_hour
ORDER BY day_num, pickup_hour;
