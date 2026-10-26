"""Incrementally load the daily USD/BRL rate (BCB SGS series 1) into BigQuery.

On the first run it loads everything since START_DATE. On later runs it only
fetches the days after the last date already in the table.

The BCB API limits daily series to 10-year windows per request, so the
period is fetched in yearly chunks.

Usage:
    python ingestion/load_fx.py
"""
from datetime import date, datetime, timedelta

import pandas as pd
import requests
from google.api_core.exceptions import NotFound
from google.cloud import bigquery
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from common import ensure_dataset, get_client

SERIES_ID = 1  # Dólar americano (venda) - comercial
TABLE = "fx_usd_brl"
START_DATE = date(2016, 1, 1)  # Olist orders start in 2016
URL = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.{series}/dados"
TIMEOUT = (10, 90)  # (connect, read) seconds — the BCB API can be slow


def make_session() -> requests.Session:
    """HTTP session with retries and backoff: the BCB API often times out or returns 5xx."""
    retry = Retry(
        total=5,
        connect=5,
        read=5,
        backoff_factor=2,  # waits 2s, 4s, 8s, 16s...
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=("GET",),
    )
    session = requests.Session()
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.headers.update({
        # The API is known to reject or stall requests without a browser-like User-Agent
        "User-Agent": "Mozilla/5.0 (olist-analytics-stack; +https://github.com/ArthurCota/olist-analytics-stack)",
        "Accept": "application/json",
    })
    return session


SESSION = make_session()


def last_loaded_date(client: bigquery.Client, table_id: str) -> date | None:
    try:
        rows = client.query(f"SELECT MAX(rate_date) AS d FROM `{table_id}`").result()
    except NotFound:
        return None
    return next(iter(rows)).d


def fetch(start: date, end: date) -> pd.DataFrame:
    params = {
        "formato": "json",
        "dataInicial": start.strftime("%d/%m/%Y"),
        "dataFinal": end.strftime("%d/%m/%Y"),
    }
    print(f"Fetching USD/BRL {start} -> {end}...")
    resp = SESSION.get(URL.format(series=SERIES_ID), params=params, timeout=TIMEOUT)
    if resp.status_code == 404:  # no data in the window (e.g. only a weekend)
        return pd.DataFrame(columns=["rate_date", "usd_brl"])
    resp.raise_for_status()

    df = pd.DataFrame(resp.json())
    if df.empty:
        return pd.DataFrame(columns=["rate_date", "usd_brl"])
    return pd.DataFrame({
        "rate_date": pd.to_datetime(df["data"], format="%d/%m/%Y").dt.date,
        "usd_brl": df["valor"].astype(float),
    })


def yearly_windows(start: date, end: date):
    while start <= end:
        window_end = min(date(start.year, 12, 31), end)
        yield start, window_end
        start = window_end + timedelta(days=1)


def main() -> None:
    client = get_client()
    table_id = f"{ensure_dataset(client)}.{TABLE}"

    last = last_loaded_date(client, table_id)
    start = last + timedelta(days=1) if last else START_DATE
    end = datetime.now().date()
    if start > end:
        print("Already up to date.")
        return

    frames = [fetch(s, e) for s, e in yearly_windows(start, end)]
    df = pd.concat(frames, ignore_index=True)
    df = df[df["rate_date"] >= start]  # the API can return the day before dataInicial
    if df.empty:
        print(f"No new rates between {start} and {end}.")
        return

    job_config = bigquery.LoadJobConfig(
        schema=[
            bigquery.SchemaField("rate_date", "DATE", mode="REQUIRED"),
            bigquery.SchemaField("usd_brl", "FLOAT64", mode="REQUIRED"),
        ],
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
    )
    client.load_table_from_dataframe(df, table_id, job_config=job_config).result()
    print(f"Loaded {len(df):,} rates ({df['rate_date'].min()} -> {df['rate_date'].max()}) -> {table_id}")


if __name__ == "__main__":
    main()
