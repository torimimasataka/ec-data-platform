{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1顧客(customer_unique_id)（全期間集計）
-- 対象: order_status = 'delivered'（配送完了済み注文のみ）
-- RFM: R=recency_days（データ最終日基準）、F=cnt_orders_all、M=sum_price_all
-- セグメンテーションは 05_application 層で行う

WITH base AS (
    SELECT
        customer_unique_id,
        order_id,
        price,
        order_purchase_timestamp,
        product_category_name_english,
        main_payment_type,
        review_score,
        customer_state
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
),

-- 基本集計（全期間）
customer_agg AS (
    SELECT
        customer_unique_id,
        SUM(price)               AS sum_price_all,
        COUNT(DISTINCT order_id) AS cnt_orders_all,
        COUNT(DISTINCT FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp))) AS cnt_order_months_all,
        COUNT(DISTINCT product_category_name_english) AS cnt_categories_all,
        MIN(order_purchase_timestamp) AS first_purchase_ts_all,
        MAX(order_purchase_timestamp) AS latest_purchase_ts_all,
        ANY_VALUE(customer_state)     AS customer_state
    FROM base
    GROUP BY customer_unique_id
),

-- recency_days の基準日: データ内の最終購入日（実行タイミング非依存で再現性を保つ）
max_date AS (
    SELECT MAX(DATE(order_purchase_timestamp)) AS max_order_date
    FROM {{ ref('unf_order_items') }}
),

-- レビュースコア: order_id 単位で重複排除してから平均
-- （同一注文に複数明細がある場合に review_score が重複するため）
review_agg AS (
    SELECT
        customer_unique_id,
        SAFE_DIVIDE(
            SUM(review_score),
            NULLIF(COUNT(review_score), 0)
        ) AS avg_review_score_all
    FROM (
        SELECT DISTINCT customer_unique_id, order_id, review_score
        FROM base
    )
    GROUP BY customer_unique_id
),

-- カテゴリ別金額集計（主カテゴリ決定用）
cat_agg AS (
    SELECT
        customer_unique_id,
        product_category_name_english,
        SUM(price) AS sum_price_cat
    FROM base
    GROUP BY customer_unique_id, product_category_name_english
),

-- 主カテゴリ: 金額最大のカテゴリを DENSE_RANK + QUALIFY で一意化
-- タイブレーク: カテゴリ名を昇順に入れることで再計算しても結果が安定
main_cat AS (
    SELECT
        customer_unique_id,
        product_category_name_english AS main_category_all
    FROM cat_agg
    QUALIFY
        DENSE_RANK() OVER (
            PARTITION BY customer_unique_id
            ORDER BY sum_price_cat DESC, product_category_name_english
        ) = 1
),

-- 支払方法の件数集計（主支払方法決定用）
-- main_payment_type: unf_order_items 側で注文単位の代表支払方法として確定済み
payment_count AS (
    SELECT
        customer_unique_id,
        main_payment_type,
        COUNT(*) AS cnt_payment_type
    FROM (
        SELECT DISTINCT customer_unique_id, order_id, main_payment_type
        FROM base
    )
    GROUP BY customer_unique_id, main_payment_type
),

-- 主支払方法: 件数最多を DENSE_RANK + QUALIFY で一意化
main_payment AS (
    SELECT
        customer_unique_id,
        main_payment_type AS main_payment_type_all
    FROM payment_count
    QUALIFY
        DENSE_RANK() OVER (
            PARTITION BY customer_unique_id
            ORDER BY cnt_payment_type DESC, main_payment_type
        ) = 1
),

-- カテゴリ一覧: ORDER BY を固定して再計算でも並びが安定
list_cat AS (
    SELECT
        customer_unique_id,
        STRING_AGG(
            DISTINCT product_category_name_english
            ORDER BY product_category_name_english
        ) AS list_categories_all
    FROM base
    WHERE product_category_name_english IS NOT NULL
    GROUP BY customer_unique_id
)

SELECT
    a.customer_unique_id,
    a.sum_price_all,
    a.cnt_orders_all,
    a.cnt_order_months_all,
    a.cnt_categories_all,
    a.first_purchase_ts_all,
    a.latest_purchase_ts_all,
    DATE_DIFF(m.max_order_date, DATE(a.latest_purchase_ts_all), DAY) AS recency_days,
    r.avg_review_score_all,
    c.main_category_all,
    p.main_payment_type_all,
    l.list_categories_all,
    a.customer_state,
    (a.cnt_orders_all > 1)            AS is_repeat_customer,
    (c.main_category_all IS NOT NULL) AS has_main_category_all
FROM customer_agg      AS a
CROSS JOIN max_date    AS m
LEFT JOIN review_agg   AS r USING (customer_unique_id)
LEFT JOIN main_cat     AS c USING (customer_unique_id)
LEFT JOIN main_payment AS p USING (customer_unique_id)
LEFT JOIN list_cat     AS l USING (customer_unique_id)
