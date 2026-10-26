-- One row per order with customer, items, payments, review, delivery metrics
-- and values converted to USD at the rate of the purchase date.

with orders as (

    select * from {{ ref('stg_olist__orders') }}

),

customers as (

    select * from {{ ref('stg_olist__customers') }}

),

items as (

    select * from {{ ref('int_order_items_aggregated') }}

),

payments as (

    select * from {{ ref('int_order_payments_aggregated') }}

),

reviews as (

    select * from {{ ref('int_order_reviews_aggregated') }}

),

fx as (

    select * from {{ ref('int_fx_rates_daily') }}

),

joined as (

    select
        -- order
        orders.order_id,
        orders.order_status,
        orders.purchased_at,
        orders.purchase_date,
        orders.approved_at,
        orders.delivered_to_carrier_at,
        orders.delivered_to_customer_at,
        orders.estimated_delivery_date,

        -- customer
        orders.customer_id,
        customers.customer_unique_id,
        customers.customer_zip_code_prefix,
        customers.customer_city,
        customers.customer_state,

        -- items
        coalesce(items.item_count, 0)               as item_count,
        coalesce(items.distinct_product_count, 0)   as distinct_product_count,
        coalesce(items.distinct_seller_count, 0)    as distinct_seller_count,
        coalesce(items.items_value_brl, 0)          as items_value_brl,
        coalesce(items.freight_value_brl, 0)        as freight_value_brl,
        coalesce(items.order_value_brl, 0)          as order_value_brl,

        -- payments
        coalesce(payments.payment_value_brl, 0)     as payment_value_brl,
        payments.payment_count,
        payments.main_payment_type,
        payments.max_installments,

        -- review
        reviews.review_score,
        reviews.avg_review_score,
        coalesce(reviews.review_count, 0)           as review_count,

        -- exchange rate
        fx.rate_date                                as fx_rate_date,
        fx.brl_per_usd

    from orders
    left join customers  on orders.customer_id = customers.customer_id
    left join items      on orders.order_id = items.order_id
    left join payments   on orders.order_id = payments.order_id
    left join reviews    on orders.order_id = reviews.order_id
    left join fx         on orders.purchase_date = fx.calendar_date

),

final as (

    select
        *,

        -- values in USD
        round(items_value_brl / brl_per_usd, 2)     as items_value_usd,
        round(freight_value_brl / brl_per_usd, 2)   as freight_value_usd,
        round(order_value_brl / brl_per_usd, 2)     as order_value_usd,
        round(payment_value_brl / brl_per_usd, 2)   as payment_value_usd,

        -- delivery
        order_status = 'delivered' and delivered_to_customer_at is not null
                                                    as is_delivered,
        date_diff(date(delivered_to_customer_at), purchase_date, day)
                                                    as delivery_days,
        -- positive = late, negative = early
        date_diff(date(delivered_to_customer_at), estimated_delivery_date, day)
                                                    as days_vs_estimate,
        date(delivered_to_customer_at) > estimated_delivery_date
                                                    as is_late,

        -- repeat purchase: 1 = first order of this person
        row_number() over (
            partition by customer_unique_id
            order by purchased_at, order_id
        )                                           as customer_order_number,
        min(purchase_date) over (partition by customer_unique_id)
                                                    as customer_first_purchase_date

    from joined

)

select * from final
