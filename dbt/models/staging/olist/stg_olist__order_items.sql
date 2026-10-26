with source as (

    select * from {{ source('olist', 'order_items') }}

),

renamed as (

    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }}  as order_item_key,
        order_id,
        order_item_id                                   as order_item_number,
        product_id,
        seller_id,
        datetime(shipping_limit_date)                   as shipping_limit_at,

        -- money as NUMERIC to avoid floating point rounding in sums
        round(cast(price as numeric), 2)                as price_brl,
        round(cast(freight_value as numeric), 2)        as freight_value_brl

    from source

)

select * from renamed
