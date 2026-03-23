# テーブル定義書：src_customers

| 項目 | 値 |
|---|---|
| **論理名** | 顧客情報 |
| **物理名** | `ec-data-platform-2026.01_import.src_customers` |
| **ソースファイル** | `olist_customers_dataset.csv` |
| **粒度** | 1行 = 1注文に対する1顧客レコード（customer_idは注文ごとに発行） |
| **行数** | 99,441件 |
| **層** | 01_import（ローデータ） |
| **更新方法** | `bq load --replace`（全件洗い替え） |
| **最終更新日** | 2026-03-21 |

---

## カラム定義

| カラム名 | BQ型 | モード | ユニーク数 | NULL数 | NULL率 | 説明 |
|---|---|---|---|---|---|---|
| `customer_id` | STRING | REQUIRED | 99,441 | 0 | 0.0% | 顧客ID（PK・注文ごとに発行される仮想ID） |
| `customer_unique_id` | STRING | NULLABLE | 96,096 | 0 | 0.0% | 実質的な顧客ID（リピート判定に使用） |
| `customer_zip_code_prefix` | STRING | NULLABLE | 14,994 | 0 | 0.0% | 郵便番号（5桁・STRING型でゼロ落ち防止） |
| `customer_city` | STRING | NULLABLE | 4,119 | 0 | 0.0% | 都市名（小文字・表記揺れあり） |
| `customer_state` | STRING | NULLABLE | 27 | 0 | 0.0% | 州コード（2文字） |

---

## ⚠️ customer_id の設計上の注意

このテーブルの `customer_id` は**注文ごとに発行される仮想ID**であり、同一顧客が複数回購入しても毎回異なるIDが付与される。

- **リピーター判定には `customer_unique_id` を使用すること**
- `customer_id`（99,441種）> `customer_unique_id`（96,096種）→ **3,345件のリピート顧客**が存在

---

## customer_state 上位5州

| 州コード | 州名 | 顧客数 | 割合 |
|---|---|---|---|
| SP | サンパウロ | 41,746 | 42.0% |
| RJ | リオデジャネイロ | 12,852 | 12.9% |
| MG | ミナスジェライス | 11,635 | 11.7% |
| RS | リオグランデドスル | 5,466 | 5.5% |
| PR | パラナ | 5,045 | 5.1% |

---

## 特記事項・クレンジング方針

| # | 対象カラム | 内容 | 方針 |
|---|---|---|---|
| 1 | `customer_city` | 表記揺れ（小文字・アクセント記号の不統一） | 02_preprocess で正規化 |
| 2 | `customer_zip_code_prefix` | 5桁の郵便番号プレフィックス | STRINGのまま保持。`geolocation` との結合キーに使用 |

---

## テーブル間リレーション

```
src_customers.customer_id          ← src_orders.customer_id              （1:1）
src_customers.customer_zip_code_prefix → src_geolocation.geolocation_zip_code_prefix（多:多）
```
