-- An order can only be flagged as late if it was actually delivered.

select order_id
from {{ ref('fct_orders') }}
where is_late and delivered_to_customer_at is null
