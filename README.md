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

## Key results

_TODO: headline numbers from the analysis._

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
  models/staging/   one cleaned view per raw table (renaming, types, zip codes, keys)
airflow/     Airflow DAGs and docker-compose
notebooks/   Cohort analysis and revenue forecast
dashboard/   Power BI file and screenshots
docs/        Architecture diagram and images
```

## Author

**Arthur Cota** — Data Analyst · [LinkedIn](#) · [GitHub](#)
