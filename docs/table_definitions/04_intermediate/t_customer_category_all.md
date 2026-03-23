# テーブル定義書：t_customer_category_all

| 項目 | 値 |
|---|---|
| **論理名** | 顧客×カテゴリ全期間クロス集計 |
| **物理名** | `ec-data-platform-2026.04_intermediate.t_customer_category_all` |
| **参照元** | `unf_order_items` |
| **粒度** | 1行 = 1顧客(customer_unique_id) × 1カテゴリ(product_category_name_english)（全期間） |
| **対象** | order_status = 'delivered'、product_category_name_english NOT NULL |
| **行数** | 94,400件 |
| **層** | 04_intermediate（分析基礎の確定集計） |
| **更新方法** | `dbt run --select t_customer_category_all`（全件洗い替え） |
| **最終更新日** | 2026-03-23 |

### 概要

顧客がどのカテゴリをどれだけ購入したかを全期間で集計したクロステーブル。購入金額・件数・顧客全体に対するカテゴリシェア・主カテゴリ判定を確定させる。クロスセル分析・カテゴリアフィニティスコアリング・購入組み合わせ分析の基礎テーブルとして使用する。

---

## カラム定義

| カラム名 | BQ型 | モード | 説明 |
|---|---|---|---|
| `customer_unique_id` | STRING | REQUIRED | 顧客ユニークID（複合PK①） |
| `product_category_name_english` | STRING | REQUIRED | 商品カテゴリ名・英語（複合PK②） |
| `sum_price_cat_all` | FLOAT64 | NULLABLE | カテゴリ内購入金額合計（BRL） |
| `cnt_orders_cat_all` | INTEGER | NULLABLE | カテゴリ内注文件数（DISTINCT order_id） |
| `cnt_order_items_cat_all` | INTEGER | NULLABLE | カテゴリ内明細件数 |
| `first_purchase_ts_cat_all` | TIMESTAMP | NULLABLE | カテゴリ初回購入日時 |
| `latest_purchase_ts_cat_all` | TIMESTAMP | NULLABLE | カテゴリ最終購入日時 |
| `rate_price_cat_in_all` | FLOAT64 | NULLABLE | 顧客の全購入に対するカテゴリシェア（0〜1） |
| `rnk_cat_all` | INTEGER | NULLABLE | 顧客内カテゴリ金額ランク（1=最大） |
| `is_main_category_all` | BOOLEAN | NULLABLE | 主カテゴリ（金額1位 かつ シェア > 50%） |

---

## 特記事項

| # | 内容 |
|---|---|
| 1 | `is_main_category_all` の条件：金額ランク1位 **かつ** シェア > 50%。シェア条件を加えることでカテゴリが分散しているノイズユーザーを除外 |
| 2 | `rnk_cat_all` は `is_main_category_all` の判定に使用するため列として保持。下流でのフィルタリングにも活用可能 |
| 3 | このテーブルと `t_customer_all` を JOIN することで、顧客プロファイル + カテゴリ軸の二次属性分析が可能 |
