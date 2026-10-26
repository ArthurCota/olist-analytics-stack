with sellers as (

    select * from {{ ref('stg_olist__sellers') }}

),

geolocation as (

    select * from {{ ref('stg_olist__geolocation') }}

),

items as (

    select * from {{ ref('fct_order_items') }}

),

sales as (

    select
        seller_id,
        min(purchase_date)                      as first_sale_date,
        max(purchase_date)                      as last_sale_date,
        count(distinct order_id)                as total_orders,
        count(*)                                as total_items,
        sum(price_brl)                          as total_sales_brl,
        sum(price_usd)                          as total_sales_usd

    from items
    where order_status not in ('canceled', 'unavailable')
    group by seller_id

),

final as (

    select
        sellers.seller_id,
        sellers.seller_zip_code_prefix,
        sellers.seller_city,
        sellers.seller_state,
        geolocation.latitude,
        geolocation.longitude,
        sales.first_sale_date,
        sales.last_sale_date,
        coalesce(sales.total_orders, 0)         as total_orders,
        coalesce(sales.total_items, 0)          as total_items,
        coalesce(sales.total_sales_brl, 0)      as total_sales_brl,
        coalesce(sales.total_sales_usd, 0)      as total_sales_usd

    from sellers
    left join sales using (seller_id)
    left join geolocation
        on sellers.seller_zip_code_prefix = geolocation.zip_code_prefix

)

select * from final
