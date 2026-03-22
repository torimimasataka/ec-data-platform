{{
    config(
        materialized='table'
    )
}}

SELECT
    product_category_name,
    product_category_name_english
FROM {{ ref('src_product_category_name_translation') }}
WHERE product_category_name IS NOT NULL
