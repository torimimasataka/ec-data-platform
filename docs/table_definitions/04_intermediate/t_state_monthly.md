# テーブル定義書：t_state_monthly

| 項目 | 値 |
|---|---|
| **論理名** | 州別月次集計 |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_state_monthly` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1顧客州(customer_state) × 1年月(year_month) |
| **対象** | order_status = 'delivered'、customer_state NOT NULL |
| **行数** | 556件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_state_monthly`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

ブラジルの州（Estado）ごとの月次注文動向を集計した中間テーブル。売上・注文・顧客数・全体シェアを保持する。Looker Studio の地域別ヒートマップ・州別売上ランキング・地域別トレンド推移の入力として使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `customer_state` | STRING | REQUIRED | 顧客の州コード（ブラジル州略称・複合PK①） |
| `year_month` | STRING | REQUIRED | 年月（YYYY-MM形式）（複合PK②） |
| `sum_price_month` | FLOAT64 | NULLABLE | 州月次売上（BRL） |
| `sum_freight_month` | FLOAT64 | NULLABLE | 州月次送料合計（BRL） |
| `cnt_orders_month` | INTEGER | NULLABLE | 注文件数（DISTINCT order_id） |
| `cnt_order_items_month` | INTEGER | NULLABLE | 明細件数 |
| `cnt_unique_customers_month` | INTEGER | NULLABLE | ユニーク顧客数 |
| `avg_review_score_month` | FLOAT64 | NULLABLE | 平均レビュースコア（注文単位で重複排除後に平均） |
| `rate_price_in_all_month` | FLOAT64 | NULLABLE | 月内の全州売上シェア（0〜1） |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | 対象は顧客の居住州（customer_state）。販売者の州（seller_state）ではない |
| 2 | ブラジルの州コードは2文字略称（例：SP=サンパウロ、RJ=リオデジャネイロ） |
| 3 | `rate_price_in_all_month` は月単位での全州合計を分母にしたシェア |
