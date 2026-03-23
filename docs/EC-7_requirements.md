# EC-7 要件定義：04_intermediate 層 データマート設計

> **チケット:** EC-7
> **レイヤー:** `04_intermediate`
> **プレフィックス:** `t_`
> **ソース:** `unf_order_items`（03_unification）
> **作成日:** 2026-03

---

## 1. 目的・設計思想

`04_intermediate` 層は **「分析基礎の確定集計」** を担う。

- `unf_order_items`（35カラム・明細粒度）を**分析軸ごとに集計し、指標を確定させる**
- 下流の `05_application` や BI がそのまま使える **横持ちフラグ・代表値つき集計テーブル** を提供する
- 「1行の意味（粒度）」を各テーブルで必ず明示する

### 設計原則（SQL分析テーブル設計パターン集より）

| 原則 | 実装方針 |
|---|---|
| **命名規約の徹底** | `sum_/cnt_/first_/latest_/is_/has_/main_/rate_/per_/list_/` を統一 |
| **主カテゴリの一意化** | `DENSE_RANK() + QUALIFY rnk=1`、タイブレークにカテゴリ名を追加し再計算でブレない |
| **DISTINCTの最小化** | 明細→ウィンドウ→最後に一意化。`SELECT DISTINCT` を最少回に抑える |
| **安全な割算** | `SAFE_DIVIDE(numer, NULLIF(denom, 0))` を徹底 |
| **NULL耐性** | `IFNULL / COALESCE / SAFE_CAST` で早めに処理 |
| **型の保持** | DATE/TIMESTAMP は型のまま保持し、表示変換は BI/Application 層で |
| **検算SQLの付属** | 各テーブルに主キー重複・合計一致・フラグ健全性の検算クエリを付ける |

---

## 2. 作成テーブル一覧

| テーブル名 | 粒度（1行の意味） | 対応パターン | 優先度 |
|---|---|---|---|
| `t_customer_monthly` | 1顧客 × 1年月 | 型① FY別集計の月次版 | ★★★ |
| `t_customer_all` | 1顧客（全期間） | 型④ ユーザープロファイル型 | ★★★ |
| `t_category_monthly` | 1カテゴリ × 1年月 | 型② 二次属性×月次 | ★★☆ |
| `t_seller_monthly` | 1販売者 × 1年月 | 型① 販売者軸 | ★★☆ |

---

## 3. テーブル詳細設計

---

### 3-1. `t_customer_monthly`
**粒度:** `customer_unique_id × year_month`（1行 = 1顧客 × 1ヶ月）

#### カラム定義

| カラム名 | 型 | 説明 |
|---|---|---|
| `customer_unique_id` | STRING | 顧客ID（主キー①） |
| `year_month` | STRING | 年月（`FORMAT_DATE('%Y-%m', ...)` ）（主キー②） |
| `sum_price_month` | FLOAT64 | 月内の商品金額合計（price の SUM） |
| `sum_freight_month` | FLOAT64 | 月内の送料合計 |
| `cnt_orders_month` | INT64 | 月内の注文件数（DISTINCT order_id） |
| `cnt_order_items_month` | INT64 | 月内の明細行数 |
| `first_purchase_ts_month` | TIMESTAMP | 月内の初回購入日時 |
| `latest_purchase_ts_month` | TIMESTAMP | 月内の最終購入日時 |
| `avg_review_score_month` | FLOAT64 | 月内の平均レビュースコア（SAFE_DIVIDE） |
| `main_category_month` | STRING | 月内の主カテゴリ（金額ベースDENSE_RANK 1位） |
| `is_active_month` | BOOL | 購入あり（sum_price_month > 0） |
| `is_repeat_in_month` | BOOL | 月内複数注文（cnt_orders_month > 1） |
| `customer_state` | STRING | 顧客の州 |

#### 実装メモ
- `customer_unique_id` を使う（`customer_id` はOlist固有の注文ごとID）
- `sum_payment_value` は注文単位の重複があるため、明細金額 `price + freight_value` を使う
- 主カテゴリは `product_category_name_english` を使い、英語名で統一

---

### 3-2. `t_customer_all`
**粒度:** `customer_unique_id`（1行 = 1顧客・全期間集計）

#### カラム定義

| カラム名 | 型 | 説明 |
|---|---|---|
| `customer_unique_id` | STRING | 顧客ID（主キー） |
| `sum_price_all` | FLOAT64 | 総購入金額（Monetary） |
| `cnt_orders_all` | INT64 | 総注文件数（Frequency） |
| `cnt_order_months_all` | INT64 | 購入月数 |
| `cnt_categories_all` | INT64 | 購入カテゴリ種類数 |
| `first_purchase_ts_all` | TIMESTAMP | 初回購入日時 |
| `latest_purchase_ts_all` | TIMESTAMP | 最終購入日時 |
| `recency_days` | INT64 | 最終購入からの経過日数（データ最終日基準） |
| `avg_review_score_all` | FLOAT64 | 全期間平均レビュースコア |
| `main_category_all` | STRING | 主カテゴリ（金額ベースDENSE_RANK 1位） |
| `main_payment_type_all` | STRING | 主支払方法（件数ベースDENSE_RANK 1位） |
| `list_categories_all` | STRING | 購入カテゴリ一覧（STRING_AGG DISTINCT ORDER BY） |
| `customer_state` | STRING | 顧客の州 |
| `is_repeat_customer` | BOOL | リピーター（cnt_orders_all > 1） |
| `has_main_category_all` | BOOL | 主カテゴリ確定済み |

#### RFM補助列の考え方
```
R（Recency）  = recency_days（小さいほど直近）
F（Frequency） = cnt_orders_all
M（Monetary）  = sum_price_all
```
セグメンテーションは `05_application` 層で行うが、この3指標はここで確定させる。

---

### 3-3. `t_category_monthly`
**粒度:** `product_category_name_english × year_month`（1行 = 1カテゴリ × 1ヶ月）

#### カラム定義

| カラム名 | 型 | 説明 |
|---|---|---|
| `product_category_name_english` | STRING | カテゴリ名（主キー①） |
| `year_month` | STRING | 年月（主キー②） |
| `sum_price_month` | FLOAT64 | カテゴリ月次売上 |
| `cnt_orders_month` | INT64 | 注文件数（DISTINCT order_id） |
| `cnt_order_items_month` | INT64 | 明細件数 |
| `cnt_unique_customers_month` | INT64 | ユニーク顧客数 |
| `cnt_unique_sellers_month` | INT64 | ユニーク販売者数 |
| `avg_review_score_month` | FLOAT64 | 平均レビュースコア |
| `rate_price_in_all_month` | FLOAT64 | 月内の全カテゴリ売上シェア（SAFE_DIVIDE） |

---

### 3-4. `t_seller_monthly`
**粒度:** `seller_id × year_month`（1行 = 1販売者 × 1ヶ月）

#### カラム定義

| カラム名 | 型 | 説明 |
|---|---|---|
| `seller_id` | STRING | 販売者ID（主キー①） |
| `year_month` | STRING | 年月（主キー②） |
| `sum_price_month` | FLOAT64 | 月次売上 |
| `cnt_orders_month` | INT64 | 注文件数（DISTINCT order_id） |
| `cnt_order_items_month` | INT64 | 明細件数 |
| `cnt_unique_customers_month` | INT64 | ユニーク顧客数 |
| `avg_review_score_month` | FLOAT64 | 平均レビュースコア |
| `main_category_month` | STRING | 主カテゴリ（金額ベースDENSE_RANK 1位） |
| `seller_state` | STRING | 販売者の州 |

---

## 4. 共通実装パターン

### 4-1. 主カテゴリの決め方（全テーブル共通）

```sql
-- ① 金額ベースでランク付け（タイブレークにカテゴリ名を追加し安定化）
DENSE_RANK() OVER (
  PARTITION BY customer_unique_id, year_month
  ORDER BY SUM(price) OVER (
    PARTITION BY customer_unique_id, year_month, product_category_name_english
  ) DESC,
  product_category_name_english
) AS rnk_cat_month

-- ② QUALIFY で1位だけ取る（BigQuery流）
QUALIFY rnk_cat_month = 1
```

### 4-2. year_month の生成

```sql
FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month
```

### 4-3. 安全な割算

```sql
SAFE_DIVIDE(
  SUM(price) OVER (PARTITION BY product_category_name_english, year_month),
  NULLIF(SUM(price) OVER (PARTITION BY year_month), 0)
) AS rate_price_in_all_month
```

### 4-4. recency_days の算出

```sql
DATE_DIFF(
  (SELECT MAX(DATE(order_purchase_timestamp)) FROM {{ ref('unf_order_items') }}),
  DATE(latest_purchase_ts_all),
  DAY
) AS recency_days
```

---

## 5. 検算テンプレート（各テーブル共通）

### 主キー重複チェック

```sql
-- t_customer_monthly
SELECT customer_unique_id, year_month, COUNT(*) AS cnt
FROM {{ ref('t_customer_monthly') }}
GROUP BY 1, 2
HAVING cnt > 1;

-- t_customer_all
SELECT customer_unique_id, COUNT(*) AS cnt
FROM {{ ref('t_customer_all') }}
GROUP BY 1
HAVING cnt > 1;
```

### 合計一致クロス検算

```sql
-- 中間集計の月次合計
SELECT year_month, SUM(sum_price_month) AS sum_month
FROM {{ ref('t_customer_monthly') }}
GROUP BY year_month;

-- 明細から再集計（独立検算）
SELECT
  FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month,
  SUM(price) AS sum_month
FROM {{ ref('unf_order_items') }}
WHERE order_status = 'delivered'
GROUP BY year_month;
```

### フラグ健全性チェック

```sql
-- アクティブなのに主カテゴリがNULL
SELECT * FROM {{ ref('t_customer_monthly') }}
WHERE is_active_month = TRUE AND main_category_month IS NULL;

-- リピーターなのに注文件数が1
SELECT * FROM {{ ref('t_customer_all') }}
WHERE is_repeat_customer = TRUE AND cnt_orders_all <= 1;
```

---

## 6. dbt 設定方針

```yaml
# models/04_intermediate/_models.yml（抜粋）

version: 2
models:
  - name: t_customer_monthly
    description: "1行 = 1顧客(customer_unique_id) × 1年月。月次RFM・主カテゴリ・フラグを提供。"
    config:
      materialized: table
    tests:
      - unique:
          column_name: "customer_unique_id || '-' || year_month"
      - not_null:
          column_name: customer_unique_id
```

- **マテリアライズ:** `table`（中間層は再計算OK・確定形）
- **tags:** `["intermediate", "customer"]` 等でタグ管理
- **テスト:** 主キー unique + not_null は必須

---

## 7. 実装順序

```
1. t_customer_monthly   （最重要・RFMの月次基礎）
2. t_customer_all       （顧客プロファイル・LTV）
3. t_category_monthly   （カテゴリ分析）
4. t_seller_monthly     （販売者分析）
```

---

## 8. 参考：ソーステーブル（unf_order_items）主要カラム

| カラム | 用途 |
|---|---|
| `customer_unique_id` | 真の顧客ID（リピーター追跡可） |
| `order_id` | 注文ID（DISTINCT で件数集計） |
| `order_purchase_timestamp` | 購入日時（year_month生成に使用） |
| `price` | 商品金額（明細粒度の金額） |
| `freight_value` | 送料（明細粒度） |
| `product_category_name_english` | カテゴリ名（英語・主カテゴリ決定に使用） |
| `seller_id` | 販売者ID |
| `review_score` | レビュースコア（1-5） |
| `main_payment_type` | 代表支払方法（注文単位・payments CTE集約済み） |
| `customer_state` | 顧客の州 |
| `seller_state` | 販売者の州 |

> **注意:** `sum_payment_value` は注文単位集約済みのため、order_item_id粒度で集計すると重複する。
> 明細金額の集計には `price` + `freight_value` を使うこと。
