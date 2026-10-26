-- Revenue must be identical whether it is summed from items or from orders.
-- Returns the orders where the two disagree (the test passes when it returns nothing).

with from_items as (

    select order_id, sum(item_value_brl) as value_brl
    from {{ ref('fct_order_items') }}
    group by order_id

),

from_orders as (

    select order_id, order_value_brl as value_brl
    from {{ ref('fct_orders') }}
    where item_count > 0

)

select
    coalesce(from_orders.order_id, from_items.order_id) as order_id,
    from_orders.value_brl as order_value_brl,
    from_items.value_brl  as items_value_brl

from from_orders
full outer join from_items using (order_id)
where from_orders.value_brl is distinct from from_items.value_brl
