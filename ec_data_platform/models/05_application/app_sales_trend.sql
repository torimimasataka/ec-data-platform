{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 売上・トレンド分析ページ
-- 粒度: 1行 = 1カテゴリ × 1年月
-- ソース: t_category_monthly
-- 前年同月比（YoY）は LAG(12) で BigQuery 側で計算して渡す（Looker Studio側で計算させない）

WITH base AS (
    SELECT
        product_category_name_english,
        year_month,
        PARSE_DATE('%Y-%m', year_month) AS order_month,
        LEFT(year_month, 4)             AS order_year,
        sum_price_month,
        cnt_orders_month,
        cnt_unique_customers_month,
        avg_review_score_month,
        rate_price_in_all_month
    FROM {{ ref('t_category_monthly') }}
),

with_rank AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY year_month
            ORDER BY sum_price_month DESC
        ) AS rank_revenue_month
    FROM base
)

SELECT
    product_category_name_english,
    year_month,
    order_month,
    order_year,
    sum_price_month,
    cnt_orders_month,
    cnt_unique_customers_month,
    avg_review_score_month,
    rate_price_in_all_month,
    rank_revenue_month,

    -- 前年同月売上（YoY計算用）
    LAG(sum_price_month, 12) OVER (
        PARTITION BY product_category_name_english
        ORDER BY year_month
    ) AS sum_price_prev_year,

    -- 前年比（率）
    SAFE_DIVIDE(
        sum_price_month - LAG(sum_price_month, 12) OVER (
            PARTITION BY product_category_name_english
            ORDER BY year_month
        ),
        NULLIF(
            LAG(sum_price_month, 12) OVER (
                PARTITION BY product_category_name_english
                ORDER BY year_month
            ),
            0
        )
    ) AS rate_yoy_revenue

FROM with_rank
ORDER BY year_month, rank_revenue_month
