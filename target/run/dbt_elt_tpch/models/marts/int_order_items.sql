
  
    

create or replace transient table dbt_db.dbt_schema.int_order_items
    
    
    
    
    

    as (select
    li.order_item_key,
    li.part_key,
    li.line_number,
    li.extended_price,
    o.order_key,
    o.customer_key,
    o.order_date,
    
    (-1 * li.extended_price * li.discount_percentage)::decimal(16, 2)
 AS item_discount_amount
from
    dbt_db.dbt_schema.stg__tpch_orders o
join
    dbt_db.dbt_schema.stg__tpch_line_items li
        on o.order_key = li.order_key
order by
    o.order_date
    )
;


  