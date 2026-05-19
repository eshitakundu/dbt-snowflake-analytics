# dbt-snowflake-analytics

An end-to-end analytics engineering project built with dbt Cloud and Snowflake. Models a fictional e-learning platform across six data sources — from raw seed data through staging, dimension/fact tables, and a consolidated performance mart.

---

## Architecture

```
seeds (raw CSVs)
    ↓
staging models (views) — clean, typed, one per source table
    ↓
dimension tables (tables) — entity descriptions with derived attributes
fact tables (tables)      — events joined across multiple dimensions
    ↓
mart_course_performance (table) — consolidated analytical output
```

---

## Stack

- **dbt Cloud** — transformation, testing, documentation, snapshots
- **Snowflake** — cloud data warehouse
- **dbt Fusion** 2.0 (preview)

---

## Project Structure

```
models/
├── staging/
│   ├── _sources.yml               # source declarations
│   ├── _staging_models.yml        # model docs + generic tests
│   ├── stg_elearning__students.sql
│   ├── stg_elearning__courses.sql
│   ├── stg_elearning__enrollments.sql
│   ├── stg_elearning__instructors.sql
│   ├── stg_elearning__payments.sql
│   └── stg_elearning__reviews.sql
└── marts/
    ├── dim_students.sql
    ├── dim_courses.sql
    ├── dim_instructors.sql
    ├── fct_enrollments.sql
    ├── fct_payments.sql
    ├── fct_reviews.sql
    └── mart_course_performance.sql

macros/
├── categorize_rating.sql
└── calculate_completion_rate.sql

snapshots/
└── students_snapshot.sql          # SCD Type 2 on subscription_type

tests/
├── assert_price_greater_than_zero.sql
├── assert_progress_pct_between_0_and_100.sql
├── assert_completion_date_after_enrolled_date.sql
└── assert_rating_between_1_and_5.sql

seeds/
├── raw_students.csv       (500 rows)
├── raw_courses.csv        (40 rows)
├── raw_instructors.csv    (20 rows)
├── raw_enrollments.csv    (2,341 rows)
├── raw_payments.csv       (1,767 rows)
└── raw_reviews.csv        (767 rows)
```

---

## Data Model

### Staging
One view per source table. Responsibilities: column renaming, type casting, null handling. No joins, no aggregations.

### Dimensions
- `dim_students` — student profiles with `age_group` derived column
- `dim_courses` — course details with `price_tier` and `course_length`
- `dim_instructors` — instructor profiles with `experience_level` and `rating_tier`

### Facts
- `fct_enrollments` — enrollment events joined with student and course attributes. Includes `is_completed` boolean and `days_to_complete`
- `fct_payments` — payment transactions with `discount_pct` vs listed price
- `fct_reviews` — review events joined across students, courses, and instructors. Uses `categorize_rating` macro

### Consolidated Mart
- `mart_course_performance` — one row per course aggregating enrollment counts, completion rates, revenue, and review sentiment. Uses both macros.

---

## Macros

- `categorize_rating(column)` — maps numeric rating to `Excellent / Good / Average / Poor`
- `calculate_completion_rate(completed, total)` — returns completion percentage with zero-division guard

---

## Tests

**47 tests total:**
- Generic: `unique`, `not_null`, `accepted_values` on all staging models
- Singular: 4 custom SQL tests for business rule validation

---

## Snapshots

`students_snapshot` tracks changes to `subscription_type` using SCD Type 2. New records get `dbt_valid_from` / `dbt_valid_to` timestamps when subscription changes.

---

## Running the Project

```bash
dbt seed          # load CSVs into Snowflake raw schema
dbt run           # build all models in dependency order
dbt test          # run all 47 tests
dbt snapshot      # capture student subscription state
dbt docs generate # generate documentation site
```

---

## Limitations & Future Improvements

- **No live data source** — currently uses seed CSVs. Production version would ingest from an API or S3 bucket via Airflow.
- **No Superset dashboard** — mart tables are ready for visualization but the BI layer is not yet connected.
- **Single snapshot** — only `subscription_type` is tracked historically. Course pricing changes are not captured.
