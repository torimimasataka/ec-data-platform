# テーブル定義書：t_cohort_monthly

| 項目 | 値 |
|---|---|
| **論理名** | コホート月次リテンション |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_cohort_monthly` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1コホート(first_purchase_month) × 1計測月(year_month) |
| **対象** | order_status = 'delivered'、year_month >= first_purchase_month |
| **行数** | 219件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_cohort_monthly`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

初回購入月（コホート）ごとに、その後の各月で何人の顧客が継続購入しているかを追跡するリテンション分析テーブル。`months_since_first=0` が初月、1が翌月の値。リテンション率の推移・コホート別LTV・購入継続期間の分布を可視化できる。ECにおいて最重要の分析軸のひとつ。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `first_purchase_month` | STRING | REQUIRED | コホート（初回購入月・YYYY-MM形式・複合PK①） |
| `year_month` | STRING | REQUIRED | 計測月（YYYY-MM形式・複合PK②） |
| `months_since_first` | INT64 | NULLABLE | 初回購入月からの経過月数（0=初月・1=翌月） |
| `cnt_customers_cohort` | INT64 | NULLABLE | コホートの初期顧客数（全計測月で固定値） |
| `cnt_active_customers` | INT64 | NULLABLE | その計測月のアクティブ顧客数 |
| `retention_rate` | FLOAT64 | NULLABLE | リテンション率 = cnt_active / cnt_customers_cohort（0〜1） |
| `sum_price` | FLOAT64 | NULLABLE | コホートのその月の売上（BRL） |
| `avg_price_per_active_customer` | FLOAT64 | NULLABLE | アクティブ顧客あたり売上 |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | `months_since_first=0`（初月）の `retention_rate` は必ず 1.0 になる（コホート全員が初月にアクティブ） |
| 2 | `cnt_customers_cohort` は全計測月で同じ値（コホートのサイズは変わらない） |
| 3 | Looker Studio でコホートヒートマップを作る場合、X軸=months_since_first、Y軸=first_purchase_month、値=retention_rate とする |
| 4 | year_month < first_purchase_month の行は存在しない（WHERE 条件で除外済み） |
