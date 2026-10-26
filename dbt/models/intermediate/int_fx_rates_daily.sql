-- The BCB only publishes rates on business days. This model creates one row per
-- calendar day and carries the last known rate forward over weekends and holidays,
-- so any order date can be converted to USD.

with rates as (

    select * from {{ ref('stg_bcb__fx_usd_brl') }}

),

calendar as (

    select calendar_date
    from unnest(generate_date_array(
        (select min(rate_date) from rates),
        current_date('America/Sao_Paulo')
    )) as calendar_date

),

joined as (

    select
        calendar.calendar_date,
        rates.rate_date      as published_rate_date,
        rates.brl_per_usd    as published_brl_per_usd

    from calendar
    left join rates
        on calendar.calendar_date = rates.rate_date

),

filled as (

    select
        calendar_date,
        last_value(published_rate_date ignore nulls) over running   as rate_date,
        last_value(published_brl_per_usd ignore nulls) over running as brl_per_usd,
        published_rate_date is null                                  as is_carried_forward

    from joined
    window running as (order by calendar_date rows between unbounded preceding and current row)

)

select * from filled
