-- ============================================================
-- NYC Taxi Demand Analysis | 01_create_tables.sql
-- Creates the raw trips table and the zone lookup table.
-- Data: NYC TLC Yellow Taxi, January 2026 (3,724,889 rows)
-- Loading: Parquet converted to CSV with Python (pandas), then
--          imported with pgAdmin (Import/Export Data, Header on).
-- ============================================================

CREATE TABLE yellow_trips (
    vendor_id              INTEGER,
    pickup_datetime        TIMESTAMP,
    dropoff_datetime       TIMESTAMP,
    passenger_count        NUMERIC,
    trip_distance          NUMERIC,
    ratecode_id            NUMERIC,
    store_and_fwd_flag     VARCHAR(1),
    pu_location_id         INTEGER,
    do_location_id         INTEGER,
    payment_type           INTEGER,
    fare_amount            NUMERIC,
    extra                  NUMERIC,
    mta_tax                NUMERIC,
    tip_amount             NUMERIC,
    tolls_amount           NUMERIC,
    improvement_surcharge  NUMERIC,
    total_amount           NUMERIC,
    congestion_surcharge   NUMERIC,
    airport_fee            NUMERIC,
    cbd_congestion_fee     NUMERIC
);

CREATE TABLE taxi_zones (
    location_id   INTEGER,
    borough       VARCHAR(50),
    zone          VARCHAR(100),
    service_zone  VARCHAR(50)
);

-- Verify the tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

-- Reconciliation checks after loading
SELECT COUNT(*) FROM taxi_zones;     -- about 265
SELECT COUNT(*) FROM yellow_trips;   -- 3,724,889 (matches the source file)
