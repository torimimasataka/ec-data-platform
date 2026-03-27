# テーブル定義書：app_hourly_kpi

| 項目 | 値 |
|---|---|
| **論理名** | 時間帯×曜日別注文ヒートマップ |
| **物理名** | `ec-data-platform-2026.05_application.app_hourly_kpi` |
| **参照元** | `unf_order_items`（03_unification） |
| **粒度** | 1行 = 1時間帯（0〜23時）× 1曜日（月〜日） |
| **行数** | 168件（24時間 × 7曜日） |
| **層** | 05_application（Streamlit Page 11 向け） |
| **更新方法** | `dbt run --select app_hourly_kpi` |
| **最終更新日** | 2026-03-27 |

### 概要

全期間の注文を時間帯・曜日で集計したヒートマップ用テーブル。「何曜日の何時に注文が多いか」を可視化する。正規化値（0〜1）も付与しており、最大値を1として相対的な強度を表現できる。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `hour_of_day` | INTEGER | NULLABLE | 時間帯（0〜23） |
| `day_of_week_num` | INTEGER | NULLABLE | 曜日番号（1=月曜〜7=日曜） |
| `day_of_week_name` | STRING | NULLABLE | 曜日名（Monday〜Sunday） |
| `cnt_orders` | INTEGER | NULLABLE | 注文件数 |
| `sum_revenue` | FLOAT64 | NULLABLE | 売上合計（BRL） |
| `aov` | FLOAT64 | NULLABLE | 平均注文単価 |
| `cnt_orders_normalized` | FLOAT64 | NULLABLE | 注文数の正規化値（最大値=1、ヒートマップ強度用） |
| `sum_revenue_normalized` | FLOAT64 | NULLABLE | 売上の正規化値（最大値=1） |
