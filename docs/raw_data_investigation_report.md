# ローデータ調査レポート

> **データセット:** Brazilian E-Commerce Public Dataset by Olist
> **調査日:** 2026-03-19
> **調査対象:** `data/raw/` 配下の全9テーブル

---

## 1. データセット概要

| テーブル論理名 | ファイル名 | 最小粒度（1行の意味） | 行数 | カラム数 | サイズ |
|---|---|---|---|---|---|
| orders（注文ヘッダー） | olist_orders_dataset.csv | 1注文 | 99,441 | 8 | 17,241 KB |
| order_items（注文明細） | olist_order_items_dataset.csv | 1注文内の1商品明細（order_id × order_item_id） | 112,650 | 7 | 15,076 KB |
| customers（顧客） | olist_customers_dataset.csv | 1注文に対する1顧客レコード（customer_idは注文ごと発行） | 99,441 | 5 | 8,822 KB |
| products（商品マスタ） | olist_products_dataset.csv | 1商品 | 32,951 | 9 | 2,323 KB |
| sellers（販売者マスタ） | olist_sellers_dataset.csv | 1販売者 | 3,095 | 4 | 170 KB |
| order_reviews（レビュー） | olist_order_reviews_dataset.csv | 1注文に対する1レビュー（重複あり） | 99,224 | 7 | 14,112 KB |
| order_payments（支払） | olist_order_payments_dataset.csv | 1注文内の1支払方法（order_id × payment_sequential） | 103,886 | 5 | 5,641 KB |
| geolocation（位置情報） | olist_geolocation_dataset.csv | 1郵便番号に対する1座標レコード（重複あり） | 1,000,163 | 5 | 59,837 KB |
| product_category（カテゴリ翻訳） | product_category_name_translation.csv | 1カテゴリの翻訳ペア | 71 | 2 | 2 KB |

- **合計行数:** 約1,550,921行
- **合計サイズ:** 約123,224 KB（約120 MB）
- **期間:** 2016年9月 〜 2018年10月（約2年間）

---

## 2. テーブル別詳細

### 2-1. orders（注文ヘッダー）

**最小粒度:** 1注文（order_id が PK、1行 = 1注文）

| カラム名 | データ型（推定） | ユニーク数 | NULL数 | NULL率 | 備考 |
|---|---|---|---|---|---|
| order_id | STRING | 99,441 | 0 | 0.0% | PK |
| customer_id | STRING | 99,441 | 0 | 0.0% | FK → customers |
| order_status | STRING | 8 | 0 | 0.0% | 下記参照 |
| order_purchase_timestamp | TIMESTAMP | 98,875 | 0 | 0.0% | |
| order_approved_at | TIMESTAMP | 90,733 | 160 | 0.2% | |
| order_delivered_carrier_date | TIMESTAMP | 81,018 | 1,783 | 1.8% | 未配送分のNULL |
| order_delivered_customer_date | TIMESTAMP | 95,664 | 2,965 | 3.0% | 未着分のNULL |
| order_estimated_delivery_date | TIMESTAMP | 459 | 0 | 0.0% | |

**order_status 分布:**

| ステータス | 件数 | 割合 |
|---|---|---|
| delivered | 96,478 | 97.0% |
| shipped | 1,107 | 1.1% |
| canceled | 625 | 0.6% |
| unavailable | 609 | 0.6% |
| invoiced | 314 | 0.3% |
| processing | 301 | 0.3% |
| created | 5 | 0.0% |
| approved | 2 | 0.0% |

**クレンジング方針:**
- `order_delivered_carrier_date`, `order_delivered_customer_date` は未配送・未着の場合にNULL → そのまま保持
- `order_approved_at` のNULL（160件）は `created` / `canceled` / `unavailable` ステータスに起因する可能性が高い → 調査後に判断

---

### 2-2. order_items（注文明細）

**最小粒度:** 1注文 × 1商品明細（order_id + order_item_id の複合キー）

| カラム名 | データ型（推定） | ユニーク数 | NULL数 | NULL率 | 備考 |
|---|---|---|---|---|---|
| order_id | STRING | 98,666 | 0 | 0.0% | FK → orders |
| order_item_id | INTEGER | 21 | 0 | 0.0% | 1始まりの連番（1注文内の商品番号） |
| product_id | STRING | 32,951 | 0 | 0.0% | FK → products |
| seller_id | STRING | 3,095 | 0 | 0.0% | FK → sellers |
| shipping_limit_date | TIMESTAMP | 93,318 | 0 | 0.0% | |
| price | FLOAT | 5,968 | 0 | 0.0% | 商品単価 |
| freight_value | FLOAT | 6,999 | 0 | 0.0% | 送料 |

**備考:**
- `order_item_id` の最大値は21（1注文に最大21品）
- orders（99,441行）に対してorder_items（112,650行）の方が多い → 1注文に複数商品を含む
- orders.order_id（99,441種）とorder_items.order_id（98,666種）に差異あり → orders側に明細なし注文が775件存在

---

### 2-3. customers（顧客）

**最小粒度:** 1注文に対する1顧客レコード（customer_id は注文ごとに発行される仮想ID。実質的な顧客識別は customer_unique_id を使用）

| カラム名 | データ型（推定） | ユニーク数 | NULL数 | NULL率 | 備考 |
|---|---|---|---|---|---|
| customer_id | STRING | 99,441 | 0 | 0.0% | PK（注文ごとに生成される仮想ID） |
| customer_unique_id | STRING | 96,096 | 0 | 0.0% | 実質的な顧客ID（リピート判定に使用） |
| customer_zip_code_prefix | STRING | 14,994 | 0 | 0.0% | 郵便番号（5桁） |
| customer_city | STRING | 4,119 | 0 | 0.0% | 都市名（小文字） |
| customer_state | STRING | 27 | 0 | 0.0% | 州コード（2文字） |

**customer_state 上位5州:**

| 州 | 顧客数 | 割合 |
|---|---|---|
| SP（サンパウロ） | 41,746 | 42.0% |
| RJ（リオデジャネイロ） | 12,852 | 12.9% |
| MG（ミナスジェライス） | 11,635 | 11.7% |
| RS（リオグランデドスル） | 5,466 | 5.5% |
| PR（パラナ） | 5,045 | 5.1% |

**備考:**
- `customer_id`（99,441）> `customer_unique_id`（96,096）→ 3,345件のリピート顧客が存在
- `customer_city` は表記揺れが多い（小文字・アクセント記号の不統一）→ クレンジング対象

---

### 2-4. products（商品マスタ）

**最小粒度:** 1商品（product_id が PK）

| カラム名 | データ型（推定） | ユニーク数 | NULL数 | NULL率 | 備考 |
|---|---|---|---|---|---|
| product_id | STRING | 32,951 | 0 | 0.0% | PK |
| product_category_name | STRING | 73 | 610 | 1.9% | ポルトガル語カテゴリ名 |
| product_name_lenght | INTEGER | 66 | 610 | 1.9% | 商品名文字数（スペルミス） |
| product_description_lenght | INTEGER | 2,960 | 610 | 1.9% | 説明文文字数（スペルミス） |
| product_photos_qty | INTEGER | 19 | 610 | 1.9% | 写真枚数 |
| product_weight_g | INTEGER | 2,204 | 2 | 0.0% | 重量（g） |
| product_length_cm | INTEGER | 99 | 2 | 0.0% | 梱包長さ（cm） |
| product_height_cm | INTEGER | 102 | 2 | 0.0% | 梱包高さ（cm） |
| product_width_cm | INTEGER | 95 | 2 | 0.0% | 梱包幅（cm） |

**product_category 上位5カテゴリ:**

| カテゴリ（ポルトガル語） | 商品数 |
|---|---|
| cama_mesa_banho（寝具・バス） | 3,029 |
| esporte_lazer（スポーツ・レジャー） | 2,867 |
| moveis_decoracao（家具・インテリア） | 2,657 |
| beleza_saude（美容・健康） | 2,444 |
| utilidades_domesticas（家庭用品） | 2,335 |

**備考:**
- `product_category_name` と `product_name_lenght` 等の複数カラムが同時にNULL（610件）→ データ欠損の可能性
- カラム名 `product_name_lenght`, `product_description_lenght` はスペルミス（正: length）→ dbt側でエイリアス対応
- `product_category_name` のカテゴリ数は73種（翻訳マスタは71種）→ 2件の差異を調査要

---

### 2-5. sellers（販売者マスタ）

**最小粒度:** 1販売者（seller_id が PK）

| カラム名 | データ型（推定） | ユニーク数 | NULL数 | NULL率 | 備考 |
|---|---|---|---|---|---|
| seller_id | STRING | 3,095 | 0 | 0.0% | PK |
| seller_zip_code_prefix | STRING | 2,246 | 0 | 0.0% | 郵便番号（5桁） |
| seller_city | STRING | 611 | 0 | 0.0% | 都市名（表記揺れあり） |
| seller_state | STRING | 23 | 0 | 0.0% | 州コード |

**備考:**
- 欠損なし
- `seller_city` は小文字・表記揺れあり → クレンジング対象

---

### 2-6. order_reviews（レビュー）

**最小粒度:** 1注文に対する1レビュー（理論上は order_id が PK だが重複あり。クレンジング後は review_id × order_id が識別子）

| カラム名 | データ型（推定） | ユニーク数 | NULL数 | NULL率 | 備考 |
|---|---|---|---|---|---|
| review_id | STRING | 98,410 | 0 | 0.0% | PK（重複1件あり） |
| order_id | STRING | 98,673 | 0 | 0.0% | FK → orders |
| review_score | INTEGER | 5 | 0 | 0.0% | 1〜5点 |
| review_comment_title | STRING | 4,527 | 87,656 | 88.3% | タイトル（任意項目） |
| review_comment_message | STRING | 36,159 | 58,247 | 58.7% | 本文（任意項目） |
| review_creation_date | TIMESTAMP | 636 | 0 | 0.0% | レビュー作成日 |
| review_answer_timestamp | TIMESTAMP | 98,248 | 0 | 0.0% | 回答タイムスタンプ |

**review_score 分布:**

| スコア | 件数 | 割合 |
|---|---|---|
| 5 | 57,328 | 57.8% |
| 4 | 19,142 | 19.3% |
| 3 | 8,179 | 8.2% |
| 2 | 3,151 | 3.2% |
| 1 | 11,424 | 11.5% |

**備考:**
- `review_comment_title`（88.3% NULL）、`review_comment_message`（58.7% NULL）は任意入力 → そのまま保持
- スコア5が約58%を占める一方、スコア1も11.5%と高め → 購買満足度の二極化
- `review_id` にユニーク数が98,410（行数99,224より少ない）→ 重複レビューが814件 → `ROW_NUMBER() QUALIFY = 1` で排除

---

### 2-7. order_payments（支払情報）

**最小粒度:** 1注文 × 1支払方法（order_id + payment_sequential の複合キー。1注文が複数支払方法に分割される場合あり）

| カラム名 | データ型（推定） | ユニーク数 | NULL数 | NULL率 | 備考 |
|---|---|---|---|---|---|
| order_id | STRING | 99,440 | 0 | 0.0% | FK → orders |
| payment_sequential | INTEGER | 29 | 0 | 0.0% | 支払の連番（複数支払に対応） |
| payment_type | STRING | 5 | 0 | 0.0% | 支払方法 |
| payment_installments | INTEGER | 24 | 0 | 0.0% | 分割回数 |
| payment_value | FLOAT | 29,077 | 0 | 0.0% | 支払金額 |

**payment_type 分布:**

| 支払方法 | 件数 | 割合 |
|---|---|---|
| credit_card | 76,795 | 73.9% |
| boleto（銀行振込） | 19,784 | 19.0% |
| voucher | 5,775 | 5.6% |
| debit_card | 1,529 | 1.5% |
| not_defined | 3 | 0.0% |

**備考:**
- order_payments（103,886行）> orders（99,441行）→ 1注文が複数支払方法を利用している
- `not_defined` が3件 → 02_preprocess でNULL化またはフラグ対応
- `payment_installments` 最大24回（分割払いが最大24ヶ月）

---

### 2-8. geolocation（位置情報）

**最小粒度:** 1郵便番号に対する1座標レコード（1郵便番号に複数行あり。PKなし。分析利用時は郵便番号ごとに AVG で代表座標に集約）

| カラム名 | データ型（推定） | ユニーク数 | NULL数 | NULL率 | 備考 |
|---|---|---|---|---|---|
| geolocation_zip_code_prefix | STRING | 19,015 | 0 | 0.0% | 郵便番号（5桁） |
| geolocation_lat | FLOAT | 717,372 | 0 | 0.0% | 緯度 |
| geolocation_lng | FLOAT | 717,615 | 0 | 0.0% | 経度 |
| geolocation_city | STRING | 8,011 | 0 | 0.0% | 都市名 |
| geolocation_state | STRING | 27 | 0 | 0.0% | 州コード |

**備考:**
- 1郵便番号に複数の緯度経度が紐付く（1,000,163行 vs ユニーク郵便番号19,015件）→ 代表値抽出（AVG or ROW_NUMBER）が必要
- 地域分析での利用時は郵便番号で結合し、`AVG(lat)` / `AVG(lng)` を使用することを推奨

---

### 2-9. product_category（カテゴリ翻訳マスタ）

**最小粒度:** 1カテゴリの翻訳ペア（product_category_name が PK）

| カラム名 | データ型（推定） | ユニーク数 | NULL数 | NULL率 | 備考 |
|---|---|---|---|---|---|
| product_category_name | STRING | 71 | 0 | 0.0% | ポルトガル語カテゴリ名 |
| product_category_name_english | STRING | 71 | 0 | 0.0% | 英語カテゴリ名 |

**備考:**
- BOMあり（UTF-8 BOM）→ 読み込み時に `encoding='utf-8-sig'` で対応
- productsのカテゴリ数（73種）との差異（2件）→ マスタ未登録カテゴリが存在 → 02_preprocess でNULL or 'unknown' 扱い

---

## 3. テーブル間リレーション

```
customers (1) ──── (N) orders
                          │
              ┌───────────┼───────────┐
              │           │           │
         (N) order_items  │    (N) order_reviews
              │      (N) order_payments
         products
         sellers
              │
         product_category（翻訳マスタ）

customers / sellers ──── geolocation（zip_code_prefix で結合）
```

**結合キーの整合性確認:**

| 結合 | 整合状況 |
|---|---|
| orders → customers | orders.customer_id = customers.customer_id（1:1, 完全一致） |
| order_items → orders | 98,666種 vs 99,441件 → 775件のorders側に明細なし |
| order_items → products | 32,951種（完全一致） |
| order_items → sellers | 3,095種（完全一致） |
| order_reviews → orders | 98,673種 vs 99,441件 → 768件のorders側にレビューなし |
| order_payments → orders | 99,440種 vs 99,441件 → 1件のorders側に支払なし |
| products → product_category | 73種 vs 71件 → 2件のカテゴリがマスタ未登録 |

---

## 4. クレンジング要注意項目サマリ

| # | テーブル | 対象カラム | 問題 | 対応方針 |
|---|---|---|---|---|
| 1 | orders | order_delivered_*_date | 未配送・未着のNULL | そのまま保持（業務上の正常NULL） |
| 2 | products | product_category_name等 | 610件のNULL | `COALESCE(..., 'unknown')` |
| 3 | products | product_name_lenght / product_description_lenght | スペルミス（lenght） | dbtで正規化カラム名を使用 |
| 4 | products | product_category_name | 翻訳マスタ未登録2件 | LEFT JOINでNULL → 'unknown' |
| 5 | order_reviews | review_comment_* | 58〜88%のNULL | 任意項目のためそのまま保持 |
| 6 | order_reviews | review_id | 814件の重複 | `ROW_NUMBER() QUALIFY = 1` で排除 |
| 7 | order_payments | payment_type = 'not_defined' | 3件の未定義 | NULLまたは'unknown'に変換 |
| 8 | geolocation | lat/lng | 1郵便番号に複数座標 | `AVG(lat)`, `AVG(lng)` で代表値 |
| 9 | customers / sellers | city | 小文字・表記揺れ | `LOWER(TRIM())` で正規化 |
| 10 | product_category | product_category_name | BOM付きUTF-8 | BQロード時に自動除去 |

---

## 5. BigQueryロード設計メモ

| テーブル | パーティション | クラスタリング | 備考 |
|---|---|---|---|
| orders | order_purchase_timestamp | order_status | 時系列分析の主テーブル |
| order_items | なし | order_id, product_id | orders経由でパーティション参照 |
| customers | なし | customer_state | 地域分析用 |
| products | なし | product_category_name | カテゴリ分析用 |
| sellers | なし | seller_state | 小テーブルのためなし |
| order_reviews | review_creation_date | review_score | レビュー時系列分析 |
| order_payments | なし | payment_type | 支払分析用 |
| geolocation | なし | geolocation_state | 大テーブル（100万件）、使用時はzip_codeで集計 |
| product_category | なし | なし | 71行の小マスタ |

---

*このレポートはClaude Code（claude-sonnet-4-6）により自動生成されました。*
