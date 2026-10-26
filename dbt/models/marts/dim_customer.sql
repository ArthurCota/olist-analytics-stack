-- One row per person (customer_unique_id). Olist creates a new customer_id for
-- every order, so customer_id cannot be used to follow a person over time.

with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

geolocation as (

    select * from {{ ref('stg_olist__geolocation') }}

),

latest_address as (

    -- address used on the most recent order
    select
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state

    from orders
    qualify row_number() over (
        partition by customer_unique_id
        order by purchased_at desc, order_id desc
    ) = 1

),

order_stats as (

    select
        customer_unique_id,
        min(purchase_date)                                  as first_purchase_date,
        max(purchase_date)                                  as last_purchase_date,
        count(*)                                            as total_orders,
        countif(order_status not in ('canceled', 'unavailable'))
                                                            as valid_orders,
        sum(if(order_status not in ('canceled', 'unavailable'), order_value_brl, 0))
                                                            as lifetime_value_brl,
        sum(if(order_status not in ('canceled', 'unavailable'), order_value_usd, 0))
                                                            as lifetime_value_usd

    from orders
    group by customer_unique_id

),

final as (

    select
        order_stats.customer_unique_id,
        latest_address.customer_zip_code_prefix,
        latest_address.customer_city,
        latest_address.customer_state,
        geolocation.latitude,
        geolocation.longitude,

        order_stats.first_purchase_date,
        date_trunc(order_stats.first_purchase_date, month)  as cohort_month,
        order_stats.last_purchase_date,
        order_stats.total_orders,
        order_stats.valid_orders,
        order_stats.total_orders > 1                        as is_repeat_customer,
        order_stats.lifetime_value_brl,
        order_stats.lifetime_value_usd

    from order_stats
    left join latest_address using (customer_unique_id)
    left join geolocation
        on latest_address.customer_zip_code_prefix = geolocation.zip_code_prefix

)

select * from final
