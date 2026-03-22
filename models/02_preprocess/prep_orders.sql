{{
    config(
        materialized='table'
    )
}}

SELECT
    order_id,
    customer_id,
    order_status,
    SAFE_CAST(order_purchase_timestamp AS TIMESTAMP)       AS order_purchase_timestamp,
    SAFE_CAST(order_approved_at AS TIMESTAMP)              AS order_approved_at,
    SAFE_CAST(order_delivered_carrier_date AS TIMESTAMP)   AS order_delivered_carrier_date,
    SAFE_CAST(order_delivered_customer_date AS TIMESTAMP)  AS order_delivered_customer_date,
    SAFE_CAST(order_estimated_delivery_date AS TIMESTAMP)  AS order_estimated_delivery_date
FROM {{ ref('src_orders') }}
