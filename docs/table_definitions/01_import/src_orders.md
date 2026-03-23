# テーブル定義書：src_orders

| 項目 | 値 |
|---|---|
| **論理名** | 注文ヘッダー |
| **物理名** | `ec-data-platform-2026.01_import.src_orders` |
| **ソースファイル** | `olist_orders_dataset.csv` |
| **粒度** | 1行 = 1注文 |
| **行数** | 99,441件 |
| **層** | 01_import（ローデータ） |
| **更新方法** | `bq load --replace`（全件洗い替え） |
| **最終更新日** | 2026-03-21 |

---

## カラム定義

| カラム名 | BQ型 | モード | ユニーク数 | NULL数 | NULL率 | 説明 |
|---|---|---|---|---|---|---|
| `order_id` | STRING | REQUIRED | 99,441 | 0 | 0.0% | 注文ID（PK） |
| `customer_id` | STRING | REQUIRED | 99,441 | 0 | 0.0% | 顧客ID（FK → customers） |
| `order_status` | STRING | NULLABLE | 8 | 0 | 0.0% | 注文ステータス（下記参照） |
| `order_purchase_timestamp` | TIMESTAMP | NULLABLE | 98,875 | 0 | 0.0% | 注文日時 |
| `order_approved_at` | TIMESTAMP | NULLABLE | 90,733 | 160 | 0.2% | 承認日時（未承認はNULL） |
| `order_delivered_carrier_date` | TIMESTAMP | NULLABLE | 81,018 | 1,783 | 1.8% | 配送業者引き渡し日時（未配送はNULL） |
| `order_delivered_customer_date` | TIMESTAMP | NULLABLE | 95,664 | 2,965 | 3.0% | 顧客着荷日時（未着はNULL） |
| `order_estimated_delivery_date` | TIMESTAMP | NULLABLE | 459 | 0 | 0.0% | 配達予定日 |

---

## order_status 値一覧

| ステータス | 件数 | 割合 | 説明 |
|---|---|---|---|
| `delivered` | 96,478 | 97.0% | 配達完了 |
| `shipped` | 1,107 | 1.1% | 発送済み |
| `canceled` | 625 | 0.6% | キャンセル |
| `unavailable` | 609 | 0.6% | 取扱不可 |
| `invoiced` | 314 | 0.3% | 請求済み |
| `processing` | 301 | 0.3% | 処理中 |
| `created` | 5 | 0.0% | 作成済み |
| `approved` | 2 | 0.0% | 承認済み |

---

## 特記事項・クレンジング方針

| # | 対象カラム | 内容 | 方針 |
|---|---|---|---|
| 1 | `order_delivered_carrier_date` | 未配送注文のNULL（1,783件） | **保持**（業務上の正常NULL） |
| 2 | `order_delivered_customer_date` | 未着注文のNULL（2,965件） | **保持**（業務上の正常NULL） |
| 3 | `order_approved_at` | 160件のNULL | `created` / `canceled` / `unavailable` に起因 → 保持 |

---

## テーブル間リレーション

```
src_orders.customer_id  → src_customers.customer_id  （多:1）
src_orders.order_id     ← src_order_items.order_id   （1:多）
src_orders.order_id     ← src_order_reviews.order_id （1:多）
src_orders.order_id     ← src_order_payments.order_id（1:多）
```
