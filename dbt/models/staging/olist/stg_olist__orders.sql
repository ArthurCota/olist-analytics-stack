with source as (

    select * from {{ source('olist', 'orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        order_status,

        -- Olist timestamps are Brazil local time without a timezone;
        -- keep them as DATETIME so the wall-clock time is not shifted
        datetime(order_purchase_timestamp)       as purchased_at,
        datetime(order_approved_at)              as approved_at,
        datetime(order_delivered_carrier_date)   as delivered_to_carrier_at,
        datetime(order_delivered_customer_date)  as delivered_to_customer_at,
        date(order_estimated_delivery_date)      as estimated_delivery_date,

        date(order_purchase_timestamp)           as purchase_date

    from source

)

select * from renamed
