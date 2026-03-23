# テーブル定義書：t_customer_monthly

| 項目 | 値 |
|---|---|
| **論理名** | 顧客月次集計 |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_customer_monthly` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1顧客(customer_unique_id) × 1年月(year_month) |
| **対象** | order_status = 'delivered'（配送完了済み注文のみ） |
| **行数** | 95,200件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_customer_monthly`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

顧客ごとの月次購入行動を集計した中間テーブル。月次RFMの基礎値・主カテゴリ・アクティブフラグを確定させ、下流の `05_application` でのセグメント分析・Looker Studio 時系列ダッシュボードの入力として使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `customer_unique_id` | STRING | REQUIRED | 顧客ユニークID（複合PK①） |
| `year_month` | STRING | REQUIRED | 年月（YYYY-MM形式）（複合PK②） |
| `sum_price_month` | FLOAT64 | NULLABLE | 月内商品金額合計（BRL） |
| `sum_freight_month` | FLOAT64 | NULLABLE | 月内送料合計（BRL） |
| `cnt_orders_month` | INTEGER | NULLABLE | 月内注文件数（DISTINCT order_id） |
| `cnt_order_items_month` | INTEGER | NULLABLE | 月内明細件数 |
| `first_purchase_ts_month` | TIMESTAMP | NULLABLE | 月内初回購入日時 |
| `latest_purchase_ts_month` | TIMESTAMP | NULLABLE | 月内最終購入日時 |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 月内平均レビュースコア（注文単位で重複排除後に平均） |
| `main_category_month` | STRING | NULLABLE | 月内主カテゴリ（金額最大・DENSE_RANK 1位） |
| `is_active_month` | BOOLEAN | NULLABLE | 月内購入あり（sum_price_month > 0） |
| `is_repeat_in_month` | BOOLEAN | NULLABLE | 月内複数注文（cnt_orders_month > 1） |
| `customer_state` | STRING | NULLABLE | 顧客の州コード |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | `sum_payment_value` は注文単位の集約済み値のため、明細粒度で集計すると重複する。金額集計は `price` / `freight_value` を使用 |
| 2 | `avg_review_score_month` は order_id 単位で重複排除してから平均を取る（複数明細がある注文で review_score が重複するため） |
| 3 | `main_category_month` は DENSE_RANK + QUALIFY パターン。タイブレークにカテゴリ名を追加し再計算でも結果が安定 |
