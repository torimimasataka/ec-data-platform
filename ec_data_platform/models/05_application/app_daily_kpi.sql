{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 日次トレンド分析ページ
-- 粒度: 1行 = 1日
-- ソース: unf_order_items（03_unification）日次集計テーブルが 04_intermediate にないため直接集計
-- 7日・30日移動平均は BigQuery 側で計算して渡す（Looker Studio側で計算させない）

WITH base AS (
    SELECT
        DATE(order_purchase_timestamp)                               AS order_date,
        FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp))         AS year_month,
        LEFT(FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)), 4) AS order_year,
        EXTRACT(DAYOFWEEK FROM order_purchase_timestamp)              AS day_of_week_num,  -- 1=日 〜 7=土
        FORMAT_TIMESTAMP('%A', order_purchase_timestamp)              AS day_of_week_name,
        order_id,
        customer_unique_id,
        price
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
),

-- 日次集計（order_id・customer_unique_id の重複に注意）
daily_agg AS (
    SELECT
        order_date,
        year_month,
        order_year,
        day_of_week_num,
        day_of_week_name,
        SUM(price)                         AS sum_revenue,
        COUNT(DISTINCT order_id)           AS cnt_orders,
        COUNT(DISTINCT customer_unique_id) AS cnt_customers
    FROM base
    GROUP BY order_date, year_month, order_year, day_of_week_num, day_of_week_name
)

SELECT
    order_date,
    year_month,
    order_year,
    day_of_week_num,
    day_of_week_name,
    sum_revenue,
    cnt_orders,
    cnt_customers,
    SAFE_DIVIDE(sum_revenue, NULLIF(cnt_orders, 0)) AS aov,

    -- 7日移動平均（直近7日間の平均）
    AVG(sum_revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS sum_revenue_7d_ma,

    AVG(cnt_orders) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS cnt_orders_7d_ma,

    -- 30日移動平均
    AVG(sum_revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS sum_revenue_30d_ma

FROM daily_agg
ORDER BY order_date
