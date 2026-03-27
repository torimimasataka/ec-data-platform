# テーブル定義書：app_summary_kpi

| 項目 | 値 |
|---|---|
| **論理名** | 全体月次KPIサマリ |
| **物理名** | `ec-data-platform-2026.05_application.app_summary_kpi` |
| **参照元** | `t_order_kpi_monthly` |
| **粒度** | 1行 = 1年月 |
| **対象** | 全配送済み注文 |
| **行数** | 23件 |
| **層** | 05_application（Streamlit Page 1 向け） |
| **更新方法** | `dbt run --select app_summary_kpi` |
| **最終更新日** | 2026-03-27 |

### 概要

ダッシュボード Page 1（サマリ）の KPI カード・月次トレンドグラフ用テーブル。フィルターなし時のベースデータ。`order_month` は DATE 型（他テーブルとの `.isin()` 比較の基準になる）。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `year_month` | STRING | NULLABLE | 年月文字列（YYYY-MM形式）|
| `order_month` | DATE | NULLABLE | 月初日（2018-01-01等）。Streamlit の期間フィルター基準 |
| `order_year` | STRING | NULLABLE | 年（YYYY形式） |
| `sum_price_month` | FLOAT64 | NULLABLE | 月次売上合計（BRL） |
| `cnt_orders_month` | INTEGER | NULLABLE | 月次注文件数 |
| `cnt_order_items_month` | INTEGER | NULLABLE | 月次明細件数 |
| `cnt_active_customers_month` | INTEGER | NULLABLE | 月次ユニーク顧客数 |
| `cnt_new_customers_month` | INTEGER | NULLABLE | 月次新規顧客数（初回購入） |
| `cnt_repeat_customers_month` | INTEGER | NULLABLE | 月次リピート顧客数 |
| `aov_month` | FLOAT64 | NULLABLE | 平均注文単価（sum_price / cnt_orders） |
| `repeat_customer_rate_month` | FLOAT64 | NULLABLE | リピート率（cnt_repeat / cnt_active） |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 月次平均レビュースコア |
| `sum_revenue_ytd` | FLOAT64 | NULLABLE | 年初来売上累計（YTD） |
| `cnt_orders_ytd` | INTEGER | NULLABLE | 年初来注文件数累計 |
