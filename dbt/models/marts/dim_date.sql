-- Calendar covering every year with orders or deliveries, with the USD/BRL rate of each day.

with bounds as (

    select
        date_trunc(min(purchase_date), year)                         as first_day,
        last_day(max(greatest(purchase_date, estimated_delivery_date,
            coalesce(date(delivered_to_customer_at), purchase_date))), year) as last_day

    from {{ ref('int_orders_enriched') }}

),

calendar as (

    select date_day
    from bounds, unnest(generate_date_array(first_day, last_day)) as date_day

),

fx as (

    select * from {{ ref('int_fx_rates_daily') }}

),

final as (

    select
        calendar.date_day,
        extract(year from date_day)                     as year,
        extract(quarter from date_day)                  as quarter,
        extract(month from date_day)                    as month,
        format_date('%B', date_day)                     as month_name,
        format_date('%Y-%m', date_day)                  as year_month,
        date_trunc(date_day, month)                     as month_start,
        date_trunc(date_day, isoweek)                   as week_start,
        extract(dayofweek from date_day)                as day_of_week,   -- 1 = Sunday
        format_date('%A', date_day)                     as day_name,
        extract(dayofweek from date_day) in (1, 7)      as is_weekend,
        fx.brl_per_usd,
        fx.is_carried_forward                           as is_fx_carried_forward

    from calendar
    left join fx on calendar.date_day = fx.calendar_date

)

select * from final
