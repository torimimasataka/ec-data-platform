-- =============================================================================
-- app_category_customer_kpi
-- -----------------------------------------------------------------------------
-- 目的    : カテゴリフィルター適用時のダッシュボード KPI カード（顧客指標）
-- 粒度    : 1行 = 1カテゴリ × 1年月
-- ソース  : unf_order_items（03_unification）
-- 主要指標: ユニーク顧客数・リピート顧客数・リピート率
--
-- リピート顧客の定義:
--   当月このカテゴリで購入した顧客のうち、同カテゴリで過去月にも購入実績がある顧客
--   ※ app_summary_kpi の repeat_customer_rate_month と同じ考え方をカテゴリ軸へ拡張
-- =============================================================================

WITH

-- 顧客 × カテゴリ × 月 の購入有無（注文レベルで重複排除）
cat_orders AS (
    SELECT
        customer_unique_id,
        product_category_name_english,
        DATE_TRUNC(order_purchase_timestamp, MONTH) AS order_month
    FROM {{ ref('unf_order_items') }}
    WHERE order_status                    = 'delivered'
      AND product_category_name_english  IS NOT NULL
    GROUP BY 1, 2, 3
),

-- 顧客 × カテゴリの初回購入月
first_cat_month AS (
    SELECT
        customer_unique_id,
        product_category_name_english,
        MIN(order_month) AS first_purchase_month
    FROM cat_orders
    GROUP BY 1, 2
),

-- カテゴリ × 月 の集計
monthly_agg AS (
    SELECT
        c.product_category_name_english,
        c.order_month,
        COUNT(DISTINCT c.customer_unique_id)                                AS cnt_unique_customers_month,
        -- 初回購入月 < 当月 → リピーター
        COUNTIF(f.first_purchase_month < c.order_month)                    AS cnt_repeat_customers_month
    FROM cat_orders c
    LEFT JOIN first_cat_month f
        ON  c.customer_unique_id            = f.customer_unique_id
        AND c.product_category_name_english = f.product_category_name_english
    GROUP BY 1, 2
)

SELECT
    product_category_name_english,
    FORMAT_DATE('%Y-%m', order_month)                                       AS year_month,
    order_month,
    cnt_unique_customers_month,
    cnt_repeat_customers_month,
    SAFE_DIVIDE(
        cnt_repeat_customers_month,
        cnt_unique_customers_month
    )                                                                       AS repeat_customer_rate_month
FROM monthly_agg
ORDER BY product_category_name_english, order_month
