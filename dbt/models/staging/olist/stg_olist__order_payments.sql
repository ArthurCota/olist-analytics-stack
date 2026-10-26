with source as (

    select * from {{ source('olist', 'order_payments') }}

),

renamed as (

    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'payment_sequential']) }}  as payment_key,
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        round(cast(payment_value as numeric), 2)        as payment_value_brl

    from source

)

select * from renamed
