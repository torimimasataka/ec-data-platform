# テーブル定義書：app_daily_category

| 項目 | 値 |
|---|---|
| **論理名** | カテゴリ別日次時系列 |
| **物理名** | `ec-data-platform-2026.05_application.app_daily_category` |
| **参照元** | `unf_order_items`（03_unification） |
| **粒度** | 1行 = 1カテゴリ × 1日 |
| **行数** | 18,792件 |
| **層** | 05_application（Streamlit Page 10 向け） |
| **更新方法** | `dbt run --select app_daily_category` |
| **最終更新日** | 2026-03-27 |

### 概要

カテゴリ別の日次売上・注文数推移。7日移動平均付き。Page 10（カテゴリ別日次時系列）のデータソース。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `order_date` | DATE | NULLABLE | 注文日 |
| `year_month` | STRING | NULLABLE | 年月（YYYY-MM） |
| `order_year` | STRING | NULLABLE | 年 |
| `product_category_name_english` | STRING | NULLABLE | カテゴリ名（英語） |
| `sum_revenue` | FLOAT64 | NULLABLE | 日次売上合計 |
| `cnt_orders` | INTEGER | NULLABLE | 日次注文件数 |
| `cnt_customers` | INTEGER | NULLABLE | 日次ユニーク顧客数 |
| `aov` | FLOAT64 | NULLABLE | 日次平均注文単価 |
| `sum_revenue_7d_ma` | FLOAT64 | NULLABLE | 売上7日移動平均（カテゴリ単位） |
