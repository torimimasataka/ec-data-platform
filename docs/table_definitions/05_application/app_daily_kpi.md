# テーブル定義書：app_daily_kpi

| 項目 | 値 |
|---|---|
| **論理名** | 日次KPI（移動平均付き） |
| **物理名** | `ec-data-platform-2026.05_application.app_daily_kpi` |
| **参照元** | `unf_order_items`（03_unification） |
| **粒度** | 1行 = 1日 |
| **行数** | 612件 |
| **層** | 05_application（Streamlit Page 9 向け） |
| **更新方法** | `dbt run --select app_daily_kpi` |
| **最終更新日** | 2026-03-27 |

### 概要

日次の売上・注文・顧客数に加え、7日移動平均・30日移動平均を付与。Page 9（日次トレンド分析）のデータソース。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `order_date` | DATE | NULLABLE | 注文日 |
| `year_month` | STRING | NULLABLE | 年月（YYYY-MM） |
| `order_year` | STRING | NULLABLE | 年 |
| `day_of_week_num` | INTEGER | NULLABLE | 曜日番号（1=月曜〜7=日曜） |
| `day_of_week_name` | STRING | NULLABLE | 曜日名（Monday〜Sunday） |
| `sum_revenue` | FLOAT64 | NULLABLE | 日次売上合計 |
| `cnt_orders` | INTEGER | NULLABLE | 日次注文件数 |
| `cnt_customers` | INTEGER | NULLABLE | 日次ユニーク顧客数 |
| `aov` | FLOAT64 | NULLABLE | 日次平均注文単価 |
| `sum_revenue_7d_ma` | FLOAT64 | NULLABLE | 売上7日移動平均 |
| `cnt_orders_7d_ma` | FLOAT64 | NULLABLE | 注文数7日移動平均 |
| `sum_revenue_30d_ma` | FLOAT64 | NULLABLE | 売上30日移動平均 |
