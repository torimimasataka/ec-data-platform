-- =============================================================================
-- app_state_customer_kpi
-- -----------------------------------------------------------------------------
-- 目的    : 州フィルター適用時のダッシュボード KPI カード（顧客指標）
-- 粒度    : 1行 = 1州 × 1年月
-- ソース  : unf_order_items（03_unification）
-- 主要指標: ユニーク顧客数・リピート顧客数・リピート率
--
-- リピート顧客の定義:
--   当月この州の顧客のうち、全体で初回購入月 < 当月 の顧客（州を問わず）
--   ブラジルECでは顧客住所変更はほぼないため州ベースのリピート判定と等価
-- =============================================================================

WITH

-- 顧客 × 州 × 月 の購入有無（注文レベルで重複排除）
state_orders AS (
    SELECT
        customer_unique_id,
        customer_state,
        DATE_TRUNC(order_purchase_timestamp, MONTH) AS order_month
    FROM {{ ref('unf_order_items') }}
    WHERE order_status  = 'delivered'
      AND customer_state IS NOT NULL
    GROUP BY 1, 2, 3
),

-- 顧客の全体初回購入月（州を問わず）
first_order_month AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS first_purchase_month
    FROM state_orders
    GROUP BY 1
),

-- 州 × 月 の集計
monthly_agg AS (
    SELECT
        s.customer_state,
        s.order_month,
        COUNT(DISTINCT s.customer_unique_id)                                AS cnt_unique_customers_month,
        -- 全体初回購入月 < 当月 → リピーター
        COUNTIF(f.first_purchase_month < s.order_month)                    AS cnt_repeat_customers_month
    FROM state_orders s
    LEFT JOIN first_order_month f
        ON s.customer_unique_id = f.customer_unique_id
    GROUP BY 1, 2
)

SELECT
    customer_state,
    FORMAT_DATE('%Y-%m', order_month)                                       AS year_month,
    order_month,
    cnt_unique_customers_month,
    cnt_repeat_customers_month,
    SAFE_DIVIDE(
        cnt_repeat_customers_month,
        cnt_unique_customers_month
    )                                                                       AS repeat_customer_rate_month
FROM monthly_agg
ORDER BY customer_state, order_month
