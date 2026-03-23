# データマート設計思想

> **対象レイヤー:** `04_intermediate` / `05_application`
> **最終更新:** 2026-03

---

## 1. レイヤーの役割分担

| レイヤー | 役割 | 設計の関心事 |
|---|---|---|
| `04_intermediate` | **分析基礎の確定集計** | 粒度ごとの集計・代表値の確定・フラグの付与 |
| `05_application` | **UX最適化・横断統合** | 横持ち・複数事実の統合・BI向けの最終整形 |

- `04_intermediate` は「何回計算しても同じ答えが出る確定値」を作る層。複数の下流から参照される。
- `05_application` は「BI/可視化ツールが直接読む」層。集計ではなく **横持ち・フラグ化・導入順** などUX最適化が仕事。

---

## 2. 分析軸の考え方

### 一次属性 × 二次属性

テーブルの設計は「**一次属性（主粒度）× 二次属性（分析軸）**」の組み合わせで考える。

| 属性 | 例 |
|---|---|
| **一次属性（主粒度）** | 顧客・期間（月/年）・販売者 |
| **二次属性（分析軸）** | カテゴリ・地域・支払方法・曜日タイプ・距離レンジ・割引種別 |

> 一次属性だけで集計したテーブルを先に作り、二次属性を加えた拡張テーブルを後に作る。
> 二次属性が増えるほど行数が爆発するため、粒度の選択は慎重に。

---

## 3. テーブル設計の型（4パターン）

### 型① 一次属性 × 期間集計型

**例:** `t_customer_monthly`（顧客×月）、`t_seller_monthly`（販売者×月）

- 粒度: `主キー × year_month`
- 基本指標: `sum_/cnt_/first_/latest_` を期間単位で揃える
- フラグ: `is_active_`（集計値 > 0）、`is_repeat_in_`（期間内複数回）
- 代表値: `main_category_`（金額ベースDENSE_RANK 1位）

```sql
-- 期間集計の定石：ウィンドウ関数で出してから最後に一意化
WITH base AS (
  SELECT DISTINCT
    customer_unique_id,
    year_month,
    SUM(price)       OVER (PARTITION BY customer_unique_id, year_month) AS sum_price_month,
    COUNT(DISTINCT order_id) OVER (PARTITION BY customer_unique_id, year_month) AS cnt_orders_month,
    MIN(order_purchase_timestamp) OVER (PARTITION BY customer_unique_id, year_month) AS first_purchase_ts_month,
    MAX(order_purchase_timestamp) OVER (PARTITION BY customer_unique_id, year_month) AS latest_purchase_ts_month,
    -- カテゴリ別金額（主カテゴリ決定に使う）
    SUM(price) OVER (PARTITION BY customer_unique_id, year_month, product_category_name_english) AS sum_price_cat_month
  FROM source_table
)
```

---

### 型② 二次属性拡張型

**例:** `t_category_monthly`（カテゴリ×月）、二次属性が加わった型①の拡張

- 粒度: `主キー × 二次属性キー × 期間`
- 型①と同じ指標体系に「二次属性内のシェア」を追加
- `is_main_`（二次属性内でのシェア > 50% かつ 1位）でノイズ抑制

```sql
-- シェア（割算は必ずSAFE_DIVIDEで0除算対策）
SAFE_DIVIDE(
  SUM(price) OVER (PARTITION BY customer_unique_id, year_month, category),
  NULLIF(SUM(price) OVER (PARTITION BY customer_unique_id, year_month), 0)
) AS rate_price_cat_in_all_month,

-- 主カテゴリフラグ（比率 > 50% かつ 1位）
(rate_price_cat_in_all_month > 0.5 AND rnk_cat = 1) AS is_main_category_month
```

---

### 型③ 複数事実の横断統合型（FULL OUTER JOIN）

**例:** `w_order_summary_all`（注文×支払を統合した全件ビュー）

- **「どちらかにしか存在しないレコードも落とさない」** 統合ビュー
- FULL OUTER JOIN + 直後に COALESCE でキー統一
- 片側のみ存在する指標は `IFNULL(..., 0)` でゼロ埋め
- `is_xxx_active_` フラグで可視化側の分岐を簡単化

```sql
SELECT
  COALESCE(a.key_col, b.key_col) AS key_col,
  IFNULL(a.sum_value_a, 0) AS sum_value_a,
  IFNULL(b.sum_value_b, 0) AS sum_value_b,
  (IFNULL(a.sum_value_a, 0) > 0) AS is_a_active,
  (IFNULL(b.sum_value_b, 0) > 0) AS is_b_active
FROM table_a AS a
FULL OUTER JOIN table_b AS b
  USING (key_col)
```

---

### 型④ ユーザープロファイル型

**例:** `t_customer_all`（顧客全期間・RFM・主属性）

- 粒度: `主キー` 1行（全期間集計）
- 基本指標: `sum_/cnt_/first_/latest_` の全期間版
- 代表値系: `main_`（最頻出・最大金額）、`list_`（一覧文字列）、`cnt_`（種類数）
- RFM: R=recency_days、F=cnt_orders_all、M=sum_price_all

```sql
-- メイン駅/カテゴリ/支払方法など「最頻出代表値」の定石
DENSE_RANK() OVER (
  PARTITION BY customer_unique_id
  ORDER BY COUNT(*) DESC, category_name  -- タイブレーク：名前を入れて安定化
) AS rnk_cat
QUALIFY rnk_cat = 1  -- BigQuery推奨パターン

-- カテゴリ一覧（STRING_AGGは ORDER BY を入れて再計算でも並びが安定）
STRING_AGG(DISTINCT category_name ORDER BY category_name) AS list_categories_all
```

---

## 4. KPI・指標設計のナレッジ

### 基本指標セット（どの型にも共通）

| 指標カテゴリ | カラム例 | SQL |
|---|---|---|
| **金額（M）** | `sum_price_month` | `SUM(price)` |
| **件数（F）** | `cnt_orders_month` | `COUNT(DISTINCT order_id)` |
| **日数** | `cnt_order_days_month` | `COUNT(DISTINCT DATE(order_purchase_timestamp))` |
| **初回** | `first_purchase_ts_month` | `MIN(order_purchase_timestamp)` |
| **最終** | `latest_purchase_ts_month` | `MAX(order_purchase_timestamp)` |
| **アクティブ** | `is_active_month` | `(SUM(price) > 0)` |
| **比率** | `rate_price_cat_month` | `SAFE_DIVIDE(sum_cat, NULLIF(sum_all, 0))` |

### 代表値の決め方

| 何の代表か | 決定基準 | 実装パターン |
|---|---|---|
| 主カテゴリ | 金額が最大のカテゴリ | `DENSE_RANK ORDER BY SUM(price) DESC` |
| 主支払方法 | 件数が最多の支払方法 | `DENSE_RANK ORDER BY COUNT(*) DESC` |
| リピーター判定 | 注文件数 > 1 | `cnt_orders_all > 1` |
| 高評価顧客 | 平均レビュー ≥ 4 | `avg_review_score_all >= 4.0` |

### recency_days（Recency）の算出

```sql
DATE_DIFF(
  (SELECT MAX(DATE(order_purchase_timestamp)) FROM {{ ref('unf_order_items') }}),
  DATE(latest_purchase_ts_all),
  DAY
) AS recency_days
```

> データの最終日を基準にすることで、実行タイミングに依存しない再現性のある値になる。

---

## 5. 命名規約（04〜05層共通）

### プレフィックス

| プレフィックス | 意味 | 型 | 例 |
|---|---|---|---|
| `sum_` | 合計 | FLOAT64/INT64 | `sum_price_month` |
| `cnt_` | 件数・種類数 | INT64 | `cnt_orders_month` |
| `first_` | 最初の値 | DATE/TIMESTAMP | `first_purchase_ts_all` |
| `latest_` | 最後の値 | DATE/TIMESTAMP | `latest_purchase_ts_all` |
| `avg_` | 平均 | FLOAT64 | `avg_review_score_month` |
| `is_` | 真偽フラグ | BOOL | `is_active_month` |
| `has_` | 存在フラグ | BOOL | `has_main_category_all` |
| `main_` | 代表値（最頻/最大） | STRING | `main_category_month` |
| `list_` | 一覧文字列 | STRING | `list_categories_all` |
| `rate_` | 比率（小数） | FLOAT64 | `rate_price_cat_month` |
| `per_` | 比率（%） | FLOAT64 | `per_ce_yoyaku_all` |

### サフィックス

| サフィックス | 意味 | 例 |
|---|---|---|
| `_month` | 月次集計値 | `sum_price_month` |
| `_all` | 全期間集計値 | `sum_price_all` |
| `_in_xxx` | xxx の内側（シェア） | `rate_price_in_category_month` |

### テーブル名

| プレフィックス | 層 | 意味 |
|---|---|---|
| `t_` | 04_intermediate | 集計中間テーブル |
| `w_` | 05_application | 横断統合・BIマート |

---

## 6. 実装パターン集（SQL早見表）

### year_month の生成
```sql
FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month
```

### ウィンドウ集計 → 最後に一意化
```sql
-- ウィンドウ関数で全行に集計値を付与
SELECT DISTINCT
  key_col,
  year_month,
  SUM(price) OVER (PARTITION BY key_col, year_month) AS sum_price_month
FROM source_table
-- ← 最後にDISTINCTで一意化。GROUP BYより先にウィンドウで出す
```

### 主カテゴリ（DENSE_RANK + QUALIFY）
```sql
SELECT *,
  DENSE_RANK() OVER (
    PARTITION BY customer_unique_id, year_month
    ORDER BY sum_price_cat_month DESC, product_category_name_english  -- タイブレーク必須
  ) AS rnk_cat
FROM base
QUALIFY rnk_cat = 1
```

### 安全な割算
```sql
SAFE_DIVIDE(numer, NULLIF(denom, 0))        -- 比率（0除算 → NULL）
IFNULL(value, 0)                             -- 欠損を0埋め
COALESCE(a.key_col, b.key_col) AS key_col   -- FULL OUTER JOIN後のキー統一
```

### STRING_AGGで安定した一覧文字列
```sql
STRING_AGG(DISTINCT category_name ORDER BY category_name) AS list_categories_all
-- ORDER BYを入れることで再計算しても並びが変わらない
```

### 最頻出代表値（RANK + QUALIFY）
```sql
SELECT customer_unique_id, payment_type AS main_payment_type_all
FROM (
  SELECT
    customer_unique_id,
    payment_type,
    RANK() OVER (
      PARTITION BY customer_unique_id
      ORDER BY COUNT(*) DESC, payment_type  -- タイブレーク
    ) AS rnk
  FROM source_table
  GROUP BY customer_unique_id, payment_type
)
QUALIFY rnk = 1
```

---

## 7. 検算ナレッジ（データ健全性チェック）

テーブル作成後、必ず以下を確認する。

### ① 主キー重複（一意性）

```sql
SELECT key_col_1, key_col_2, COUNT(*) AS cnt
FROM {{ ref('t_xxx') }}
GROUP BY 1, 2
HAVING cnt > 1;
-- 0行 = OK
```

### ② 合計一致クロス検算

```sql
-- 中間テーブルから
SELECT year_month, SUM(sum_price_month) FROM {{ ref('t_customer_monthly') }} GROUP BY 1;

-- ソース（unf_order_items）から直接集計
SELECT
  FORMAT_DATE('%Y-%m', DATE(order_purchase_timestamp)) AS year_month,
  SUM(price)
FROM {{ ref('unf_order_items') }}
GROUP BY 1;
-- 両者が一致すること
```

### ③ フラグ健全性

```sql
-- アクティブなのに代表値がNULL
SELECT * FROM {{ ref('t_customer_monthly') }}
WHERE is_active_month = TRUE AND main_category_month IS NULL;

-- リピーターなのに件数が1以下
SELECT * FROM {{ ref('t_customer_all') }}
WHERE is_repeat_customer = TRUE AND cnt_orders_all <= 1;
```

### ④ 一覧文字列のノイズ確認

```sql
SELECT * FROM {{ ref('t_customer_all') }}
WHERE REGEXP_CONTAINS(list_categories_all, r'(,,|^,|,$)')
   OR list_categories_all IS NULL;
```

### ⑤ FULL OUTER JOINの片側落ち確認

```sql
SELECT
  SUM(IF(a_key IS NULL, 1, 0)) AS only_b,
  SUM(IF(b_key IS NULL, 1, 0)) AS only_a
FROM (
  SELECT a.key_col AS a_key, b.key_col AS b_key
  FROM table_a a
  FULL OUTER JOIN table_b b USING (key_col)
);
```

### ⑥ 比率列のNULL・0除算確認

```sql
SELECT COUNTIF(rate_price_cat_month IS NULL) AS null_count
FROM {{ ref('t_category_monthly') }};
```

---

## 8. dbt 設定方針

```yaml
# 04_intermediate 共通設定
models:
  - name: t_customer_monthly
    description: "1行 = 1顧客(customer_unique_id) × 1年月。月次RFM基礎値・主カテゴリ・フラグを確定させる。"
    config:
      materialized: table   # 中間層は table（再計算OK・確定形）
      tags: ["intermediate", "customer"]
    tests:
      - unique:
          column_name: "customer_unique_id || '-' || year_month"
      - not_null:
          column_name: customer_unique_id
      - not_null:
          column_name: year_month
```

- **マテリアライズ:** `table`（中間層・アプリ層はすべて `table`）
- **tags:** 層名 + 主粒度（例: `["intermediate", "customer"]`）
- **dbt tests:** 主キーの `unique` + `not_null` は全テーブル必須
