{{
    config(
        materialized='table'
    )
}}

-- 支払情報を注文単位で集約
-- 1注文に複数支払方法がある場合、支払金額が最大の支払方法を main_payment_type として代表値にする
WITH payments AS (
    SELECT
        order_id,
        SUM(payment_value)        AS sum_payment_value,
        MAX(payment_installments) AS max_payment_installments,
        ARRAY_AGG(payment_type ORDER BY payment_value DESC LIMIT 1)[OFFSET(0)] AS main_payment_type
    FROM {{ ref('prep_order_payments') }}
    GROUP BY order_id
)

SELECT
    -- ---- キー ----
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    o.customer_id,

    -- ---- 注文情報 ----
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- ---- 明細金額 ----
    oi.price,
    oi.freight_value,
    oi.shipping_limit_date,

    -- ---- 支払情報（注文単位集約）----
    p.sum_payment_value,
    p.main_payment_type,
    p.max_payment_installments,

    -- ---- 顧客情報 ----
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    geo_c.geolocation_lat  AS customer_lat,
    geo_c.geolocation_lng  AS customer_lng,

    -- ---- 商品情報 ----
    prod.product_category_name,
    cat.product_category_name_english,
    prod.product_weight_g,
    prod.product_length_cm,
    prod.product_height_cm,
    prod.product_width_cm,

    -- ---- 販売者情報 ----
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    geo_s.geolocation_lat  AS seller_lat,
    geo_s.geolocation_lng  AS seller_lng,

    -- ---- レビュー情報 ----
    r.review_score,
    r.review_creation_date

FROM {{ ref('prep_order_items') }}                            AS oi
LEFT JOIN {{ ref('prep_orders') }}                            AS o
    ON oi.order_id = o.order_id
LEFT JOIN {{ ref('prep_customers') }}                         AS c
    ON o.customer_id = c.customer_id
LEFT JOIN {{ ref('prep_products') }}                          AS prod
    ON oi.product_id = prod.product_id
LEFT JOIN {{ ref('prep_product_category_name_translation') }} AS cat
    ON prod.product_category_name = cat.product_category_name
LEFT JOIN {{ ref('prep_sellers') }}                           AS s
    ON oi.seller_id = s.seller_id
LEFT JOIN {{ ref('prep_geolocation') }}                       AS geo_c
    ON c.customer_zip_code_prefix = geo_c.geolocation_zip_code_prefix
LEFT JOIN {{ ref('prep_geolocation') }}                       AS geo_s
    ON s.seller_zip_code_prefix = geo_s.geolocation_zip_code_prefix
LEFT JOIN payments                                            AS p
    ON oi.order_id = p.order_id
LEFT JOIN {{ ref('prep_order_reviews') }}                     AS r
    ON oi.order_id = r.order_id
