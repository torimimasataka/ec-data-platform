{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1コホート(first_purchase_month) × 1計測月(year_month)
-- 対象: order_status = 'delivered'
-- 目的: 初回購入月別のリテンション分析
-- year_month >= first_purchase_month の行のみ出力（未来月は不要）

WITH base AS (
    SELECT
        customer_unique_id,
        order_id,
        price,
        order_purchase_timestamp,
        FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
),

-- 顧客ごとの初回購入月（全期間）
customer_first_month AS (
    SELECT
        customer_unique_id,
        FORMAT_DATE('%Y-%m', DATE(MIN(order_purchase_timestamp))) AS first_purchase_month
    FROM base
    GROUP BY customer_unique_id
),

-- コホートサイズ: first_purchase_month ごとのユニーク顧客数
cohort_size AS (
    SELECT
        first_purchase_month,
        COUNT(DISTINCT customer_unique_id) AS cnt_customers_cohort
    FROM customer_first_month
    GROUP BY first_purchase_month
),

-- 顧客×計測月の購入実績（コホート列付与）
customer_active AS (
    SELECT
        b.customer_unique_id,
        b.year_month,
        b.order_id,
        b.price,
        f.first_purchase_month
    FROM base AS b
    INNER JOIN customer_first_month AS f USING (customer_unique_id)
    WHERE b.year_month >= f.first_purchase_month
),

-- コホート×計測月の集計
cohort_agg AS (
    SELECT
        first_purchase_month,
        year_month,
        COUNT(DISTINCT customer_unique_id) AS cnt_active_customers,
        SUM(price)                         AS sum_price
    FROM customer_active
    GROUP BY first_purchase_month, year_month
)

SELECT
    cs.first_purchase_month,
    ca.year_month,
    DATE_DIFF(
        PARSE_DATE('%Y-%m', ca.year_month),
        PARSE_DATE('%Y-%m', cs.first_purchase_month),
        MONTH
    )                                                                AS months_since_first,
    cs.cnt_customers_cohort,
    ca.cnt_active_customers,
    SAFE_DIVIDE(
        ca.cnt_active_customers,
        NULLIF(cs.cnt_customers_cohort, 0)
    )                                                                AS retention_rate,
    ca.sum_price,
    SAFE_DIVIDE(
        ca.sum_price,
        NULLIF(ca.cnt_active_customers, 0)
    )                                                                AS avg_price_per_active_customer
FROM cohort_agg        AS ca
INNER JOIN cohort_size AS cs USING (first_purchase_month)
