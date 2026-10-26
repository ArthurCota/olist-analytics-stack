"""Load the Olist CSV files into the BigQuery raw dataset.

Each CSV becomes one table, e.g. olist_orders_dataset.csv -> raw.orders.
Tables are fully replaced on every run (the source is a static snapshot).

Usage:
    python ingestion/load_olist.py
"""
import os
from pathlib import Path

from google.cloud import bigquery

from common import ensure_dataset, get_client

CSV_DIR = Path(os.getenv("OLIST_CSV_DIR", "data/raw/olist"))

# Files where schema autodetection fails. When every column is text, BigQuery
# cannot tell the header from the data and names the columns string_field_0, 1...
EXPLICIT_SCHEMAS = {
    "product_category_name_translation": [
        bigquery.SchemaField("product_category_name", "STRING"),
        bigquery.SchemaField("product_category_name_english", "STRING"),
    ],
}


def table_name(csv_path: Path) -> str:
    """olist_order_items_dataset.csv -> order_items"""
    name = csv_path.stem
    name = name.removeprefix("olist_").removesuffix("_dataset")
    return name


def main() -> None:
    csv_files = sorted(CSV_DIR.glob("*.csv"))
    if not csv_files:
        raise SystemExit(f"No CSV files found in {CSV_DIR.resolve()}. Download the dataset from Kaggle first.")

    client = get_client()
    dataset_id = ensure_dataset(client)

    for csv_path in csv_files:
        name = table_name(csv_path)
        table_id = f"{dataset_id}.{name}"
        schema = EXPLICIT_SCHEMAS.get(name)
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            autodetect=schema is None,
            schema=schema,
            allow_quoted_newlines=True,  # review comments contain line breaks
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        )
        with csv_path.open("rb") as f:
            job = client.load_table_from_file(f, table_id, job_config=job_config)
        job.result()
        table = client.get_table(table_id)
        print(f"Loaded {table.num_rows:>7,} rows -> {table_id}")


if __name__ == "__main__":
    main()
