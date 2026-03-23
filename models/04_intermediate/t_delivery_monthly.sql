{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1年月(year_month)（配送パフォーマンス月次KPI）
-- 対象: order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
-- year_month は order_purchase_timestamp ベース
-- 注文単位で重複排除してから集計（order_items の重複を排除）

WITH base AS (
    SELECT
        order_id,
        FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month,
        review_score,
        DATE_DIFF(
            DATE(order_delivered_customer_date),
            DATE(order_purchase_timestamp),
            DAY
        ) AS delivery_days,
        DATE_DIFF(
            DATE(order_delivered_customer_date),
            DATE(order_estimated_delivery_date),
            DAY
        ) AS days_diff_vs_estimate,
        (DATE(order_delivered_customer_date) <= DATE(order_estimated_delivery_date)) AS is_on_time
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
),

-- 注文単位で重複排除（同一注文に複数明細があるため）
order_dedup AS (
    SELECT DISTINCT
        order_id,
        year_month,
        delivery_days,
        days_diff_vs_estimate,
        is_on_time
    FROM base
),

-- 月次配送集計
delivery_agg AS (
    SELECT
        year_month,
        COUNT(DISTINCT order_id)                                   AS cnt_delivered_orders_month,
        AVG(delivery_days)                                         AS avg_delivery_days_month,
        APPROX_QUANTILES(delivery_days, 100)[OFFSET(50)]           AS p50_delivery_days_month,
        SAFE_DIVIDE(COUNTIF(is_on_time), NULLIF(COUNT(*), 0))      AS on_time_rate_month,
        COUNTIF(NOT is_on_time)                                    AS cnt_late_orders_month,
        AVG(days_diff_vs_estimate)                                 AS avg_days_diff_vs_estimate_month
    FROM order_dedup
    GROUP BY year_month
),

-- レビュースコア: order_id 単位で重複排除してから平均
review_agg AS (
    SELECT
        year_month,
        SAFE_DIVIDE(
            SUM(review_score),
            NULLIF(COUNT(review_score), 0)
        ) AS avg_review_score_month
    FROM (
        SELECT DISTINCT
            year_month,
            order_id,
            review_score
        FROM base
    )
    GROUP BY year_month
)

SELECT
    d.year_month,
    d.cnt_delivered_orders_month,
    d.avg_delivery_days_month,
    d.p50_delivery_days_month,
    d.on_time_rate_month,
    d.cnt_late_orders_month,
    d.avg_days_diff_vs_estimate_month,
    r.avg_review_score_month
FROM delivery_agg    AS d
LEFT JOIN review_agg AS r USING (year_month)
