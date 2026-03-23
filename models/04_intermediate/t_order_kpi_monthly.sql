{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1年月(year_month)（ビジネス全体の月次KPI）
-- 対象: order_status = 'delivered'
-- 新規/リピート判定: unf_order_items から直接 MIN(order_purchase_timestamp) を算出

WITH base AS (
    SELECT
        customer_unique_id,
        order_id,
        price,
        review_score,
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

-- 月次基本集計
monthly_agg AS (
    SELECT
        year_month,
        SUM(price)                         AS sum_price_month,
        COUNT(DISTINCT order_id)           AS cnt_orders_month,
        COUNT(*)                           AS cnt_order_items_month,
        COUNT(DISTINCT customer_unique_id) AS cnt_active_customers_month
    FROM base
    GROUP BY year_month
),

-- 顧客×月次の存在フラグ（新規/リピート分類用）
customer_month AS (
    SELECT DISTINCT
        b.customer_unique_id,
        b.year_month,
        f.first_purchase_month
    FROM base AS b
    INNER JOIN customer_first_month AS f USING (customer_unique_id)
),

-- 新規・リピート顧客数の月次集計
new_repeat_agg AS (
    SELECT
        year_month,
        COUNTIF(year_month = first_purchase_month) AS cnt_new_customers_month,
        COUNTIF(year_month != first_purchase_month) AS cnt_repeat_customers_month
    FROM customer_month
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
    m.year_month,
    m.sum_price_month,
    m.cnt_orders_month,
    m.cnt_order_items_month,
    m.cnt_active_customers_month,
    IFNULL(nr.cnt_new_customers_month, 0)    AS cnt_new_customers_month,
    IFNULL(nr.cnt_repeat_customers_month, 0) AS cnt_repeat_customers_month,
    SAFE_DIVIDE(m.sum_price_month, NULLIF(m.cnt_orders_month, 0))           AS aov_month,
    SAFE_DIVIDE(m.sum_price_month, NULLIF(m.cnt_order_items_month, 0))      AS apv_month,
    SAFE_DIVIDE(m.cnt_orders_month, NULLIF(m.cnt_active_customers_month, 0)) AS avg_orders_per_customer_month,
    SAFE_DIVIDE(
        IFNULL(nr.cnt_repeat_customers_month, 0),
        NULLIF(m.cnt_active_customers_month, 0)
    )                                                                         AS repeat_customer_rate_month,
    r.avg_review_score_month
FROM monthly_agg       AS m
LEFT JOIN new_repeat_agg AS nr USING (year_month)
LEFT JOIN review_agg     AS r  USING (year_month)
