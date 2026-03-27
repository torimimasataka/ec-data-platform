# テーブル定義書：app_category_customer_kpi

| 項目 | 値 |
|---|---|
| **論理名** | カテゴリ別月次顧客KPI |
| **物理名** | `ec-data-platform-2026.05_application.app_category_customer_kpi` |
| **参照元** | `t_category_monthly`（04_intermediate） |
| **粒度** | 1行 = 1カテゴリ × 1年月 |
| **行数** | 1,243件 |
| **層** | 05_application（Streamlit Page 1 KPIカード向け） |
| **更新方法** | `dbt run --select app_category_customer_kpi` |
| **最終更新日** | 2026-03-27 |

### 概要

カテゴリフィルター時の「Unique Customers」「Repeat Rate」KPI カード表示用。`app_summary_kpi` はカテゴリ軸を持たないため、カテゴリ選択時はこのテーブルから集計する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `product_category_name_english` | STRING | NULLABLE | カテゴリ名（英語） |
| `year_month` | STRING | NULLABLE | 年月文字列（YYYY-MM） |
| `order_month` | TIMESTAMP | NULLABLE | 月初日（**TIMESTAMP型**）。Streamlit では `pd.to_datetime()` 後に `.dt.strftime("%Y-%m")` でマッチングする |
| `cnt_unique_customers_month` | INTEGER | NULLABLE | 月次ユニーク顧客数 |
| `cnt_repeat_customers_month` | INTEGER | NULLABLE | 月次リピート顧客数 |
| `repeat_customer_rate_month` | FLOAT64 | NULLABLE | リピート率（cnt_repeat / cnt_unique） |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | `order_month` は TIMESTAMP 型。Streamlit 側では `strftime("%Y-%m")` 文字列比較でマッチングしているため DATE 型不一致の影響を受けない |
| 2 | 複数カテゴリ選択時は `cnt_unique_customers_month` を単純合算する（顧客の重複計上が微量に発生する可能性あり） |
