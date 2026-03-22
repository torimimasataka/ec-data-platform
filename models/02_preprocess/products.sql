{{
    config(
        materialized='table'
    )
}}

-- product_category_name: NULL 約610件 → 'unknown' に補完
SELECT
    product_id,
    COALESCE(product_category_name, 'unknown')  AS product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM {{ source('olist_raw', 'products') }}
