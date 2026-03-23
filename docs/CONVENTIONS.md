# 命名規則

> 要件定義書（requirements.md）Section 4・5 に基づく。
> ※ 印は要件定義に明記なし → 要件の設計思想から補足。

---

## 1. テーブル命名規則

### レイヤー別プレフィックス

各レイヤーのテーブル名はプレフィックスによってユニークに識別できる。

| レイヤー | プレフィックス | 命名パターン | 例 |
|---|---|---|---|
| `01_import` | `src_` | `src_{ソース名}` | `src_orders` |
| `02_preprocess` | `prep_` | `prep_{ソース名}` | `prep_orders` |
| `03_unification` | `unf_` | `unf_{統合対象}` | `unf_order_transaction` |
| `04_intermediate` | `t_` | `t_{集計軸}_{粒度}` | `t_customer_order_monthly` |
| `05_application` | `dm_` | `dm_{分析テーマ}` | `dm_sales_summary` |

### 基本原則
- すべて **小文字・snake_case**
- `04_intermediate` の `t_` プレフィックスと命名パターンは要件定義に明記

---

## 2. カラム命名規則

### 基本原則（要件定義より）
- すべて **小文字・snake_case**
- 型に応じたサフィックス・プレフィックスを徹底する

### 型別サフィックス ※

| 型 | ルール | 例 |
|---|---|---|
| ID（STRING） | `_id` で終わる | `order_id`, `customer_id` |
| 日付（DATE） | `_date` で終わる | `order_date`, `birth_date` |
| 日時（TIMESTAMP） | `_at` または `_timestamp` で終わる | `created_at`, `purchase_timestamp` |
| フラグ（BOOL） | `is_` または `has_` で始まる（後述） | `is_repeat`, `has_review` |

### 集計カラムプレフィックス（要件定義より）

| プレフィックス | 意味 | 型 | 例 |
|---|---|---|---|
| `sum_` | 合計 | FLOAT64 / INT64 | `sum_payment_value` |
| `cnt_` | 件数 | INT64 | `cnt_orders` |
| `first_` | 最初の値 | 元の型に準ずる | `first_order_date` |
| `latest_` | 最後の値 | 元の型に準ずる | `latest_order_date` |
| `is_` | フラグ | BOOL | `is_repeat_customer` |
| `has_` | 存在フラグ | BOOL | `has_review` |
| `main_` | 代表値（最頻/最大） | 元の型に準ずる | `main_category` |
| `list_` | 一覧文字列 | STRING | `list_categories` |
| `rate_` / `per_` | 比率・割合 | FLOAT64 | `rate_repeat`, `per_item_price` |

---

## 3. SQLコーディング規約（要件定義より）

| ルール | 内容 |
|---|---|
| 予約語 | **大文字**（`SELECT`, `FROM`, `WHERE` など） |
| テーブル名・カラム名 | **小文字・snake_case** |
| `SELECT *` | **禁止** → カラムを明示 |
| `GROUP BY` | 列名明示（番号指定禁止） |
| JOIN | `LEFT OUTER JOIN` に統一。`RIGHT JOIN` 禁止 |
| サブクエリ | `WITH` 句を優先。ネストしたサブクエリは禁止 |
| ゼロ除算 | `SAFE_DIVIDE` または `NULLIF(分母, 0)` |
| NULL安全 | `NOT IN (subquery)` 禁止 → `NOT EXISTS` を使用 |
| 日付範囲 | `BETWEEN` 禁止 → 半開区間（`>= AND <`）を使用 |
| 重複排除 | `ROW_NUMBER() OVER (...) QUALIFY = 1` を使用 |

---

## 4. GATEレイヤー参照規則（アーキテクチャ原則）

### 基本原則

| 原則 | 内容 |
|---|---|
| **一方向参照** | データフローは 01 → 02 → 03 → 04 → 05 の一方向のみ。逆流禁止 |
| **同一レイヤー間参照禁止** | 同じレイヤー内のモデル同士は参照しない |
| **必ず1つ上のレイヤーを参照** | 各レイヤーは直前のレイヤーのモデルのみを参照する |

### dbt での参照方法

| レイヤー | 参照方法 | 参照先 | 例 |
|---|---|---|---|
| `01_import`（src_*） | `{{ source(...) }}` | GCS経由でBQにロードしたローデータ | `{{ source('olist_raw', 'orders') }}` |
| `02_preprocess`（prep_*） | `{{ ref(...) }}` | `01_import` の `src_*` モデル | `{{ ref('src_orders') }}` |
| `03_unification`（unf_*） | `{{ ref(...) }}` | `02_preprocess` の `prep_*` モデル | `{{ ref('prep_orders') }}` |
| `04_intermediate`（t_*） | `{{ ref(...) }}` | `03_unification` の `unf_*` モデル | `{{ ref('unf_order_transaction') }}` |
| `05_application`（dm_*） | `{{ ref(...) }}` | `04_intermediate` の `t_*` モデル | `{{ ref('t_customer_order_monthly') }}` |

> **NG例：** `prep_orders.sql` で `{{ source('olist_raw', 'orders') }}` を使うのは違反。
> `01_import` をスキップしてローデータを直接参照することになり、01層のクレンジング・型変換が無効化される。

---

## 5. クレンジング設計方針（02_preprocess）（要件定義より）

| 対象 | 対応方針 |
|---|---|
| NULL値 | カラムの性質に応じて `COALESCE` / `IFNULL` / そのまま保持を選択 |
| 型の不整合 | `SAFE_CAST` で変換、失敗は NULL として扱う |
| 表記揺れ | `TRIM` + `LOWER` で正規化、または CASE文・マスタJOINで対応 |
| 重複レコード | `ROW_NUMBER() QUALIFY = 1` で排除 |
| 日付フォーマット不統一 | `PARSE_DATE` / `PARSE_TIMESTAMP` で統一 |
| IDのゼロ落ち | CAST前に STRING として保持 |
