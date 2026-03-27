# テーブル定義書：app_geo_summary

| 項目 | 値 |
|---|---|
| **論理名** | 州別月次地域サマリ |
| **物理名** | `ec-data-platform-2026.05_application.app_geo_summary` |
| **参照元** | `t_state_monthly`（04_intermediate） |
| **粒度** | 1行 = 1州 × 1年月 |
| **対象** | 全配送済み注文 |
| **行数** | 556件 |
| **層** | 05_application（Streamlit Page 1・Page 6 向け） |
| **更新方法** | `dbt run --select app_geo_summary` |
| **最終更新日** | 2026-03-27 |

### 概要

州別の月次売上・注文・顧客数を保持するテーブル。Streamlit ダッシュボードの州スライサー選択肢（`state_name_en`）の生成元でもあるため、`app_cross_monthly` と州名が一致している必要がある。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `customer_state` | STRING | NULLABLE | 州コード（例: SP, RJ） |
| `state_code_iso` | STRING | NULLABLE | ISO形式州コード（例: BR-SP）。地図可視化用 |
| `state_name_en` | STRING | NULLABLE | 州名（英語）。アクセント付き（`Amapá`, `Ceará` 等）|
| `year_month` | STRING | NULLABLE | 年月文字列（YYYY-MM形式） |
| `order_month` | DATE | NULLABLE | 月初日（DATE型） |
| `order_year` | STRING | NULLABLE | 年（YYYY形式） |
| `sum_price_month` | FLOAT64 | NULLABLE | 月次売上合計（BRL） |
| `sum_freight_month` | FLOAT64 | NULLABLE | 月次送料合計（BRL） |
| `cnt_orders_month` | INTEGER | NULLABLE | 月次注文件数 |
| `cnt_unique_customers_month` | INTEGER | NULLABLE | 月次ユニーク顧客数 |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 月次平均レビュースコア |
| `rate_price_in_all_month` | FLOAT64 | NULLABLE | 月内の全州売上シェア（0〜1） |
| `rank_revenue_month` | INTEGER | NULLABLE | 月次売上ランキング（1位 = 最高売上） |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | `state_name_en` は `app_cross_monthly` と同一スペルに統一（2026-03-27 修正済み）。変更時は両テーブルを同時に `dbt run` すること |
| 2 | Streamlit のスライサー選択肢 `all_states` はこのテーブルの `state_name_en` から生成される |
