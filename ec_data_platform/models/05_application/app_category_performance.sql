{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 商品・カテゴリ分析ページ
-- 粒度: 1行 = 1カテゴリ × 1年月
-- ソース: t_category_monthly
-- 月次ランキング・全期間ランキングは BigQuery 側で計算して渡す

WITH base AS (
    SELECT
        product_category_name_english,
        year_month,
        PARSE_DATE('%Y-%m', year_month) AS order_month,
        LEFT(year_month, 4)             AS order_year,
        sum_price_month,
        cnt_orders_month,
        cnt_order_items_month,
        cnt_unique_customers_month,
        cnt_unique_sellers_month,
        avg_review_score_month,
        rate_price_in_all_month
    FROM {{ ref('t_category_monthly') }}
),

-- 全期間カテゴリ合計（全期間ランキング用）
all_time AS (
    SELECT
        product_category_name_english,
        SUM(sum_price_month)  AS sum_price_all_time,
        SUM(cnt_orders_month) AS cnt_orders_all_time,
        RANK() OVER (ORDER BY SUM(sum_price_month) DESC) AS rank_revenue_all_time
    FROM {{ ref('t_category_monthly') }}
    GROUP BY product_category_name_english
)

SELECT
    b.product_category_name_english,
    b.year_month,
    b.order_month,
    b.order_year,
    b.sum_price_month,
    b.cnt_orders_month,
    b.cnt_order_items_month,
    b.cnt_unique_customers_month,
    b.cnt_unique_sellers_month,
    b.avg_review_score_month,
    b.rate_price_in_all_month,

    -- 月次ランキング（その月の中での売上順位）
    RANK() OVER (
        PARTITION BY b.year_month
        ORDER BY b.sum_price_month DESC
    ) AS rank_revenue_month,

    -- 全期間集計
    a.sum_price_all_time,
    a.cnt_orders_all_time,
    a.rank_revenue_all_time

FROM base AS b
LEFT JOIN all_time AS a USING (product_category_name_english)
ORDER BY b.year_month, rank_revenue_month
