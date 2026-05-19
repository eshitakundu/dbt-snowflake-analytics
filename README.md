# dbt-snowflake-analytics

End-to-end analytics engineering project built with dbt Cloud and Snowflake. Models a fictional e-learning platform — 6 data sources, 13 models across staging/dimension/fact layers, 47 tests, SCD Type 2 snapshot, and a live documentation site.

**[Live dbt Docs →](https://eshitakundu.github.io/dbt-snowflake-analytics)**

---

## Architecture

```
seeds (raw CSVs)
    ↓
staging (views)     — typed, cleaned, one model per source
    ↓
dimensions (tables) — entity attributes with derived columns
facts (tables)      — events joined across multiple dimensions
    ↓
mart_course_performance — consolidated analytical output
```

---

## Stack

| Tool | Role |
|------|------|
| dbt Cloud (Fusion 2.0) | Transformation, testing, documentation, orchestration |
| Snowflake | Cloud data warehouse |
| GitHub Pages | Hosts live dbt docs site |

---

## Data Sources

| File | Rows | Description |
|------|------|-------------|
| `raw_students.csv` | 500 | Student profiles — country, subscription type, signup date |
| `raw_courses.csv` | 40 | Course catalog — category, level, price, duration |
| `raw_instructors.csv` | 20 | Instructor profiles — expertise, rating, tenure |
| `raw_enrollments.csv` | 2,341 | Enrollment events — completion status, progress, ratings |
| `raw_payments.csv` | 1,767 | Payment transactions — amount, method, date |
| `raw_reviews.csv` | 767 | Course reviews — sentiment, helpful votes, verified purchase |

---

## Models

### Staging — 6 views
Clean, typed representations of each source table. No joins, no business logic.

### Dimensions — 3 tables
| Model | Key additions |
|-------|--------------|
| `dim_students` | `age_group` derived from age |
| `dim_courses` | `price_tier`, `course_length` |
| `dim_instructors` | `experience_level`, `rating_tier` |

### Facts — 3 tables
| Model | Joins | Key additions |
|-------|-------|--------------|
| `fct_enrollments` | students, courses | `is_completed` boolean, `days_to_complete` |
| `fct_payments` | students, courses | `discount_pct` vs listed price |
| `fct_reviews` | students, courses, instructors | `rating_category` via macro |

### Consolidated Mart — 1 table
`mart_course_performance` — one row per course. Aggregates enrollment counts, completion rates, revenue, average ratings, and review sentiment. Uses both custom macros.

---

## Macros

```sql
{{ categorize_rating('rating') }}
-- Maps numeric rating → 'Excellent' / 'Good' / 'Average' / 'Poor'

{{ calculate_completion_rate('completed_count', 'total_enrolled') }}
-- Returns completion % with zero-division guard
```

---

## Tests

**47 tests total**
- Generic: `unique`, `not_null`, `accepted_values` across all 6 staging models
- Singular: 4 custom SQL tests for business rule validation
  - Price > 0
  - Progress % between 0 and 100
  - Completion date after enrolled date
  - Rating between 1 and 5

---

## Snapshot

`students_snapshot` — SCD Type 2 on `subscription_type`. Tracks subscription changes over time with `dbt_valid_from` / `dbt_valid_to` timestamps.

---

## Running the Project

```bash
dbt seed                        # load CSVs into Snowflake raw schema
dbt run                         # build all 13 models in dependency order
dbt test                        # run all 47 tests
dbt snapshot                    # capture student subscription state
dbt compile --write-catalog     # generate catalog.json for docs site
```

---

## Documentation

Live dbt docs with full lineage, model descriptions, column definitions, and test results:

**[eshitakundu.github.io/dbt-snowflake-analytics](https://eshitakundu.github.io/dbt-snowflake-analytics)**

---

## Limitations & Future Improvements

- **No live data source** — seed CSVs replace a real ingestion layer. Production version would pull from a REST API or S3 via Airflow.
- **No BI dashboard** — mart tables are warehouse-ready but Superset/Metabase visualization is not yet connected.
- **Single snapshot** — only `subscription_type` is tracked historically. Course pricing changes are not captured.
- **dbt Fusion limitations** — running on Fusion 2.0 preview which has breaking changes from dbt Core. `accepted_values` test syntax differs from standard dbt documentation.