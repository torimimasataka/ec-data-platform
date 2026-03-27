# 05_application テーブル定義書一覧

Streamlit ダッシュボード各ページ向けの最終出力テーブル。

| テーブル名 | 論理名 | 行数 | 対象ページ |
|---|---|---|---|
| [app_summary_kpi](./app_summary_kpi.md) | 全体月次KPIサマリ | 23 | Page 1（サマリ） |
| [app_cross_monthly](./app_cross_monthly.md) | カテゴリ×州×月クロス集計 | 11,393 | Page 1（ユニバーサルスライサー） |
| [app_geo_summary](./app_geo_summary.md) | 州別月次地域サマリ | 556 | Page 1・Page 6 |
| [app_category_performance](./app_category_performance.md) | カテゴリ別月次パフォーマンス | 1,243 | Page 1・Page 5 |
| [app_category_customer_kpi](./app_category_customer_kpi.md) | カテゴリ別月次顧客KPI | 1,243 | Page 1（KPIカード） |
| [app_state_customer_kpi](./app_state_customer_kpi.md) | 州別月次顧客KPI | 556 | Page 1（KPIカード） |
| [app_sales_trend](./app_sales_trend.md) | カテゴリ別月次売上トレンド（前年比付き） | 1,243 | Page 2 |
| [app_customer_rfm](./app_customer_rfm.md) | 顧客RFMスコア・セグメント | 93,358 | Page 3 |
| [app_cohort_retention](./app_cohort_retention.md) | コホートリテンション | 219 | Page 4 |
| [app_delivery_quality](./app_delivery_quality.md) | 月次配送品質KPI | 23 | Page 7 |
| [app_order_detail](./app_order_detail.md) | 注文明細ドリルダウン | 110,197 | Page 8 |
| [app_daily_kpi](./app_daily_kpi.md) | 日次KPI（移動平均付き） | 612 | Page 9 |
| [app_daily_category](./app_daily_category.md) | カテゴリ別日次時系列 | 18,792 | Page 10 |
| [app_hourly_kpi](./app_hourly_kpi.md) | 時間帯×曜日別注文ヒートマップ | 168 | Page 11 |

## 重要な注意事項

- `app_cross_monthly.order_month` は **TIMESTAMP（UTC）型**。Streamlit クエリでは `DATE(order_month)` キャスト必須
- `app_category_customer_kpi.order_month` / `app_state_customer_kpi.order_month` も **TIMESTAMP型**
- 州名（`state_name_en`）は `app_cross_monthly` と `app_geo_summary` で統一済み（アクセント付き: `Amapá`, `Ceará` 等）。新規マッピング追加時は `app_cross_monthly.sql` を参照
