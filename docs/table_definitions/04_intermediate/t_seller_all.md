# テーブル定義書：t_seller_all

| 項目 | 値 |
|---|---|
| **論理名** | 販売者全期間プロファイル |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_seller_all` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1販売者(seller_id)（全期間集計） |
| **対象** | order_status = 'delivered' |
| **行数** | 3,000件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_seller_all`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

販売者ごとの全期間売上・顧客数・主カテゴリ・カテゴリ一覧を集計したプロファイルテーブル。`t_customer_all` の販売者版。Looker Studio の販売者ランキング・出品カテゴリ分析・販売者別顧客獲得数の分析に使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `seller_id` | STRING | REQUIRED | 販売者ID（PK） |
| `sum_price_all` | FLOAT64 | NULLABLE | 総売上（BRL） |
| `cnt_orders_all` | INTEGER | NULLABLE | 総注文件数 |
| `cnt_order_items_all` | INTEGER | NULLABLE | 総明細件数 |
| `cnt_unique_customers_all` | INTEGER | NULLABLE | ユニーク顧客数（獲得顧客数） |
| `cnt_active_months_all` | INTEGER | NULLABLE | 売上が発生した月数 |
| `cnt_categories_all` | INTEGER | NULLABLE | 出品カテゴリ種類数 |
| `first_order_ts_all` | TIMESTAMP | NULLABLE | 初回出荷日時 |
| `latest_order_ts_all` | TIMESTAMP | NULLABLE | 最終出荷日時 |
| `avg_review_score_all` | FLOAT64 | NULLABLE | 全期間平均レビュースコア（注文単位で重複排除後に平均） |
| `main_category_all` | STRING | NULLABLE | 主カテゴリ（金額最大・DENSE_RANK 1位） |
| `list_categories_all` | STRING | NULLABLE | 出品カテゴリ一覧（STRING_AGG DISTINCT・カンマ区切り） |
| `seller_state` | STRING | NULLABLE | 販売者の州コード |
| `seller_city` | STRING | NULLABLE | 販売者の都市名 |
