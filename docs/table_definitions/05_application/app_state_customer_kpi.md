# テーブル定義書：app_state_customer_kpi

| 項目 | 値 |
|---|---|
| **論理名** | 州別月次顧客KPI |
| **物理名** | `ec-data-platform-2026.05_application.app_state_customer_kpi` |
| **参照元** | `t_state_monthly`（04_intermediate） |
| **粒度** | 1行 = 1州 × 1年月 |
| **行数** | 556件 |
| **層** | 05_application（Streamlit Page 1 KPIカード向け） |
| **更新方法** | `dbt run --select app_state_customer_kpi` |
| **最終更新日** | 2026-03-27 |

### 概要

州フィルター時の「Unique Customers」「Repeat Rate」KPI カード表示用。Streamlit の `load_state_customer_kpi()` では `app_geo_summary` と JOIN して `state_name_en` を付与している。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `customer_state` | STRING | NULLABLE | 州コード（例: SP, RJ） |
| `year_month` | STRING | NULLABLE | 年月文字列（YYYY-MM） |
| `order_month` | TIMESTAMP | NULLABLE | 月初日（**TIMESTAMP型**） |
| `cnt_unique_customers_month` | INTEGER | NULLABLE | 月次ユニーク顧客数 |
| `cnt_repeat_customers_month` | INTEGER | NULLABLE | 月次リピート顧客数 |
| `repeat_customer_rate_month` | FLOAT64 | NULLABLE | リピート率 |
