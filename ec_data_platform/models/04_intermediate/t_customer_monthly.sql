{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1顧客(customer_unique_id) × 1年月(year_month)
-- 対象: order_status = 'delivered'（配送完了済み注文のみ）
-- 金額: price + freight_value（sum_payment_value は注文単位集約済みのため order_item 粒度では重複するため不使用）

WITH base AS (
    SELECT
        customer_unique_id,
        FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month,
        order_id,
        price,
        freight_value,
        order_purchase_timestamp,
        product_category_name_english,
        review_score,
        customer_state
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
),

-- カテゴリ別金額集計（主カテゴリ決定用）
cat_agg AS (
    SELECT
        customer_unique_id,
        year_month,
        product_category_name_english,
        SUM(price) AS sum_price_cat_month
    FROM base
    GROUP BY
        customer_unique_id,
        year_month,
        product_category_name_english
),

-- 主カテゴリ: 金額最大のカテゴリを DENSE_RANK + QUALIFY で一意化
-- タイブレーク: カテゴリ名を昇順に入れることで再計算しても結果が安定
main_cat AS (
    SELECT
        customer_unique_id,
        year_month,
        product_category_name_english AS main_category_month
    FROM cat_agg
    QUALIFY
        DENSE_RANK() OVER (
            PARTITION BY customer_unique_id, year_month
            ORDER BY sum_price_cat_month DESC, product_category_name_english
        ) = 1
),

-- レビュースコア: order_id 単位で重複排除してから平均
-- （同一注文に複数明細がある場合に review_score が重複するため）
review_agg AS (
    SELECT
        customer_unique_id,
        year_month,
        SAFE_DIVIDE(
            SUM(review_score),
            NULLIF(COUNT(review_score), 0)
        ) AS avg_review_score_month
    FROM (
        SELECT DISTINCT
            customer_unique_id,
            year_month,
            order_id,
            review_score
        FROM base
    )
    GROUP BY
        customer_unique_id,
        year_month
),

-- 基本集計
monthly_agg AS (
    SELECT
        customer_unique_id,
        year_month,
        SUM(price)                AS sum_price_month,
        SUM(freight_value)        AS sum_freight_month,
        COUNT(DISTINCT order_id)  AS cnt_orders_month,
        COUNT(*)                  AS cnt_order_items_month,
        MIN(order_purchase_timestamp) AS first_purchase_ts_month,
        MAX(order_purchase_timestamp) AS latest_purchase_ts_month,
        ANY_VALUE(customer_state)     AS customer_state
    FROM base
    GROUP BY
        customer_unique_id,
        year_month
)

SELECT
    m.customer_unique_id,
    m.year_month,
    m.sum_price_month,
    m.sum_freight_month,
    m.cnt_orders_month,
    m.cnt_order_items_month,
    m.first_purchase_ts_month,
    m.latest_purchase_ts_month,
    r.avg_review_score_month,
    c.main_category_month,
    (m.sum_price_month > 0)   AS is_active_month,
    (m.cnt_orders_month > 1)  AS is_repeat_in_month,
    m.customer_state
FROM monthly_agg       AS m
LEFT JOIN review_agg   AS r USING (customer_unique_id, year_month)
LEFT JOIN main_cat     AS c USING (customer_unique_id, year_month)
