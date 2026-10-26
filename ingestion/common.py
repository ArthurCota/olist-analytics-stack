"""Shared helpers for the ingestion scripts."""
import os

from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv()

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
DATASET_RAW = os.getenv("BQ_DATASET_RAW", "raw")
LOCATION = os.getenv("BQ_LOCATION", "US")


def get_client() -> bigquery.Client:
    return bigquery.Client(project=PROJECT_ID, location=LOCATION)


def ensure_dataset(client: bigquery.Client, dataset_id: str = DATASET_RAW) -> str:
    """Create the dataset if it does not exist and return its full id."""
    full_id = f"{PROJECT_ID}.{dataset_id}"
    dataset = bigquery.Dataset(full_id)
    dataset.location = LOCATION
    client.create_dataset(dataset, exists_ok=True)
    return full_id
