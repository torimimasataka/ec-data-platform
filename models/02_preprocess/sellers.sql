{{
    config(
        materialized='table'
    )
}}

-- city の表記揺れを正規化（TRIM + LOWER）
WITH source AS (
    SELECT
        seller_id,
        CAST(seller_zip_code_prefix AS STRING)  AS seller_zip_code_prefix,
        TRIM(LOWER(seller_city))                AS seller_city,
        UPPER(TRIM(seller_state))               AS seller_state
    FROM {{ source('olist_raw', 'sellers') }}
)

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM source
