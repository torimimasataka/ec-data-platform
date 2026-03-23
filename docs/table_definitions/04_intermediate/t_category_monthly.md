# テーブル定義書：t_category_monthly

| 項目 | 値 |
|---|---|
| **論理名** | カテゴリ月次集計 |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_category_monthly` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1カテゴリ(product_category_name_english) × 1年月(year_month) |
| **対象** | order_status = 'delivered'、product_category_name_english NOT NULL |
| **行数** | 1,200件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_category_monthly`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

商品カテゴリごとの月次売上・注文・顧客・販売者数を集計した中間テーブル。月内の全カテゴリに対するシェア（`rate_price_in_all_month`）も保持する。Looker Studio のカテゴリ別売上 Top10 ランキング・トレンド推移・シェア推移グラフの入力として使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `product_category_name_english` | STRING | REQUIRED | 商品カテゴリ名・英語（複合PK①） |
| `year_month` | STRING | REQUIRED | 年月（YYYY-MM形式）（複合PK②） |
| `sum_price_month` | FLOAT64 | NULLABLE | カテゴリ月次売上（BRL） |
| `cnt_orders_month` | INTEGER | NULLABLE | 注文件数（DISTINCT order_id） |
| `cnt_order_items_month` | INTEGER | NULLABLE | 明細件数 |
| `cnt_unique_customers_month` | INTEGER | NULLABLE | ユニーク顧客数 |
| `cnt_unique_sellers_month` | INTEGER | NULLABLE | ユニーク販売者数 |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 平均レビュースコア（注文単位で重複排除後に平均） |
| `rate_price_in_all_month` | FLOAT64 | NULLABLE | 月内の全カテゴリ売上シェア（0〜1） |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | `rate_price_in_all_month` は月単位で全カテゴリの合計を分母にしたシェア。ゼロ除算は `SAFE_DIVIDE` で対処 |
| 2 | `cnt_unique_customers_month` / `cnt_unique_sellers_month` はカテゴリの市場規模感を測る補助指標 |
