select
    li.order_item_key,
    li.part_key,
    li.line_number,
    li.extended_price,
    o.order_key,
    o.customer_key,
    o.order_date,
    {{ discounted_amount('li.extended_price', 'li.discount_percentage') }} AS item_discount_amount
from
    {{ ref('stg__tpch_orders') }} o
join
    {{ ref('stg__tpch_line_items') }} li
        on o.order_key = li.order_key
order by
    o.order_date
