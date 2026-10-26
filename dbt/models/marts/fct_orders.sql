-- One row per order. Joins to dim_customer on customer_unique_id and to dim_date on purchase_date.

with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

final as (

    select
        -- keys
        order_id,
        customer_unique_id,
        customer_id,
        purchase_date,

        -- status and timeline
        order_status,
        order_status not in ('canceled', 'unavailable')     as is_valid_order,
        purchased_at,
        approved_at,
        delivered_to_carrier_at,
        delivered_to_customer_at,
        estimated_delivery_date,

        -- delivery
        is_delivered,
        delivery_days,
        days_vs_estimate,
        is_late,

        -- customer location at the time of the order
        customer_state,
        customer_city,

        -- basket
        item_count,
        distinct_product_count,
        distinct_seller_count,

        -- money (BRL)
        items_value_brl,
        freight_value_brl,
        order_value_brl,
        payment_value_brl,

        -- money (USD, rate of the purchase date)
        brl_per_usd,
        fx_rate_date,
        items_value_usd,
        freight_value_usd,
        order_value_usd,
        payment_value_usd,

        -- payment
        main_payment_type,
        payment_count,
        max_installments,

        -- review
        review_score,
        avg_review_score,
        review_count,

        -- cohorts
        customer_order_number,
        customer_order_number = 1                           as is_first_order,
        date_trunc(customer_first_purchase_date, month)     as cohort_month,
        date_diff(
            date_trunc(purchase_date, month),
            date_trunc(customer_first_purchase_date, month),
            month
        )                                                   as months_since_first_purchase

    from orders

)

select * from final
