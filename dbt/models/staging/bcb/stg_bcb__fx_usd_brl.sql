with source as (

    select * from {{ source('bcb', 'fx_usd_brl') }}

),

renamed as (

    select
        rate_date,
        -- how many reais one US dollar costs (free market sell rate, BCB SGS series 1)
        round(cast(usd_brl as numeric), 4)  as brl_per_usd

    from source

)

select * from renamed
