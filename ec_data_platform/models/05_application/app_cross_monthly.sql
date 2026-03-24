-- =============================================================================
-- app_cross_monthly
-- -----------------------------------------------------------------------------
-- 目的    : カテゴリ × 州 × 月 のクロス集計テーブル
-- 粒度    : 1行 = 1カテゴリ × 1州 × 1年月
-- ソース  : unf_order_items（03_unification）
-- 用途    : Streamlit ダッシュボードのユニバーサルスライサー対応
--           ・カテゴリ選択 → 州TOP10・州パイをカテゴリ軸で絞り込み
--           ・州選択 → カテゴリTOP10・カテゴリパイを州軸で絞り込み
--           ・両方選択 → 全ウィジェットをクロスで絞り込み
-- =============================================================================

WITH

base AS (
    SELECT
        product_category_name_english,
        customer_state,
        DATE_TRUNC(order_purchase_timestamp, MONTH) AS order_month,
        order_id,
        customer_unique_id,
        price + freight_value                       AS revenue
    FROM {{ ref('unf_order_items') }}
    WHERE order_status                   = 'delivered'
      AND product_category_name_english IS NOT NULL
      AND customer_state                IS NOT NULL
),

-- 州コード → 州名（英語）マッピング
-- app_geo_summary と同一の STRUCT UNNEST を使用（全フィールドに明示エイリアス）
state_names AS (
    SELECT state_code, state_name_en
    FROM UNNEST([
        STRUCT('AC' AS state_code, 'Acre'                  AS state_name_en),
        STRUCT('AL' AS state_code, 'Alagoas'               AS state_name_en),
        STRUCT('AP' AS state_code, 'Amapá'                 AS state_name_en),
        STRUCT('AM' AS state_code, 'Amazonas'              AS state_name_en),
        STRUCT('BA' AS state_code, 'Bahia'                 AS state_name_en),
        STRUCT('CE' AS state_code, 'Ceará'                 AS state_name_en),
        STRUCT('DF' AS state_code, 'Distrito Federal'      AS state_name_en),
        STRUCT('ES' AS state_code, 'Espírito Santo'        AS state_name_en),
        STRUCT('GO' AS state_code, 'Goiás'                 AS state_name_en),
        STRUCT('MA' AS state_code, 'Maranhão'              AS state_name_en),
        STRUCT('MT' AS state_code, 'Mato Grosso'           AS state_name_en),
        STRUCT('MS' AS state_code, 'Mato Grosso do Sul'    AS state_name_en),
        STRUCT('MG' AS state_code, 'Minas Gerais'          AS state_name_en),
        STRUCT('PA' AS state_code, 'Pará'                  AS state_name_en),
        STRUCT('PB' AS state_code, 'Paraíba'               AS state_name_en),
        STRUCT('PR' AS state_code, 'Paraná'                AS state_name_en),
        STRUCT('PE' AS state_code, 'Pernambuco'            AS state_name_en),
        STRUCT('PI' AS state_code, 'Piauí'                 AS state_name_en),
        STRUCT('RJ' AS state_code, 'Rio de Janeiro'        AS state_name_en),
        STRUCT('RN' AS state_code, 'Rio Grande do Norte'   AS state_name_en),
        STRUCT('RS' AS state_code, 'Rio Grande do Sul'     AS state_name_en),
        STRUCT('RO' AS state_code, 'Rondônia'              AS state_name_en),
        STRUCT('RR' AS state_code, 'Roraima'               AS state_name_en),
        STRUCT('SC' AS state_code, 'Santa Catarina'        AS state_name_en),
        STRUCT('SP' AS state_code, 'São Paulo'             AS state_name_en),
        STRUCT('SE' AS state_code, 'Sergipe'               AS state_name_en),
        STRUCT('TO' AS state_code, 'Tocantins'             AS state_name_en)
    ])
),

monthly_agg AS (
    SELECT
        product_category_name_english,
        customer_state,
        order_month,
        SUM(revenue)                        AS sum_price_month,
        COUNT(DISTINCT order_id)            AS cnt_orders_month,
        COUNT(DISTINCT customer_unique_id)  AS cnt_unique_customers_month
    FROM base
    GROUP BY 1, 2, 3
)

SELECT
    m.product_category_name_english,
    m.customer_state,
    s.state_name_en,
    FORMAT_DATE('%Y-%m', m.order_month)     AS year_month,
    m.order_month,
    m.sum_price_month,
    m.cnt_orders_month,
    m.cnt_unique_customers_month
FROM monthly_agg m
LEFT JOIN state_names s
    ON m.customer_state = s.state_code
ORDER BY m.product_category_name_english, m.customer_state, m.order_month
