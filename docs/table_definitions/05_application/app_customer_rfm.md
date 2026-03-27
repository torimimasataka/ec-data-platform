# テーブル定義書：app_customer_rfm

| 項目 | 値 |
|---|---|
| **論理名** | 顧客RFMスコア・セグメント |
| **物理名** | `ec-data-platform-2026.05_application.app_customer_rfm` |
| **参照元** | `t_customer_all`（04_intermediate） |
| **粒度** | 1行 = 1顧客（customer_unique_id） |
| **行数** | 93,358件 |
| **層** | 05_application（Streamlit Page 3 向け） |
| **更新方法** | `dbt run --select app_customer_rfm` |
| **最終更新日** | 2026-03-27 |

### 概要

RFM（Recency・Frequency・Monetary）分析に基づく顧客セグメンテーションテーブル。各顧客に R/F/M スコア（1〜5）を付与し、セグメント（Champions / Loyal Customers 等）に分類する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `customer_unique_id` | STRING | NULLABLE | 顧客ID（PK） |
| `sum_price_all` | FLOAT64 | NULLABLE | 累計購入金額（Monetary） |
| `cnt_orders_all` | INTEGER | NULLABLE | 累計注文件数（Frequency） |
| `recency_days` | INTEGER | NULLABLE | 最終購入からの経過日数（Recency）。基準日はデータセット最終日 |
| `first_purchase_date` | DATE | NULLABLE | 初回購入日 |
| `latest_purchase_date` | DATE | NULLABLE | 最終購入日 |
| `main_category_all` | STRING | NULLABLE | 最も多く購入したカテゴリ |
| `main_payment_type_all` | STRING | NULLABLE | 最も多く使った支払方法 |
| `customer_state` | STRING | NULLABLE | 顧客の居住州コード |
| `is_repeat_customer` | BOOLEAN | NULLABLE | リピーター判定（cnt_orders >= 2） |
| `avg_review_score_all` | FLOAT64 | NULLABLE | 平均レビュースコア |
| `r_score` | INTEGER | NULLABLE | Recency スコア（1〜5。5が最近） |
| `f_score` | INTEGER | NULLABLE | Frequency スコア（1〜5。5が最多） |
| `m_score` | INTEGER | NULLABLE | Monetary スコア（1〜5。5が最高額） |
| `rfm_total_score` | INTEGER | NULLABLE | R+F+M 合計スコア（3〜15） |
| `rfm_segment` | STRING | NULLABLE | セグメント名（Champions / Loyal Customers / At Risk 等） |
