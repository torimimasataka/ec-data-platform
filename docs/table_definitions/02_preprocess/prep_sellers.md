# テーブル定義書：prep_sellers

| 項目 | 値 |
|---|---|
| **論理名** | 販売者マスタ |
| **物理名** | `ec-data-platform-2026.02_preprocess.prep_sellers` |
| **ソースファイル** | `olist_sellers_dataset.csv` |
| **粒度** | 1行 = 1販売者（seller_id が PK） |
| **行数** | 3,095件 |
| **層** | 02_preprocess（クレンジング済み） |
| **更新方法** | `bq load --replace`（全件洗い替え） |
| **最終更新日** | 2026-03-21 |

---

## カラム定義

| カラム名 | BQ型 | モード | ユニーク数 | NULL数 | NULL率 | 説明 |
|---|---|---|---|---|---|---|
| `seller_id` | STRING | REQUIRED | 3,095 | 0 | 0.0% | 販売者ID（PK） |
| `seller_zip_code_prefix` | STRING | NULLABLE | 2,246 | 0 | 0.0% | 郵便番号（5桁・STRING型でゼロ落ち防止） |
| `seller_city` | STRING | NULLABLE | 611 | 0 | 0.0% | 都市名（表記揺れあり） |
| `seller_state` | STRING | NULLABLE | 23 | 0 | 0.0% | 州コード（2文字） |

---

## 特記事項・クレンジング方針

| # | 対象カラム | 内容 | 方針 |
|---|---|---|---|
| 1 | `seller_city` | 小文字・表記揺れあり | 02_preprocess で正規化 |
| 2 | `seller_zip_code_prefix` | 5桁郵便番号プレフィックス | STRINGのまま保持。`geolocation` との結合キーに使用 |
| 3 | 全カラム | NULL件数 0（欠損なし） | クレンジング不要 |

---

## テーブル間リレーション

```
prep_sellers.seller_id              ← prep_order_items.seller_id                        （1:多）
prep_sellers.seller_zip_code_prefix → prep_geolocation.geolocation_zip_code_prefix（多:多）
```
