# テーブル定義書：app_order_detail

| 項目 | 値 |
|---|---|
| **論理名** | 注文明細ドリルダウン |
| **物理名** | `ec-data-platform-2026.05_application.app_order_detail` |
| **参照元** | `unf_order_items`（03_unification） |
| **粒度** | 1行 = 1注文明細（order_id × order_item_id） |
| **行数** | 110,197件 |
| **層** | 05_application（Streamlit Page 8 向け） |
| **更新方法** | `dbt run --select app_order_detail` |
| **最終更新日** | 2026-03-27 |

### 概要

個別注文の明細レベルデータ。Page 8（注文明細ドリルダウン）で注文を検索・絞り込み・詳細確認するためのデータソース。全明細を持つため最も行数が多いテーブル。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `order_id` | STRING | NULLABLE | 注文ID |
| `order_item_id` | INTEGER | NULLABLE | 明細番号（同一注文内の連番） |
| `product_id` | STRING | NULLABLE | 商品ID |
| `seller_id` | STRING | NULLABLE | 販売者ID |
| `customer_unique_id` | STRING | NULLABLE | 顧客ID（匿名化済み） |
| `customer_state` | STRING | NULLABLE | 顧客の州コード |
| `order_purchase_date` | DATE | NULLABLE | 注文日 |
| `year_month` | STRING | NULLABLE | 年月（YYYY-MM） |
| `order_year` | STRING | NULLABLE | 年 |
| `product_category_name_english` | STRING | NULLABLE | カテゴリ名（英語） |
| `price` | FLOAT64 | NULLABLE | 商品価格（BRL） |
| `freight_value` | FLOAT64 | NULLABLE | 送料（BRL） |
| `sum_revenue` | FLOAT64 | NULLABLE | 明細売上（price + freight_value） |
| `main_payment_type` | STRING | NULLABLE | 主な支払方法 |
| `review_score` | INTEGER | NULLABLE | レビュースコア（1〜5） |
| `delivery_days` | INTEGER | NULLABLE | 実際の配送日数 |
| `is_on_time` | BOOLEAN | NULLABLE | 期日内配送フラグ |
| `is_repeat_customer` | BOOLEAN | NULLABLE | リピーター判定フラグ |
