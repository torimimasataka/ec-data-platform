{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 顧客分析ページ（コホートリテンション）
-- 粒度: 1行 = 1コホート月(first_purchase_month) × 1計測月(year_month)
-- ソース: t_cohort_monthly
-- app_customer_rfm と同じ「顧客分析」ページで使うが粒度が異なるため別テーブルに分離

SELECT
    first_purchase_month,
    year_month,
    PARSE_DATE('%Y-%m', first_purchase_month) AS cohort_month,
    PARSE_DATE('%Y-%m', year_month)           AS order_month,
    months_since_first,
    cnt_customers_cohort,
    cnt_active_customers,
    retention_rate,
    sum_price,
    avg_price_per_active_customer

FROM {{ ref('t_cohort_monthly') }}
ORDER BY first_purchase_month, year_month
