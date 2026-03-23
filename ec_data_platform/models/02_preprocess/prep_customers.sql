{{
    config(
        materialized='table'
    )
}}

-- city の表記揺れを正規化（TRIM + LOWER）
WITH source AS (
    SELECT
        customer_id,
        customer_unique_id,
        CAST(customer_zip_code_prefix AS STRING)  AS customer_zip_code_prefix,
        TRIM(LOWER(customer_city))                AS customer_city,
        UPPER(TRIM(customer_state))               AS customer_state
    FROM {{ ref('src_customers') }}
)

SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM source
