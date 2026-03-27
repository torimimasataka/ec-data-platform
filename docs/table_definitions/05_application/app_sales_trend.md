# テーブル定義書：app_sales_trend

| 項目 | 値 |
|---|---|
| **論理名** | カテゴリ別月次売上トレンド（前年比付き） |
| **物理名** | `ec-data-platform-2026.05_application.app_sales_trend` |
| **参照元** | `t_category_monthly`（04_intermediate） |
| **粒度** | 1行 = 1カテゴリ × 1年月 |
| **行数** | 1,243件 |
| **層** | 05_application（Streamlit Page 2 向け） |
| **更新方法** | `dbt run --select app_sales_trend` |
| **最終更新日** | 2026-03-27 |

### 概要

売上・注文・顧客数の月次推移と前年同月比（YoY）を含む。Streamlit Page 2（売上・トレンド分析）のデータソース。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `product_category_name_english` | STRING | NULLABLE | カテゴリ名（英語） |
| `year_month` | STRING | NULLABLE | 年月文字列（YYYY-MM） |
| `order_month` | DATE | NULLABLE | 月初日（DATE型） |
| `order_year` | STRING | NULLABLE | 年 |
| `sum_price_month` | FLOAT64 | NULLABLE | 月次売上合計（BRL） |
| `cnt_orders_month` | INTEGER | NULLABLE | 月次注文件数 |
| `cnt_unique_customers_month` | INTEGER | NULLABLE | 月次ユニーク顧客数 |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 月次平均レビュースコア |
| `rate_price_in_all_month` | FLOAT64 | NULLABLE | 月内の全カテゴリ売上シェア |
| `rank_revenue_month` | INTEGER | NULLABLE | 月次売上ランキング |
| `sum_price_prev_year` | FLOAT64 | NULLABLE | 前年同月売上（LAG 12ヶ月） |
| `rate_yoy_revenue` | FLOAT64 | NULLABLE | 前年比成長率（YoY）。`(当月 - 前年) / 前年` |
