{{
    config(
        materialized='table'
    )
}}

-- 粒度: 1行 = 1顧客(customer_unique_id) × 1カテゴリ(product_category_name_english)（全期間）
-- 対象: order_status = 'delivered'
-- 目的: 顧客がどのカテゴリをどれだけ買ったかを横断的に把握する
--       クロスセル分析・カテゴリアフィニティ・購入組み合わせ分析の基礎テーブル
-- 参考: DATA_MART_DESIGN.md 型② 二次属性拡張型

WITH base AS (
    SELECT
        customer_unique_id,
        order_id,
        price,
        order_purchase_timestamp,
        product_category_name_english
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
      AND product_category_name_english IS NOT NULL
),

-- 顧客×カテゴリ別集計
cat_agg AS (
    SELECT
        customer_unique_id,
        product_category_name_english,
        SUM(price)               AS sum_price_cat_all,
        COUNT(DISTINCT order_id) AS cnt_orders_cat_all,
        COUNT(*)                 AS cnt_order_items_cat_all,
        MIN(order_purchase_timestamp) AS first_purchase_ts_cat_all,
        MAX(order_purchase_timestamp) AS latest_purchase_ts_cat_all
    FROM base
    GROUP BY customer_unique_id, product_category_name_english
),

-- 顧客全体の購入金額（シェア計算用）
customer_total AS (
    SELECT
        customer_unique_id,
        SUM(price) AS sum_price_all
    FROM base
    GROUP BY customer_unique_id
)

SELECT
    c.customer_unique_id,
    c.product_category_name_english,
    c.sum_price_cat_all,
    c.cnt_orders_cat_all,
    c.cnt_order_items_cat_all,
    c.first_purchase_ts_cat_all,
    c.latest_purchase_ts_cat_all,
    -- 顧客の全購入に対するカテゴリシェア
    SAFE_DIVIDE(c.sum_price_cat_all, NULLIF(t.sum_price_all, 0)) AS rate_price_cat_in_all,
    -- 主カテゴリ判定: 金額最大のカテゴリを DENSE_RANK + QUALIFY で一意化
    DENSE_RANK() OVER (
        PARTITION BY c.customer_unique_id
        ORDER BY c.sum_price_cat_all DESC, c.product_category_name_english
    ) AS rnk_cat_all,
    -- 1位かつシェア > 50% を主カテゴリとする（ノイズ抑制）
    (
        DENSE_RANK() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY c.sum_price_cat_all DESC, c.product_category_name_english
        ) = 1
        AND SAFE_DIVIDE(c.sum_price_cat_all, NULLIF(t.sum_price_all, 0)) > 0.5
    ) AS is_main_category_all
FROM cat_agg       AS c
LEFT JOIN customer_total AS t USING (customer_unique_id)
