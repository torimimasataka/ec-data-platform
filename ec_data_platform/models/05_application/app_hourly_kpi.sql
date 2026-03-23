{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 時間帯・曜日分析ページ
-- 粒度: 1行 = 1時間帯(0〜23) × 1曜日(1〜7)
-- ソース: unf_order_items（03_unification）
-- 全期間を集計したヒートマップ用テーブル（時系列ではなくパターン分析）
-- BigQuery の EXTRACT(DAYOFWEEK) は 1=日曜 〜 7=土曜

WITH base AS (
    SELECT
        EXTRACT(HOUR FROM order_purchase_timestamp)       AS hour_of_day,
        EXTRACT(DAYOFWEEK FROM order_purchase_timestamp)  AS day_of_week_num,
        FORMAT_TIMESTAMP('%A', order_purchase_timestamp)  AS day_of_week_name,
        order_id,
        price
    FROM {{ ref('unf_order_items') }}
    WHERE order_status = 'delivered'
),

agg AS (
    SELECT
        hour_of_day,
        day_of_week_num,
        ANY_VALUE(day_of_week_name) AS day_of_week_name,
        COUNT(DISTINCT order_id)    AS cnt_orders,
        SUM(price)                  AS sum_revenue
    FROM base
    GROUP BY hour_of_day, day_of_week_num
)

SELECT
    hour_of_day,
    day_of_week_num,
    day_of_week_name,
    cnt_orders,
    sum_revenue,
    SAFE_DIVIDE(sum_revenue, NULLIF(cnt_orders, 0)) AS aov,

    -- ヒートマップの強度用: 全セルの中での相対順位（0〜1）
    SAFE_DIVIDE(
        cnt_orders - MIN(cnt_orders) OVER (),
        NULLIF(MAX(cnt_orders) OVER () - MIN(cnt_orders) OVER (), 0)
    ) AS cnt_orders_normalized,

    SAFE_DIVIDE(
        sum_revenue - MIN(sum_revenue) OVER (),
        NULLIF(MAX(sum_revenue) OVER () - MIN(sum_revenue) OVER (), 0)
    ) AS sum_revenue_normalized

FROM agg
ORDER BY day_of_week_num, hour_of_day
