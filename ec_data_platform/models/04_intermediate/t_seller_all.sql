{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1販売者(seller_id)（全期間集計）
-- 対象: order_status = 'delivered'
-- t_customer_all の販売者版。Looker Studio の販売者ランキング・プロファイル分析に使用

WITH base AS (
    SELECT
        seller_id,
        order_id,
        price,
        order_purchase_timestamp,
        customer_unique_id,
        product_category_name_english,
        review_score,
        seller_state,
        seller_city
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
),

-- 基本集計（全期間）
seller_agg AS (
    SELECT
        seller_id,
        SUM(price)                         AS sum_price_all,
        COUNT(DISTINCT order_id)            AS cnt_orders_all,
        COUNT(*)                            AS cnt_order_items_all,
        COUNT(DISTINCT customer_unique_id)  AS cnt_unique_customers_all,
        COUNT(DISTINCT FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp))) AS cnt_active_months_all,
        COUNT(DISTINCT product_category_name_english) AS cnt_categories_all,
        MIN(order_purchase_timestamp)       AS first_order_ts_all,
        MAX(order_purchase_timestamp)       AS latest_order_ts_all,
        ANY_VALUE(seller_state)             AS seller_state,
        ANY_VALUE(seller_city)              AS seller_city
    FROM base
    GROUP BY seller_id
),

-- レビュースコア: order_id 単位で重複排除してから平均
review_agg AS (
    SELECT
        seller_id,
        SAFE_DIVIDE(
            SUM(review_score),
            NULLIF(COUNT(review_score), 0)
        ) AS avg_review_score_all
    FROM (
        SELECT DISTINCT seller_id, order_id, review_score
        FROM base
    )
    GROUP BY seller_id
),

-- カテゴリ別金額集計（主カテゴリ決定用）
cat_agg AS (
    SELECT
        seller_id,
        product_category_name_english,
        SUM(price) AS sum_price_cat
    FROM base
    GROUP BY seller_id, product_category_name_english
),

-- 主カテゴリ: 金額最大のカテゴリを DENSE_RANK + QUALIFY で一意化
main_cat AS (
    SELECT
        seller_id,
        product_category_name_english AS main_category_all
    FROM cat_agg
    QUALIFY
        DENSE_RANK() OVER (
            PARTITION BY seller_id
            ORDER BY sum_price_cat DESC, product_category_name_english
        ) = 1
),

-- カテゴリ一覧: ORDER BY を固定して再計算でも並びが安定
list_cat AS (
    SELECT
        seller_id,
        STRING_AGG(
            DISTINCT product_category_name_english
            ORDER BY product_category_name_english
        ) AS list_categories_all
    FROM base
    WHERE product_category_name_english IS NOT NULL
    GROUP BY seller_id
)

SELECT
    a.seller_id,
    a.sum_price_all,
    a.cnt_orders_all,
    a.cnt_order_items_all,
    a.cnt_unique_customers_all,
    a.cnt_active_months_all,
    a.cnt_categories_all,
    a.first_order_ts_all,
    a.latest_order_ts_all,
    r.avg_review_score_all,
    c.main_category_all,
    l.list_categories_all,
    a.seller_state,
    a.seller_city
FROM seller_agg    AS a
LEFT JOIN review_agg AS r USING (seller_id)
LEFT JOIN main_cat   AS c USING (seller_id)
LEFT JOIN list_cat   AS l USING (seller_id)
