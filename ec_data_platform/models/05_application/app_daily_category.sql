{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 時系列分析ページ（カテゴリ別日次トレンド）
-- 粒度: 1行 = 1カテゴリ × 1日
-- ソース: unf_order_items（03_unification）
-- Looker Studio のフィルター（カテゴリ・期間）でカテゴリ別の時系列比較が可能

WITH base AS (
    SELECT
        DATE(order_purchase_timestamp)                               AS order_date,
        FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp))         AS year_month,
        LEFT(FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)), 4) AS order_year,
        COALESCE(product_category_name_english, 'Unknown')           AS product_category_name_english,
        order_id,
        customer_unique_id,
        price
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
)

SELECT
    order_date,
    year_month,
    order_year,
    product_category_name_english,
    SUM(price)                         AS sum_revenue,
    COUNT(DISTINCT order_id)           AS cnt_orders,
    COUNT(DISTINCT customer_unique_id) AS cnt_customers,
    SAFE_DIVIDE(
        SUM(price),
        NULLIF(COUNT(DISTINCT order_id), 0)
    )                                  AS aov,

    -- カテゴリ内の7日移動平均
    AVG(SUM(price)) OVER (
        PARTITION BY product_category_name_english
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS sum_revenue_7d_ma

FROM base
GROUP BY order_date, year_month, order_year, product_category_name_english
ORDER BY order_date, product_category_name_english
