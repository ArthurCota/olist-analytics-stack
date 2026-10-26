# Olist Analytics Stack

> End-to-end analytics pipeline on real Brazilian e-commerce data: daily orchestrated ingestion, a cloud data warehouse, tested dbt models, cohort analysis and a revenue dashboard in BRL and USD.

🚧 **Work in progress** — being built in public, step by step.

## Business problem

_TODO: two sentences on the question this project answers (e.g. what drives repeat purchases, and how delivery delays affect review scores)._

## Architecture

_TODO: architecture diagram._

```
Olist CSVs ─┐
            ├─► BigQuery (raw) ─► dbt (staging → intermediate → marts) ─► Power BI
BCB API ────┘        ▲
                     └── Airflow (daily) · GitHub Actions (CI on every PR)
```

## Stack

| Layer | Tool |
|---|---|
| Ingestion | Python |
| Warehouse | Google BigQuery |
| Transformation | dbt Core |
| Orchestration | Apache Airflow (Docker) |
| CI | GitHub Actions |
| BI | Power BI |

## Data sources

- [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — ~100k orders, 2016–2018
- [Central Bank of Brazil (SGS) API](https://dadosabertos.bcb.gov.br/) — daily USD/BRL rate, series 1

## Data quality

Issues found in the raw data and how the staging layer handles them:

| Issue | Fix |
|---|---|
| Zip code prefixes read as integers lost their leading zero (23,995 customers) | `lpad(..., 5, '0')` back to 5-digit strings |
| `review_id` is not unique (98,410 ids for 99,224 rows) | Grain set to `review_id + order_id` with a surrogate key |
| ~1M geolocation rows, several per zip, some outside Brazil | Filtered to Brazil's bounding box and reduced to one row per zip |
| Category translation CSV loaded with generic column names | Explicit schema in the loader |
| Typos in source columns (`product_name_lenght`) | Renamed in staging |
| Money stored as FLOAT | Cast to `NUMERIC` to avoid rounding errors in sums |

Every staging model is covered by `unique`, `not_null`, `relationships` and `accepted_values` tests.

## Data model

Star schema in the `marts` dataset, built and tested with dbt:

| Table | Grain | Highlights |
|---|---|---|
| `fct_orders` | one row per order | GMV and amount paid in BRL and USD, delivery days, lateness, review score, cohort month |
| `fct_order_items` | one row per item | price and freight in BRL and USD, product and seller keys |
| `dim_customer` | one row per person | cohort month, lifetime value, repeat flag, location |
| `dim_product` | one row per product | category in Portuguese and English |
| `dim_seller` | one row per seller | location and sales totals |
| `dim_date` | one row per day | calendar attributes and the USD/BRL rate of the day |

USD values use the Central Bank rate of the purchase date; weekends and holidays use the last business day's rate.

## Key results

Preliminary numbers from the marts (full analysis in progress):

- **Late deliveries kill satisfaction:** average review score is **2.27** for late orders vs **4.29** for on-time orders.
- **Very low repeat purchase:** only **3.1%** of customers (2,997 of 96,096) ever placed a second order.
- **GMV:** R$ 15.8M ≈ **US$ 4.7M** at daily exchange rates, across ~99k orders (Sep 2016 – Oct 2018).
- **Average delivery time:** 12.5 days.

## How to run

```bash
# 1. Install dependencies
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# 2. Authenticate with Google Cloud
gcloud auth application-default login

# 3. Configure
cp .env.example .env             # then fill in your GCP project id

# 4. Load the data
python ingestion/load_olist.py   # CSVs must be in data/raw/olist/
python ingestion/load_fx.py

# 5. Build and test the dbt models
cd dbt
dbt deps
dbt build
```

## Project structure

```
ingestion/   Python scripts that load raw data into BigQuery
dbt/         dbt project (staging, intermediate, marts, tests)
  models/staging/        one cleaned view per raw table (renaming, types, zip codes, keys)
  models/intermediate/   order-level joins: items, payments, reviews, daily FX rate, delivery metrics
  models/marts/          star schema for BI: fct_orders, fct_order_items, dim_customer, dim_product, dim_seller, dim_date
  seeds/                 small reference data (missing category translations)
  tests/                 custom tests, e.g. item revenue reconciles with order revenue
airflow/     Airflow DAGs and docker-compose
notebooks/   Cohort analysis and revenue forecast
dashboard/   Power BI file and screenshots
docs/        Architecture diagram and images
```

## Author

**Arthur Cota** — Data Analyst · [LinkedIn](#) · [GitHub](#)
