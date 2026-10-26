-- One row per order with item totals.

with items as (

    select * from {{ ref('stg_olist__order_items') }}

),

aggregated as (

    select
        order_id,
        count(*)                                as item_count,
        count(distinct product_id)              as distinct_product_count,
        count(distinct seller_id)               as distinct_seller_count,
        sum(price_brl)                          as items_value_brl,
        sum(freight_value_brl)                  as freight_value_brl,
        sum(price_brl + freight_value_brl)      as order_value_brl

    from items
    group by order_id

)

select * from aggregated
