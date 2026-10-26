with source as (

    select * from {{ source('olist', 'sellers') }}

),

renamed as (

    select
        seller_id,
        lpad(cast(seller_zip_code_prefix as string), 5, '0')  as seller_zip_code_prefix,
        seller_city,
        upper(seller_state)                                    as seller_state

    from source

)

select * from renamed
