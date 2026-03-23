{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1カテゴリ(product_category_name_english) × 1年月(year_month)
-- 対象: order_status = 'delivered'、カテゴリ名 NOT NULL
-- rate_price_in_all_month: その月の全カテゴリ売上に対するシェア

WITH base AS (
    SELECT
        product_category_name_english,
        FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month,
        order_id,
        price,
        customer_unique_id,
        seller_id,
        review_score
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
      AND product_category_name_english IS NOT NULL
),

-- 月別全体合計（シェア計算用）
monthly_total AS (
    SELECT
        year_month,
        SUM(price) AS sum_price_all_month
    FROM base
    GROUP BY year_month
),

-- カテゴリ×月次 基本集計
cat_agg AS (
    SELECT
        product_category_name_english,
        year_month,
        SUM(price)                         AS sum_price_month,
        COUNT(DISTINCT order_id)            AS cnt_orders_month,
        COUNT(*)                            AS cnt_order_items_month,
        COUNT(DISTINCT customer_unique_id)  AS cnt_unique_customers_month,
        COUNT(DISTINCT seller_id)           AS cnt_unique_sellers_month
    FROM base
    GROUP BY product_category_name_english, year_month
),

-- レビュースコア: order_id 単位で重複排除してから平均
review_agg AS (
    SELECT
        product_category_name_english,
        year_month,
        SAFE_DIVIDE(
            SUM(review_score),
            NULLIF(COUNT(review_score), 0)
        ) AS avg_review_score_month
    FROM (
        SELECT DISTINCT
            product_category_name_english,
            year_month,
            order_id,
            review_score
        FROM base
    )
    GROUP BY product_category_name_english, year_month
)

SELECT
    c.product_category_name_english,
    c.year_month,
    c.sum_price_month,
    c.cnt_orders_month,
    c.cnt_order_items_month,
    c.cnt_unique_customers_month,
    c.cnt_unique_sellers_month,
    r.avg_review_score_month,
    SAFE_DIVIDE(c.sum_price_month, NULLIF(t.sum_price_all_month, 0)) AS rate_price_in_all_month
FROM cat_agg        AS c
LEFT JOIN monthly_total AS t USING (year_month)
LEFT JOIN review_agg    AS r USING (product_category_name_english, year_month)
