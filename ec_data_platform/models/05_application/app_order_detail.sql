{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 注文明細（ドリルダウン）ページ
-- 粒度: 1行 = 1注文明細（order_id × order_item_id）
-- ソース: unf_order_items（03_unification）
-- 05_application の中で唯一 03_unification を参照するテーブル
-- 必要カラムのみを SELECT（全カラム渡し禁止）
-- 各ページからのクロスフィルター（カテゴリ・期間・州・販売者）に対応できるよう全ディメンションを保持

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    customer_unique_id,
    customer_state,
    DATE(order_purchase_timestamp)                               AS order_purchase_date,
    FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp))         AS year_month,
    LEFT(FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)), 4) AS order_year,
    product_category_name_english,
    price,
    freight_value,
    price + freight_value                                        AS sum_revenue,
    main_payment_type,
    review_score,

    -- 配送関連
    DATE_DIFF(
        DATE(order_delivered_customer_date),
        DATE(order_purchase_timestamp),
        DAY
    )                                                            AS delivery_days,
    (
        DATE(order_delivered_customer_date)
        <= DATE(order_estimated_delivery_date)
    )                                                            AS is_on_time,

    -- 顧客属性
    (cnt_orders > 1)                                             AS is_repeat_customer

FROM (
    SELECT
        *,
        COUNT(DISTINCT order_id) OVER (
            PARTITION BY customer_unique_id
        ) AS cnt_orders
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
)
-- geolocation の多対1 JOIN による重複を排除
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY order_id, order_item_id
    ORDER BY order_purchase_timestamp
) = 1
ORDER BY order_purchase_timestamp DESC
