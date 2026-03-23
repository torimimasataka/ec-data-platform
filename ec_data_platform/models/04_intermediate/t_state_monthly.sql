{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1顧客州(customer_state) × 1年月(year_month)
-- 対象: order_status = 'delivered'
-- 目的: 州別の売上・注文・顧客動向の月次推移（地域ヒートマップ・地域分析用）

WITH base AS (
    SELECT
        customer_state,
        FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month,
        order_id,
        price,
        freight_value,
        customer_unique_id,
        review_score
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
      AND customer_state IS NOT NULL
),

-- 月別全体合計（シェア計算用）
monthly_total AS (
    SELECT
        year_month,
        SUM(price) AS sum_price_all_month
    FROM base
    GROUP BY year_month
),

-- 州×月次 基本集計
state_agg AS (
    SELECT
        customer_state,
        year_month,
        SUM(price)                        AS sum_price_month,
        SUM(freight_value)                AS sum_freight_month,
        COUNT(DISTINCT order_id)           AS cnt_orders_month,
        COUNT(*)                           AS cnt_order_items_month,
        COUNT(DISTINCT customer_unique_id) AS cnt_unique_customers_month
    FROM base
    GROUP BY customer_state, year_month
),

-- レビュースコア: order_id 単位で重複排除してから平均
review_agg AS (
    SELECT
        customer_state,
        year_month,
        SAFE_DIVIDE(
            SUM(review_score),
            NULLIF(COUNT(review_score), 0)
        ) AS avg_review_score_month
    FROM (
        SELECT DISTINCT customer_state, year_month, order_id, review_score
        FROM base
    )
    GROUP BY customer_state, year_month
)

SELECT
    s.customer_state,
    s.year_month,
    s.sum_price_month,
    s.sum_freight_month,
    s.cnt_orders_month,
    s.cnt_order_items_month,
    s.cnt_unique_customers_month,
    r.avg_review_score_month,
    SAFE_DIVIDE(s.sum_price_month, NULLIF(t.sum_price_all_month, 0)) AS rate_price_in_all_month
FROM state_agg      AS s
LEFT JOIN monthly_total AS t USING (year_month)
LEFT JOIN review_agg    AS r USING (customer_state, year_month)
