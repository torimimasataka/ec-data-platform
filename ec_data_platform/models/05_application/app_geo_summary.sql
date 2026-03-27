{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 地域分析ページ
-- 粒度: 1行 = 1州 × 1年月
-- ソース: t_state_monthly
-- Looker Studio のジオマップ用に ISO 形式の州コード（BR-SP 等）を付与
-- 州名（英語）マッピングを BigQuery 側で付与

WITH state_name_map AS (
    SELECT * FROM UNNEST([
        STRUCT('AC' AS state_code, 'Acre'                  AS state_name_en),
        STRUCT('AL',               'Alagoas'),
        STRUCT('AP',               'Amapá'),
        STRUCT('AM',               'Amazonas'),
        STRUCT('BA',               'Bahia'),
        STRUCT('CE',               'Ceará'),
        STRUCT('DF',               'Distrito Federal'),
        STRUCT('ES',               'Espírito Santo'),
        STRUCT('GO',               'Goiás'),
        STRUCT('MA',               'Maranhão'),
        STRUCT('MT',               'Mato Grosso'),
        STRUCT('MS',               'Mato Grosso do Sul'),
        STRUCT('MG',               'Minas Gerais'),
        STRUCT('PA',               'Pará'),
        STRUCT('PB',               'Paraíba'),
        STRUCT('PR',               'Paraná'),
        STRUCT('PE',               'Pernambuco'),
        STRUCT('PI',               'Piauí'),
        STRUCT('RJ',               'Rio de Janeiro'),
        STRUCT('RN',               'Rio Grande do Norte'),
        STRUCT('RS',               'Rio Grande do Sul'),
        STRUCT('RO',               'Rondônia'),
        STRUCT('RR',               'Roraima'),
        STRUCT('SC',               'Santa Catarina'),
        STRUCT('SP',               'São Paulo'),
        STRUCT('SE',               'Sergipe'),
        STRUCT('TO',               'Tocantins')
    ])
)

SELECT
    s.customer_state,
    CONCAT('BR-', s.customer_state) AS state_code_iso,
    n.state_name_en,
    s.year_month,
    PARSE_DATE('%Y-%m', s.year_month) AS order_month,
    LEFT(s.year_month, 4)             AS order_year,
    s.sum_price_month,
    s.sum_freight_month,
    s.cnt_orders_month,
    s.cnt_unique_customers_month,
    s.avg_review_score_month,
    s.rate_price_in_all_month,

    RANK() OVER (
        PARTITION BY s.year_month
        ORDER BY s.sum_price_month DESC
    ) AS rank_revenue_month

FROM {{ ref('t_state_monthly') }} AS s
LEFT JOIN state_name_map AS n
    ON s.customer_state = n.state_code
ORDER BY s.year_month, rank_revenue_month
