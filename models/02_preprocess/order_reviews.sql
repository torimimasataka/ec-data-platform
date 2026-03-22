{{
    config(
        materialized='table'
    )
}}

-- review_id の重複 約814件を排除
-- 同一 review_id のうち review_answer_timestamp が最新のレコードを1件残す
SELECT
    review_id,
    order_id,
    SAFE_CAST(review_score AS INT64)                    AS review_score,
    review_comment_title,
    review_comment_message,
    SAFE_CAST(review_creation_date AS TIMESTAMP)        AS review_creation_date,
    SAFE_CAST(review_answer_timestamp AS TIMESTAMP)     AS review_answer_timestamp
FROM {{ source('olist_raw', 'order_reviews') }}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY review_id
    ORDER BY review_answer_timestamp DESC NULLS LAST
) = 1
