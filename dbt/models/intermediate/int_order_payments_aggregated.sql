-- One row per order with payment totals. The amount paid can differ from
-- items + freight (interest on installments, vouchers), so both are kept.

with payments as (

    select * from {{ ref('stg_olist__order_payments') }}

),

aggregated as (

    select
        order_id,
        sum(payment_value_brl)                  as payment_value_brl,
        count(*)                                as payment_count,
        count(distinct payment_type)            as distinct_payment_type_count,
        max(payment_installments)               as max_installments,

        -- the method that paid the largest share of the order
        array_agg(payment_type order by payment_value_brl desc, payment_sequential limit 1)[offset(0)]
                                                as main_payment_type

    from payments
    group by order_id

)

select * from aggregated
