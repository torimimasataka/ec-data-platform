# テーブル定義書：unf_order_items

| 項目 | 値 |
|---|---|
| **論理名** | 統合トランザクション |
| **物理名** | `ec-data-platform-2026.03_unification.unf_order_items` |
| **参照元** | `prep_order_items`（ベース）+ 全 `prep_*` マスタ |
| **粒度** | 1行 = 1注文×1商品明細（order_id + order_item_id が複合PK） |
| **行数** | 112,650件（prep_order_items と同数） |
| **層** | 03_unification（統合済み） |
| **更新方法** | `dbt run --select unf_order_items`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `order_id` | STRING | REQUIRED | 注文ID（複合PK①） |
| `order_item_id` | INTEGER | REQUIRED | 注文明細連番（複合PK②） |
| `product_id` | STRING | REQUIRED | 商品ID |
| `seller_id` | STRING | REQUIRED | 販売者ID |
| `customer_id` | STRING | REQUIRED | 顧客ID |
| `order_status` | STRING | NULLABLE | 注文ステータス |
| `order_purchase_timestamp` | TIMESTAMP | NULLABLE | 注文日時 |
| `order_approved_at` | TIMESTAMP | NULLABLE | 承認日時 |
| `order_delivered_carrier_date` | TIMESTAMP | NULLABLE | 配送業者引き渡し日時 |
| `order_delivered_customer_date` | TIMESTAMP | NULLABLE | 顧客着荷日時 |
| `order_estimated_delivery_date` | TIMESTAMP | NULLABLE | 配達予定日 |
| `price` | FLOAT64 | NULLABLE | 商品単価（BRL） |
| `freight_value` | FLOAT64 | NULLABLE | 送料（BRL） |
| `shipping_limit_date` | TIMESTAMP | NULLABLE | 発送期限 |
| `sum_payment_value` | FLOAT64 | NULLABLE | 注文合計支払金額（注文単位集約） |
| `main_payment_type` | STRING | NULLABLE | 代表支払方法（支払金額最大） |
| `max_payment_installments` | INTEGER | NULLABLE | 最大分割払い回数 |
| `customer_unique_id` | STRING | NULLABLE | 顧客ユニークID（リピート判定用） |
| `customer_zip_code_prefix` | STRING | NULLABLE | 顧客郵便番号 |
| `customer_city` | STRING | NULLABLE | 顧客都市名 |
| `customer_state` | STRING | NULLABLE | 顧客州コード |
| `customer_lat` | FLOAT64 | NULLABLE | 顧客緯度 |
| `customer_lng` | FLOAT64 | NULLABLE | 顧客経度 |
| `product_category_name` | STRING | NULLABLE | 商品カテゴリ（ポルトガル語） |
| `product_category_name_english` | STRING | NULLABLE | 商品カテゴリ（英語） |
| `product_weight_g` | FLOAT64 | NULLABLE | 商品重量（g） |
| `product_length_cm` | FLOAT64 | NULLABLE | 梱包長さ（cm） |
| `product_height_cm` | FLOAT64 | NULLABLE | 梱包高さ（cm） |
| `product_width_cm` | FLOAT64 | NULLABLE | 梱包幅（cm） |
| `seller_zip_code_prefix` | STRING | NULLABLE | 販売者郵便番号 |
| `seller_city` | STRING | NULLABLE | 販売者都市名 |
| `seller_state` | STRING | NULLABLE | 販売者州コード |
| `seller_lat` | FLOAT64 | NULLABLE | 販売者緯度 |
| `seller_lng` | FLOAT64 | NULLABLE | 販売者経度 |
| `review_score` | INTEGER | NULLABLE | レビュースコア（1〜5・NULLはレビューなし） |
| `review_creation_date` | TIMESTAMP | NULLABLE | レビュー作成日時 |

---

## 特記事項

| # | 内容 | 対応 |
|---|---|---|
| 1 | `prep_geolocation` を顧客・販売者の2回 JOIN | エイリアス `geo_c` / `geo_s` で区別 |
| 2 | `prep_order_payments` は注文単位で集約してから JOIN | CTE `payments` で `SUM(payment_value)` / `MAX(installments)` / `main_payment_type`（金額最大の支払方法）を算出 |
| 3 | `review_score` の NULL は「レビューなし注文」（768件） | LEFT JOIN のため正常NULL |
| 4 | `product_category_name_english` の NULL は「翻訳マスタ未登録カテゴリ」（2種） | LEFT JOIN のため正常NULL |

---

## テーブル間リレーション

```
unf_order_items ← prep_order_items（ベース）
              ← prep_orders
              ← prep_customers
              ← prep_products
              ← prep_product_category_name_translation
              ← prep_sellers
              ← prep_geolocation（顧客・販売者の2回）
              ← prep_order_payments（注文単位集約）
              ← prep_order_reviews
```
