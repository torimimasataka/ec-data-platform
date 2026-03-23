# テーブル定義書：t_order_kpi_monthly

| 項目 | 値 |
|---|---|
| **論理名** | 月次ビジネスKPI |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_order_kpi_monthly` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1年月(year_month)（ビジネス全体） |
| **対象** | order_status = 'delivered' |
| **行数** | 23件（2016-09〜2018-09の月次） |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_order_kpi_monthly`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

ビジネス全体の月次KPIを1テーブルに集約した中間テーブル。売上・注文・顧客数・新規/リピーター比率・AOV（注文あたり平均売上）・APV（明細あたり平均単価）・リピーター率・平均レビューを月次で確定させる。Looker Studio のサマリダッシュボード（KPIカード・時系列トレンド）の主要入力として使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `year_month` | STRING | REQUIRED | 年月（YYYY-MM形式・PK） |
| `sum_price_month` | FLOAT64 | NULLABLE | 月次売上（BRL） |
| `cnt_orders_month` | INT64 | NULLABLE | 注文件数（DISTINCT order_id） |
| `cnt_order_items_month` | INT64 | NULLABLE | 明細件数 |
| `cnt_active_customers_month` | INT64 | NULLABLE | アクティブ顧客数 |
| `cnt_new_customers_month` | INT64 | NULLABLE | 新規顧客数（その月が初回購入月） |
| `cnt_repeat_customers_month` | INT64 | NULLABLE | リピーター顧客数 |
| `aov_month` | FLOAT64 | NULLABLE | AOV = sum_price / cnt_orders（注文あたり平均売上） |
| `apv_month` | FLOAT64 | NULLABLE | APV = sum_price / cnt_order_items（明細あたり平均単価） |
| `avg_orders_per_customer_month` | FLOAT64 | NULLABLE | 顧客あたり平均注文数 |
| `repeat_customer_rate_month` | FLOAT64 | NULLABLE | リピーター率 = cnt_repeat / cnt_active（0〜1） |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 平均レビュースコア（注文単位で重複排除後に平均） |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | 新規/リピート判定は `unf_order_items` から各顧客の `MIN(order_purchase_timestamp)` を計算し、初回購入月==year_month なら新規（same-layer参照禁止のため `t_customer_all` は使わない） |
| 2 | `cnt_new + cnt_repeat = cnt_active` となるよう設計。cnt_new/cnt_repeat はIFNULL(…,0)でNULL排除 |
| 3 | AOV・APV・リピーター率の計算はすべて SAFE_DIVIDE で0除算対処 |
