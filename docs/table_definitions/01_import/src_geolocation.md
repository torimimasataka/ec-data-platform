# テーブル定義書：src_geolocation

| 項目 | 値 |
|---|---|
| **論理名** | 位置情報（郵便番号×緯度経度） |
| **物理名** | `ec-data-platform-2026.01_import.src_geolocation` |
| **ソースファイル** | `olist_geolocation_dataset.csv` |
| **粒度** | 1行 = 1郵便番号に対する1座標レコード（PKなし・1郵便番号に複数行あり） |
| **行数** | 1,000,163件 |
| **層** | 01_import（ローデータ） |
| **更新方法** | `bq load --replace`（全件洗い替え） |
| **最終更新日** | 2026-03-21 |

---

## カラム定義

| カラム名 | BQ型 | モード | ユニーク数 | NULL数 | NULL率 | 説明 |
|---|---|---|---|---|---|---|
| `geolocation_zip_code_prefix` | STRING | NULLABLE | 19,015 | 0 | 0.0% | 郵便番号プレフィックス（5桁・STRING型でゼロ落ち防止） |
| `geolocation_lat` | FLOAT64 | NULLABLE | 717,372 | 0 | 0.0% | 緯度 |
| `geolocation_lng` | FLOAT64 | NULLABLE | 717,615 | 0 | 0.0% | 経度 |
| `geolocation_city` | STRING | NULLABLE | 8,011 | 0 | 0.0% | 都市名 |
| `geolocation_state` | STRING | NULLABLE | 27 | 0 | 0.0% | 州コード（2文字） |

---

## ⚠️ 重要：このテーブルの使い方

このテーブルは**1郵便番号に複数の座標行が存在する**ため、そのまま結合すると行数が爆発する。

| ユニーク郵便番号数 | 総行数 | 1郵便番号あたり平均行数 |
|---|---|---|
| 19,015件 | 1,000,163件 | 約52行 |

**推奨する利用方法：** 02_preprocess で郵便番号ごとに代表座標を集約してから結合する。

```sql
-- 02_preprocess での集約例
SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat)  AS lat,
    AVG(geolocation_lng)  AS lng,
    MAX(geolocation_state) AS state
FROM {{ source('olist_raw', 'geolocation') }}
GROUP BY geolocation_zip_code_prefix
```

---

## 特記事項・クレンジング方針

| # | 内容 | 方針 |
|---|---|---|
| 1 | PKなし・1郵便番号に複数座標 | 02_preprocess で `AVG(lat)` / `AVG(lng)` に集約 |
| 2 | NULL件数 0（欠損なし） | クレンジング不要 |

---

## テーブル間リレーション

```
src_geolocation.geolocation_zip_code_prefix ← src_customers.customer_zip_code_prefix（多:多）
src_geolocation.geolocation_zip_code_prefix ← src_sellers.seller_zip_code_prefix    （多:多）
※ 結合前に郵便番号単位で集約すること
```
