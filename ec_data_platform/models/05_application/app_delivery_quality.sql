{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 配送・品質分析ページ
-- 粒度: 1行 = 1年月
-- ソース: t_delivery_monthly

SELECT
    year_month,
    PARSE_DATE('%Y-%m', year_month) AS order_month,
    LEFT(year_month, 4)             AS order_year,
    cnt_delivered_orders_month,
    avg_delivery_days_month,
    p50_delivery_days_month,
    on_time_rate_month,
    cnt_late_orders_month,
    SAFE_DIVIDE(
        cnt_late_orders_month,
        NULLIF(cnt_delivered_orders_month, 0)
    )                               AS late_rate_month,
    avg_days_diff_vs_estimate_month,
    avg_review_score_month

FROM {{ ref('t_delivery_monthly') }}
ORDER BY year_month
