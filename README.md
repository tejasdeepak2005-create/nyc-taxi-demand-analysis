# NYC Taxi Demand Analysis Using SQL

An end-to-end data analytics project that analyzes **3.72 million NYC yellow taxi trips (January 2026)** with **PostgreSQL** and visualizes the findings in a **Power BI** dashboard.

![Dashboard](dashboard/dashboard_screenshot.png)

---

## Problem Statement

A taxi operator wants to know *when* and *where* to put more drivers on the road. Guessing wastes fuel and misses passengers. This project uses trip records to answer:

- Which hours of the day are busiest?
- Which days of the week have the highest demand?
- Which pickup zones generate the most trips?
- Does demand differ between weekdays and weekends?

## Objectives

1. Load and understand the NYC TLC Yellow Taxi trip data.
2. Clean the data with documented, justified decisions.
3. Use SQL (aggregations, JOINs, CASE WHEN, CTEs, window functions) to answer demand questions.
4. Present the results in an interactive Power BI dashboard.

## Tools Used

| Tool | Purpose |
|---|---|
| PostgreSQL + pgAdmin | Storage, cleaning, analysis |
| Python (pandas, pyarrow) | Convert Parquet to CSV for loading |
| Power BI Desktop | Dashboard |

## Dataset

- **Source:** [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
- **File:** Yellow Taxi Trip Records, January 2026 (Parquet)
- **Size:** 3,724,889 rows, 20 columns
- **Zone lookup:** Taxi Zone Lookup Table (CSV, about 265 zones)

Key columns: `tpep_pickup_datetime`, `tpep_dropoff_datetime`, `PULocationID`, `DOLocationID`, `passenger_count`, `trip_distance`, `payment_type`, `fare_amount`, `total_amount`.

The raw data files are not included because of their size. Download them from the TLC link above.

---

## Project Workflow

1. **Setup:** Created two tables (`yellow_trips`, `taxi_zones`), converted Parquet to CSV with Python, imported into PostgreSQL, and reconciled the row count (3,724,889) against the source file.
2. **Exploration:** Checked the date range, payment types, top zones, and verified JOINs lose no rows (INNER JOIN and LEFT JOIN checks).
3. **Cleaning:** Investigated problems before removing anything (see below) and built `yellow_trips_clean`.
4. **Analysis:** Hourly, daily, weekday vs weekend, and top-zone queries.
5. **Visualization:** Power BI dashboard.

## Data Cleaning Methodology

The raw table `yellow_trips` is never modified. Cleaning produces a separate table, `yellow_trips_clean` (3,724,846 rows).

| # | Finding | Decision | Reason |
|---|---|---|---|
| 0 | 7 trips fall outside January 2026 (month-boundary trips) | **Exclude** | Keeps the analysis to one clean month |
| 1 | 1,088,058 rows (29.2%) have NULL `passenger_count`, `ratecode_id`, `store_and_fwd_flag`; all are `payment_type = 0` (Flex Fare) | **Keep** | NULLs are by design; pickup time and zone are complete |
| 2 | 41,545 trips have fare <= 0; 63% are Disputes and about 74% are Dispute or No-charge | **Keep for demand; exclude for revenue** | Mostly real business events, not errors |
| 3 | 1 trip with drop-off before pickup; 35 trips longer than 24 hours | **Exclude** | Impossible for a taxi trip |
| 4 | 125,738 zero-distance trips (97% were charged a fare); 45,069 trips with identical pickup and drop-off time | **Keep for demand; exclude for distance/speed** | Time and zone remain valid |
| 5 | 14,787 trips with `passenger_count = 0` | **Keep for demand** | Driver-entered field; trip still happened |
| 6 | 1 near-duplicate pair (differs in `trip_distance`) | **Keep** | Not an exact duplicate |

**Principle:** a row is only "bad" relative to the question being asked. Demand analysis needs pickup time and zone, so rows with unusable fare or passenger data are kept for it.

Tips are recorded only for card payments, so any tip analysis should be restricted to `payment_type = 1`.

## Key SQL Techniques Used

- `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`
- `GROUP BY`, `HAVING`, `COUNT / MIN / MAX`, `COUNT(*) FILTER (WHERE ...)`
- `INNER JOIN` and `LEFT JOIN` (to verify no unmatched zones)
- `CASE WHEN` (weekday vs weekend)
- Date functions: `EXTRACT(HOUR / DOW ...)`, `TO_CHAR`, `::date`, interval arithmetic
- CTE (`WITH`)
- Window function: `RANK() OVER (ORDER BY ...)`

Example (top pickup zones with ranking):

```sql
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
```

---

## Business Insights

1. **Demand peaks in the evening.** 6 PM is the busiest hour (265,573 trips), and demand stays high from 4 PM to 10 PM. The lowest hour is 4 AM (28,673 trips), about 9 times lower than the peak.
2. **Late-week days are strongest.** Averaged per day (to adjust for 5 Thursdays, Fridays, and Saturdays in the month), Saturday has about 134K trips and Sunday about 93K, so Saturday is roughly 44% busier than Sunday.
3. **Weekday vs weekend is nearly even per day.** About 122K trips per weekday vs 116K per weekend day. Raw totals (2.68M vs 1.05M) are misleading because there are 22 weekdays and 9 weekend days.
4. **Demand is concentrated in Manhattan.** 9 of the top 10 pickup zones are in Manhattan, led by Upper East Side South (160K trips). JFK Airport (153K) is the only non-Manhattan zone in the top 3.
5. **Card is the dominant payment method** (about 60% of trips), and cash is about 8%.

### Recommendations

- Concentrate driver supply between 4 PM and 8 PM, and on Thursday to Saturday.
- Prioritize the Upper East Side, Midtown, and JFK Airport for dispatch.
- Plan lighter supply for 2 AM to 5 AM and for Sundays.

## Conclusion

Taxi demand follows a clear daily rhythm (evening peak), a clear weekly rhythm (Saturday high, Sunday low), and strong geographic clustering in Manhattan and JFK Airport. These patterns can guide where and when to deploy drivers.

---

## Limitations and Future Work

- **Single month only (January 2026).** Month-to-month trends cannot be measured yet. Adding more months would answer "which months have the highest demand."
- Planned additions: an hour-by-day-of-week heatmap, top-N zones per borough using `RANK() OVER (PARTITION BY borough ...)`, and `LAG()` / moving-average analysis.
- Demand figures describe yellow taxis only (not green cabs or app-based services), and January weather and holidays may affect patterns.

## Repository Structure

```
nyc-taxi-demand-analysis/
├── README.md
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_data_exploration.sql
│   ├── 03_data_cleaning.sql
│   └── 04_analysis_queries.sql
├── dashboard/
│   ├── nyc_taxi_dashboard.pbix
│   └── dashboard_screenshot.png
└── data/
    └── README.md   (link to the TLC data)
```

## How to Reproduce

1. Download the January 2026 Yellow Taxi Parquet file and the Taxi Zone Lookup CSV from the TLC site.
2. Convert the Parquet file to CSV with pandas (lowercase and rename columns to match `sql/01_create_tables.sql`).
3. Create the tables and import both files into PostgreSQL.
4. Run the scripts in `sql/` in order.
5. Open the `.pbix` file in Power BI Desktop (or reload the exported CSVs).

## Author

**[Tejas Bhosale]** | [https://www.linkedin.com/in/tejas-bhosale-13020m/] | [https://github.com/tejasdeepak2005-create/]
