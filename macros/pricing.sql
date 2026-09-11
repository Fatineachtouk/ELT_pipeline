{% macro discounted_amount(extended_price, discount_percentage) %}
    (-1 * {{ extended_price }} * {{ discount_percentage }})::decimal(16, 2)
{% endmacro %}