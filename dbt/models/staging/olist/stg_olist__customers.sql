with source as (

    select * from {{ source('olist', 'customers') }}

),

renamed as (

    select
        -- customer_id is unique per order; customer_unique_id identifies the person
        customer_id,
        customer_unique_id,

        -- zip prefixes were read as integers and lost their leading zero (e.g. 1003 -> '01003')
        lpad(cast(customer_zip_code_prefix as string), 5, '0')  as customer_zip_code_prefix,
        customer_city,
        upper(customer_state)                                    as customer_state

    from source

)

select * from renamed
