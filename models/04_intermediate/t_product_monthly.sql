{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1商品(product_id) × 1年月(year_month)
-- 対象: order_status = 'delivered'
-- product_category_name_english は ANY_VALUE で取得

WITH base AS (
    SELECT
        product_id,
        FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month,
        order_id,
        price,
        customer_unique_id,
        product_category_name_english,
        review_score
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
),

-- 商品×月次 基本集計
product_agg AS (
    SELECT
        product_id,
        year_month,
        ANY_VALUE(product_category_name_english) AS product_category_name_english,
        SUM(price)                               AS sum_price_month,
        COUNT(DISTINCT order_id)                 AS cnt_orders_month,
        COUNT(*)                                 AS cnt_order_items_month,
        COUNT(DISTINCT customer_unique_id)       AS cnt_unique_customers_month
    FROM base
    GROUP BY product_id, year_month
),

-- レビュースコア: order_id 単位で重複排除してから平均
review_agg AS (
    SELECT
        product_id,
        year_month,
        SAFE_DIVIDE(
            SUM(review_score),
            NULLIF(COUNT(review_score), 0)
        ) AS avg_review_score_month
    FROM (
        SELECT DISTINCT
            product_id,
            year_month,
            order_id,
            review_score
        FROM base
    )
    GROUP BY product_id, year_month
)

SELECT
    p.product_id,
    p.year_month,
    p.product_category_name_english,
    p.sum_price_month,
    p.cnt_orders_month,
    p.cnt_order_items_month,
    p.cnt_unique_customers_month,
    SAFE_DIVIDE(p.sum_price_month, NULLIF(p.cnt_order_items_month, 0)) AS avg_item_price_month,
    r.avg_review_score_month
FROM product_agg     AS p
LEFT JOIN review_agg AS r USING (product_id, year_month)
