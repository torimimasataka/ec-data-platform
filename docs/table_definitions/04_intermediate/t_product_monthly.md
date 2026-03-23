# テーブル定義書：t_product_monthly

| 項目 | 値 |
|---|---|
| **論理名** | 商品月次集計 |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_product_monthly` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1商品(product_id) × 1年月(year_month) |
| **対象** | order_status = 'delivered' |
| **行数** | 60,900件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_product_monthly`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

商品（product_id）ごとの月次売上・注文数・顧客数・平均単価・平均レビューを集計した中間テーブル。売れ筋商品の特定・商品ライフサイクル分析・カテゴリ内での商品比較・レビューと売上の相関分析に使用する。`t_category_monthly` が集計軸をカテゴリにしているのに対し、このテーブルは個別商品レベルの分析を提供する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `product_id` | STRING | REQUIRED | 商品ID（複合PK①） |
| `year_month` | STRING | REQUIRED | 年月（YYYY-MM形式・複合PK②） |
| `product_category_name_english` | STRING | NULLABLE | カテゴリ名（英語・ANY_VALUE で取得） |
| `sum_price_month` | FLOAT64 | NULLABLE | 月次売上（BRL） |
| `cnt_orders_month` | INT64 | NULLABLE | 注文件数（DISTINCT order_id） |
| `cnt_order_items_month` | INT64 | NULLABLE | 明細件数 |
| `cnt_unique_customers_month` | INT64 | NULLABLE | ユニーク顧客数 |
| `avg_item_price_month` | FLOAT64 | NULLABLE | 平均単価 = sum_price / cnt_order_items |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 平均レビュースコア（注文単位で重複排除後に平均） |
