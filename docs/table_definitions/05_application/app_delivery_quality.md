# テーブル定義書：app_delivery_quality

| 項目 | 値 |
|---|---|
| **論理名** | 月次配送品質KPI |
| **物理名** | `ec-data-platform-2026.05_application.app_delivery_quality` |
| **参照元** | `t_delivery_monthly`（04_intermediate） |
| **粒度** | 1行 = 1年月 |
| **行数** | 23件 |
| **層** | 05_application（Streamlit Page 7 向け） |
| **更新方法** | `dbt run --select app_delivery_quality` |
| **最終更新日** | 2026-03-27 |

### 概要

月次の配送日数・遅延率・レビュースコアを保持する配送品質分析テーブル。Page 7（配送・品質分析）のデータソース。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `year_month` | STRING | NULLABLE | 年月（YYYY-MM） |
| `order_month` | DATE | NULLABLE | 月初日（DATE型） |
| `order_year` | STRING | NULLABLE | 年 |
| `cnt_delivered_orders_month` | INTEGER | NULLABLE | 月次配送完了注文件数 |
| `avg_delivery_days_month` | FLOAT64 | NULLABLE | 月次平均配送日数 |
| `p50_delivery_days_month` | INTEGER | NULLABLE | 配送日数中央値（p50） |
| `on_time_rate_month` | FLOAT64 | NULLABLE | 期日内配送率（0〜1） |
| `cnt_late_orders_month` | INTEGER | NULLABLE | 遅延注文件数 |
| `late_rate_month` | FLOAT64 | NULLABLE | 遅延率（cnt_late / cnt_delivered） |
| `avg_days_diff_vs_estimate_month` | FLOAT64 | NULLABLE | 予定日との差異の平均日数（マイナス=早着） |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 月次平均レビュースコア |
