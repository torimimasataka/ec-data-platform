# テーブル定義書：t_seller_monthly

| 項目 | 値 |
|---|---|
| **論理名** | 販売者月次集計 |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_seller_monthly` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1販売者(seller_id) × 1年月(year_month) |
| **対象** | order_status = 'delivered' |
| **行数** | 16,100件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_seller_monthly`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

販売者ごとの月次売上・注文・顧客数・主カテゴリを集計した中間テーブル。販売者別のパフォーマンスモニタリング・月次トレンド分析・レビュー動向把握に使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `seller_id` | STRING | REQUIRED | 販売者ID（複合PK①） |
| `year_month` | STRING | REQUIRED | 年月（YYYY-MM形式）（複合PK②） |
| `sum_price_month` | FLOAT64 | NULLABLE | 月次売上（BRL） |
| `cnt_orders_month` | INTEGER | NULLABLE | 注文件数（DISTINCT order_id） |
| `cnt_order_items_month` | INTEGER | NULLABLE | 明細件数 |
| `cnt_unique_customers_month` | INTEGER | NULLABLE | ユニーク顧客数 |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 平均レビュースコア（注文単位で重複排除後に平均） |
| `main_category_month` | STRING | NULLABLE | 月内主カテゴリ（金額最大・DENSE_RANK 1位） |
| `seller_state` | STRING | NULLABLE | 販売者の州コード |
