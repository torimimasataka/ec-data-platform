# テーブル定義書：t_delivery_monthly

| 項目 | 値 |
|---|---|
| **論理名** | 配送パフォーマンス月次KPI |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_delivery_monthly` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1年月(year_month)（配送パフォーマンス全体） |
| **対象** | order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL |
| **行数** | 23件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_delivery_monthly`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

配送パフォーマンスの月次KPIを集計した中間テーブル。Olistデータセット固有の分析軸として、平均配送日数・中央値配送日数・オンタイム率・遅延件数・予定との差分を確定させる。配送品質の月次トレンド監視・レビュースコアとの相関分析（配送が遅れるとレビューが下がるか）に使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `year_month` | STRING | REQUIRED | 年月（YYYY-MM形式・PK）。order_purchase_timestamp ベース |
| `cnt_delivered_orders_month` | INT64 | NULLABLE | 配達完了注文数（DISTINCT order_id） |
| `avg_delivery_days_month` | FLOAT64 | NULLABLE | 平均配送日数（注文日→顧客着荷日） |
| `p50_delivery_days_month` | FLOAT64 | NULLABLE | 中央値配送日数（APPROX_QUANTILES） |
| `on_time_rate_month` | FLOAT64 | NULLABLE | オンタイム率（実際 ≤ 予定配達日の割合・0〜1） |
| `cnt_late_orders_month` | INT64 | NULLABLE | 遅延件数（実際 > 予定配達日） |
| `avg_days_diff_vs_estimate_month` | FLOAT64 | NULLABLE | 実際-予定の平均日数差（正=遅延・負=早着） |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 平均レビュースコア（注文単位で重複排除後に平均） |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | 注文単位で重複排除してから集計（`order_dedup` CTE で DISTINCT order_id に集約）。order_items 粒度での重複を防ぐ |
| 2 | `avg_days_diff_vs_estimate_month` が負の値 = 平均で予定より早着。正の値 = 平均で遅延 |
| 3 | `avg_review_score_month` との相関を見ることで、配送遅延がレビューに与える影響を分析可能（Olist固有の価値ある分析） |
| 4 | `order_estimated_delivery_date` が NULL の注文は `is_on_time` が NULL になるため、`on_time_rate_month` の分母から自動除外（COUNTIF の挙動） |
