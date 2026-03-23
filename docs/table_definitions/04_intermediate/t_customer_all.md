# テーブル定義書：t_customer_all

| 項目 | 値 |
|---|---|
| **論理名** | 顧客全期間プロファイル |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_customer_all` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1顧客(customer_unique_id)（全期間集計） |
| **対象** | order_status = 'delivered'（配送完了済み注文のみ） |
| **行数** | 93,400件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_customer_all`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

顧客ごとの全期間購入行動を集計したプロファイルテーブル。RFM指標（Recency / Frequency / Monetary）・主カテゴリ・主支払方法・購入カテゴリ一覧を確定させる。下流の `05_application` でのRFMセグメンテーション・顧客ランキング・リピーター分析の基礎テーブルとして使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `customer_unique_id` | STRING | REQUIRED | 顧客ユニークID（PK） |
| `sum_price_all` | FLOAT64 | NULLABLE | 総購入金額（Monetary / BRL） |
| `cnt_orders_all` | INTEGER | NULLABLE | 総注文件数（Frequency） |
| `cnt_order_months_all` | INTEGER | NULLABLE | 購入月数 |
| `cnt_categories_all` | INTEGER | NULLABLE | 購入カテゴリ種類数 |
| `first_purchase_ts_all` | TIMESTAMP | NULLABLE | 初回購入日時 |
| `latest_purchase_ts_all` | TIMESTAMP | NULLABLE | 最終購入日時 |
| `recency_days` | INTEGER | NULLABLE | 最終購入からの経過日数（Recency・データ最終日基準） |
| `avg_review_score_all` | FLOAT64 | NULLABLE | 全期間平均レビュースコア（注文単位で重複排除後に平均） |
| `main_category_all` | STRING | NULLABLE | 主カテゴリ（金額最大・DENSE_RANK 1位） |
| `main_payment_type_all` | STRING | NULLABLE | 主支払方法（件数最多・DENSE_RANK 1位） |
| `list_categories_all` | STRING | NULLABLE | 購入カテゴリ一覧（STRING_AGG DISTINCT・カンマ区切り） |
| `customer_state` | STRING | NULLABLE | 顧客の州コード |
| `is_repeat_customer` | BOOLEAN | NULLABLE | リピーター（cnt_orders_all > 1） |
| `has_main_category_all` | BOOLEAN | NULLABLE | 主カテゴリ確定済み |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | `recency_days` はデータセット内の最終注文日を基準にする（実行タイミング非依存・再現性あり） |
| 2 | `main_payment_type_all` は注文単位でカウントして件数最多を選択（unf_order_items の main_payment_type を使用） |
| 3 | RFMセグメントの付与は `05_application` 層で行う。このテーブルはR/F/Mの数値のみを確定させる |
