# テーブル定義書：app_cross_monthly

| 項目 | 値 |
|---|---|
| **論理名** | カテゴリ×州×月クロス集計 |
| **物理名** | `ec-data-platform-2026.05_application.app_cross_monthly` |
| **参照元** | `unf_order_items`（03_unification） |
| **粒度** | 1行 = 1カテゴリ × 1州 × 1年月 |
| **対象** | order_status = 'delivered'、カテゴリ・州 NOT NULL |
| **行数** | 11,393件 |
| **層** | 05_application（Streamlit ユニバーサルスライサー用） |
| **更新方法** | `dbt run --select app_cross_monthly` |
| **最終更新日** | 2026-03-27 |

### 概要

Streamlit ダッシュボードのユニバーサルスライサー（カテゴリ×州の同時フィルター）を実現するために作成したクロステーブル。カテゴリを選択したとき「州 Top10」を正しく絞り込む、または州を選択したとき「カテゴリ Top10」を絞り込む場合に使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `product_category_name_english` | STRING | NULLABLE | 商品カテゴリ名（英語） |
| `customer_state` | STRING | NULLABLE | 州コード（例: SP, RJ） |
| `state_name_en` | STRING | NULLABLE | 州名（英語フルネーム）。スライサー選択肢と一致させるため dbt 側で JOIN 済み |
| `year_month` | STRING | NULLABLE | 年月文字列（YYYY-MM形式） |
| `order_month` | TIMESTAMP | NULLABLE | 月初日（UTC付きタイムスタンプ）。**⚠️ Streamlit クエリでは `DATE(order_month)` キャスト必須** |
| `sum_price_month` | FLOAT64 | NULLABLE | 月次売上合計（BRL） |
| `cnt_orders_month` | INTEGER | NULLABLE | 月次注文件数 |
| `cnt_unique_customers_month` | INTEGER | NULLABLE | 月次ユニーク顧客数 |

---

## 特記事項・注意点

| # | 内容 |
|---|---|
| 1 | **`order_month` は TIMESTAMP（UTC）型**。`app_summary_kpi` の DATE 型と `.isin()` 比較すると全行 False になる。Streamlit の `bigquery.py` では `DATE(order_month)` でキャストして読み込むこと |
| 2 | **`state_name_en` はアクセント付き**（`Amapá`, `Ceará`, `Goiás` 等）。`app_geo_summary` も同じ値に統一済み。新規に州名マッピングを書く場合はこのテーブルの UNNEST リストを正として参照すること |
| 3 | カテゴリ × 州の組み合わせが存在する行のみ（注文が1件もない組み合わせは行なし） |
