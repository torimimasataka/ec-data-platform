{{
    config(
        materialized='table'
    )
}}

-- 同一郵便番号に複数の座標が存在するため、AVG で集約して1件に絞り込む
WITH source AS (
    SELECT
        CAST(geolocation_zip_code_prefix AS STRING)  AS geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        TRIM(LOWER(geolocation_city))                AS geolocation_city,
        UPPER(TRIM(geolocation_state))               AS geolocation_state
    FROM {{ ref('src_geolocation') }}
)

SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat)   AS geolocation_lat,
    AVG(geolocation_lng)   AS geolocation_lng,
    MAX(geolocation_city)  AS geolocation_city,
    MAX(geolocation_state) AS geolocation_state
FROM source
GROUP BY
    geolocation_zip_code_prefix
