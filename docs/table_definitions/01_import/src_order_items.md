# テーブル定義書：src_order_items

| 項目 | 値 |
|---|---|
| **論理名** | 注文明細 |
| **物理名** | `ec-data-platform-2026.01_import.src_order_items` |
| **ソースファイル** | `olist_order_items_dataset.csv` |
| **粒度** | 1行 = 1注文内の1商品明細（order_id + order_item_id の複合キー） |
| **行数** | 112,650件 |
| **層** | 01_import（ローデータ） |
| **更新方法** | `bq load --replace`（全件洗い替え） |
| **最終更新日** | 2026-03-21 |

---

## カラム定義

| カラム名 | BQ型 | モード | ユニーク数 | NULL数 | NULL率 | 説明 |
|---|---|---|---|---|---|---|
| `order_id` | STRING | REQUIRED | 98,666 | 0 | 0.0% | 注文ID（FK → orders） |
| `order_item_id` | INTEGER | REQUIRED | 21 | 0 | 0.0% | 注文内の商品連番（1始まり、最大21） |
| `product_id` | STRING | NULLABLE | 32,951 | 0 | 0.0% | 商品ID（FK → products） |
| `seller_id` | STRING | NULLABLE | 3,095 | 0 | 0.0% | 販売者ID（FK → sellers） |
| `shipping_limit_date` | TIMESTAMP | NULLABLE | 93,318 | 0 | 0.0% | 発送期限日時 |
| `price` | FLOAT64 | NULLABLE | 5,968 | 0 | 0.0% | 商品単価（BRL） |
| `freight_value` | FLOAT64 | NULLABLE | 6,999 | 0 | 0.0% | 送料（BRL） |

---

## 特記事項・クレンジング方針

| # | 内容 | 方針 |
|---|---|---|
| 1 | orders（99,441件）より行数が多い（112,650件）→ 1注文に複数商品を含む | 正常。order_item_id で商品ごとに明細化 |
| 2 | order_id のユニーク数が 98,666（ordersの99,441より775件少ない）| ordersに明細なし注文が775件存在。LEFT JOINで保持 |
| 3 | `price` + `freight_value` が売上計算の基礎 | 02_preprocess で `sum_price`・`sum_freight` を計算 |

---

## テーブル間リレーション

```
src_order_items.order_id   → src_orders.order_id    （多:1）
src_order_items.product_id → src_products.product_id（多:1）
src_order_items.seller_id  → src_sellers.seller_id  （多:1）
```
