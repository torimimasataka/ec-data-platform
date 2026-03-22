{{
    config(
        materialized='table'
    )
}}

-- payment_type: 'not_defined' 約3件 → 'unknown' に正規化
SELECT
    order_id,
    SAFE_CAST(payment_sequential AS INT64)  AS payment_sequential,
    CASE
        WHEN payment_type = 'not_defined' THEN 'unknown'
        ELSE payment_type
    END                                     AS payment_type,
    SAFE_CAST(payment_installments AS INT64) AS payment_installments,
    SAFE_CAST(payment_value AS FLOAT64)      AS payment_value
FROM {{ source('olist_raw', 'order_payments') }}
