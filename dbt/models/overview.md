{% docs __overview__ %}

# Olist Analytics Stack

Documentation for the dbt project behind
[ArthurCota/olist-analytics-stack](https://github.com/ArthurCota/olist-analytics-stack):
an end-to-end analytics pipeline on ~100k real orders from Olist, the largest
Brazilian marketplace, with revenue in BRL and USD.

## Layers

| Layer | Dataset | What it does |
|---|---|---|
| Sources | `raw` | Olist CSVs and the daily USD/BRL rate from the Central Bank of Brazil, loaded as-is by Python scripts |
| Staging | `staging` | One view per source table: renaming, types, leading zeros in zip codes, surrogate keys |
| Intermediate | `intermediate` | Order-level aggregations and a daily exchange rate with weekends and holidays filled in |
| Marts | `marts` | Star schema for BI: `fct_orders`, `fct_order_items` and the customer, product, seller and date dimensions |

## How to explore

- Click **View Lineage Graph** (bottom right) to see how every table is built.
- Open any model on the left to see its description, columns, tests and SQL.

## Key definitions

- **Customer**: a person, identified by `customer_unique_id`. Olist creates a new
  `customer_id` for every order, so it cannot be used to follow a person over time.
- **GMV / order value**: items + freight. The amount actually paid is kept apart
  (`payment_value_*`) because installment interest and vouchers make it differ.
- **USD values**: converted at the Central Bank rate of the purchase date; weekends
  and holidays use the last business day's rate.
- **Valid order**: any status except `canceled` and `unavailable`.
- **Cohort**: the month of a customer's first purchase.

{% enddocs %}
