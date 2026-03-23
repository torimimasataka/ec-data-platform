{{
    config(
        materialized='table'
    )
}}

-- ダッシュボード: 顧客分析ページ（RFMセグメント分布）
-- 粒度: 1行 = 1顧客
-- ソース: t_customer_all
-- RFMスコアとセグメントラベルは BigQuery 側で付与（Looker Studio側で計算させない）
-- セグメント定義:
--   R: recency_days（90日以内=4, 180日以内=3, 365日以内=2, それ以上=1）
--   F: cnt_orders_all（5件以上=4, 3件以上=3, 2件=2, 1件=1）
--   M: sum_price_all（1000以上=4, 400以上=3, 150以上=2, それ以下=1）

WITH scored AS (
    SELECT
        customer_unique_id,
        sum_price_all,
        cnt_orders_all,
        recency_days,
        DATE(first_purchase_ts_all)  AS first_purchase_date,
        DATE(latest_purchase_ts_all) AS latest_purchase_date,
        main_category_all,
        main_payment_type_all,
        customer_state,
        is_repeat_customer,
        avg_review_score_all,

        -- R スコア（小さいほど最近購入）
        CASE
            WHEN recency_days <= 90  THEN 4
            WHEN recency_days <= 180 THEN 3
            WHEN recency_days <= 365 THEN 2
            ELSE 1
        END AS r_score,

        -- F スコア（多いほど高頻度）
        CASE
            WHEN cnt_orders_all >= 5 THEN 4
            WHEN cnt_orders_all >= 3 THEN 3
            WHEN cnt_orders_all >= 2 THEN 2
            ELSE 1
        END AS f_score,

        -- M スコア（高いほど高額）
        CASE
            WHEN sum_price_all >= 1000 THEN 4
            WHEN sum_price_all >= 400  THEN 3
            WHEN sum_price_all >= 150  THEN 2
            ELSE 1
        END AS m_score

    FROM {{ ref('t_customer_all') }}
)

SELECT
    customer_unique_id,
    sum_price_all,
    cnt_orders_all,
    recency_days,
    first_purchase_date,
    latest_purchase_date,
    main_category_all,
    main_payment_type_all,
    customer_state,
    is_repeat_customer,
    avg_review_score_all,
    r_score,
    f_score,
    m_score,
    r_score + f_score + m_score AS rfm_total_score,

    -- セグメントラベル
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 2                  THEN 'Loyal'
        WHEN r_score >= 3 AND f_score = 1                   THEN 'Promising'
        WHEN r_score = 2  AND f_score >= 2                  THEN 'Need Attention'
        WHEN r_score = 2  AND f_score = 1                   THEN 'At Risk'
        WHEN r_score = 1  AND f_score >= 2                  THEN 'Cannot Lose'
        ELSE 'Hibernating'
    END AS rfm_segment

FROM scored
