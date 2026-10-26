-- One row per item sold. Use this table for product, category and seller analysis.

with items as (

    select * from {{ ref('stg_olist__order_items') }}

),

orders as (

    select * from {{ ref('int_orders_enriched') }}

),

final as (

    select
        -- keys
        items.order_item_key,
        items.order_id,
        items.order_item_number,
        items.product_id,
        items.seller_id,
        orders.customer_unique_id,
        orders.purchase_date,

        -- context
        orders.order_status,
        orders.customer_state,
        items.shipping_limit_at,

        -- money
        items.price_brl,
        items.freight_value_brl,
        items.price_brl + items.freight_value_brl                   as item_value_brl,
        orders.brl_per_usd,
        round(items.price_brl / orders.brl_per_usd, 2)              as price_usd,
        round(items.freight_value_brl / orders.brl_per_usd, 2)      as freight_value_usd,
        round((items.price_brl + items.freight_value_brl) / orders.brl_per_usd, 2)
                                                                    as item_value_usd

    from items
    inner join orders on items.order_id = orders.order_id

)

select * from final
