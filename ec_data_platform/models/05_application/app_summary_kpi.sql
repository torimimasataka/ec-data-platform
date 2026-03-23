{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: サマリ（概況）ページ
-- 粒度: 1行 = 1年月
-- ソース: t_order_kpi_monthly
-- YTD（年累計）は BigQuery の WINDOW 関数で計算して渡す（Looker Studio側で集計させない）

SELECT
    year_month,
    PARSE_DATE('%Y-%m', year_month)  AS order_month,
    LEFT(year_month, 4)              AS order_year,
    sum_price_month,
    cnt_orders_month,
    cnt_order_items_month,
    cnt_active_customers_month,
    cnt_new_customers_month,
    cnt_repeat_customers_month,
    aov_month,
    repeat_customer_rate_month,
    avg_review_score_month,

    -- YTD: 年内の累計（期間フィルターと組み合わせてKPIカードに使用）
    SUM(sum_price_month) OVER (
        PARTITION BY LEFT(year_month, 4)
        ORDER BY year_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS sum_revenue_ytd,

    SUM(cnt_orders_month) OVER (
        PARTITION BY LEFT(year_month, 4)
        ORDER BY year_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cnt_orders_ytd

FROM {{ ref('t_order_kpi_monthly') }}
ORDER BY year_month
