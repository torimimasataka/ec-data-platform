# テーブル定義書：app_cohort_retention

| 項目 | 値 |
|---|---|
| **論理名** | コホートリテンション |
| **物理名** | `ec-data-platform-2026.05_application.app_cohort_retention` |
| **参照元** | `t_cohort_monthly`（04_intermediate） |
| **粒度** | 1行 = 1コホート月 × 1経過月 |
| **行数** | 219件 |
| **層** | 05_application（Streamlit Page 4 向け） |
| **更新方法** | `dbt run --select app_cohort_retention` |
| **最終更新日** | 2026-03-27 |

### 概要

初回購入月（コホート）ごとに、その後の各月でどれだけの顧客が再購入したかを追跡するリテンション分析テーブル。ヒートマップ表示に使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `first_purchase_month` | STRING | NULLABLE | コホート月（初回購入月、YYYY-MM形式） |
| `year_month` | STRING | NULLABLE | 観測月（YYYY-MM形式） |
| `cohort_month` | DATE | NULLABLE | コホート月（DATE型） |
| `order_month` | DATE | NULLABLE | 観測月（DATE型） |
| `months_since_first` | INTEGER | NULLABLE | 初回購入からの経過月数（0=初月） |
| `cnt_customers_cohort` | INTEGER | NULLABLE | コホートの初月顧客数（分母） |
| `cnt_active_customers` | INTEGER | NULLABLE | 観測月にアクティブだった顧客数 |
| `retention_rate` | FLOAT64 | NULLABLE | リテンション率（cnt_active / cnt_cohort） |
| `sum_price` | FLOAT64 | NULLABLE | 観測月の売上合計 |
| `avg_price_per_active_customer` | FLOAT64 | NULLABLE | 観測月のアクティブ顧客1人あたり売上 |
