{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1販売者(seller_id) × 1年月(year_month)
-- 対象: order_status = 'delivered'
-- 主カテゴリ: その月に最も売上の高かったカテゴリ

WITH base AS (
    SELECT
        seller_id,
        FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month,
        order_id,
        price,
        customer_unique_id,
        product_category_name_english,
        review_score,
        seller_state
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
),

-- カテゴリ別金額集計（主カテゴリ決定用）
cat_agg AS (
    SELECT
        seller_id,
        year_month,
        product_category_name_english,
        SUM(price) AS sum_price_cat_month
    FROM base
    GROUP BY seller_id, year_month, product_category_name_english
),

-- 主カテゴリ: 金額最大のカテゴリを DENSE_RANK + QUALIFY で一意化
main_cat AS (
    SELECT
        seller_id,
        year_month,
        product_category_name_english AS main_category_month
    FROM cat_agg
    QUALIFY
        DENSE_RANK() OVER (
            PARTITION BY seller_id, year_month
            ORDER BY sum_price_cat_month DESC, product_category_name_english
        ) = 1
),

-- レビュースコア: order_id 単位で重複排除してから平均
review_agg AS (
    SELECT
        seller_id,
        year_month,
        SAFE_DIVIDE(
            SUM(review_score),
            NULLIF(COUNT(review_score), 0)
        ) AS avg_review_score_month
    FROM (
        SELECT DISTINCT seller_id, year_month, order_id, review_score
        FROM base
    )
    GROUP BY seller_id, year_month
),

-- 基本集計
seller_agg AS (
    SELECT
        seller_id,
        year_month,
        SUM(price)                        AS sum_price_month,
        COUNT(DISTINCT order_id)           AS cnt_orders_month,
        COUNT(*)                           AS cnt_order_items_month,
        COUNT(DISTINCT customer_unique_id) AS cnt_unique_customers_month,
        ANY_VALUE(seller_state)            AS seller_state
    FROM base
    GROUP BY seller_id, year_month
)

SELECT
    s.seller_id,
    s.year_month,
    s.sum_price_month,
    s.cnt_orders_month,
    s.cnt_order_items_month,
    s.cnt_unique_customers_month,
    r.avg_review_score_month,
    c.main_category_month,
    s.seller_state
FROM seller_agg     AS s
LEFT JOIN review_agg AS r USING (seller_id, year_month)
LEFT JOIN main_cat   AS c USING (seller_id, year_month)
