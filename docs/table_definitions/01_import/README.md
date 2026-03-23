# テーブル定義書：01_import 層

> **BQデータセット:** `ec-data-platform-2026.01_import`
> **更新日:** 2026-03-21
> **ステータス:** ロード完了（全9テーブル・計1,550,921件）

GCSからBigQueryへロードしたローデータテーブル群。このデータをそのまま参照するのではなく、`02_preprocess` 以降でクレンジング・変換して使用する。

---

## テーブル一覧

| テーブル名 | 論理名 | 粒度 | 行数 | 定義書 |
|---|---|---|---|---|
| `src_orders` | 注文ヘッダー | 1注文 | 99,441 | [src_orders.md](./src_orders.md) |
| `src_order_items` | 注文明細 | 1注文×1商品 | 112,650 | [src_order_items.md](./src_order_items.md) |
| `src_customers` | 顧客情報 | 1注文×1顧客 | 99,441 | [src_customers.md](./src_customers.md) |
| `src_products` | 商品マスタ | 1商品 | 32,951 | [src_products.md](./src_products.md) |
| `src_sellers` | 販売者マスタ | 1販売者 | 3,095 | [src_sellers.md](./src_sellers.md) |
| `src_order_reviews` | 注文レビュー | 1注文×1レビュー | 99,224 | [src_order_reviews.md](./src_order_reviews.md) |
| `src_order_payments` | 支払情報 | 1注文×1支払方法 | 103,886 | [src_order_payments.md](./src_order_payments.md) |
| `src_geolocation` | 位置情報 | 1郵便番号×1座標 | 1,000,163 | [src_geolocation.md](./src_geolocation.md) |
| `src_product_category_name_translation` | カテゴリ翻訳マスタ | 1カテゴリ | 71 | [src_product_category_name_translation.md](./src_product_category_name_translation.md) |
| **合計** | | | **1,550,921** | |

---

## テーブル間リレーション

```
customers (1) ──────────────── (N) orders
                                      │
                      ┌───────────────┼───────────────┐
                      │               │               │
               (N) order_items  (N) order_reviews  (N) order_payments
                      │
               (N) products ── product_category_name_translation
               (N) sellers

customers.customer_zip_code_prefix ┐
sellers.seller_zip_code_prefix     ┘ → geolocation.geolocation_zip_code_prefix
```

---

## 02_preprocess での主なクレンジング対象

| # | テーブル | 問題 | 方針 |
|---|---|---|---|
| 1 | `products` | 610件のNULL（カテゴリ等） | `COALESCE(..., 'unknown')` |
| 2 | `order_reviews` | 814件の重複 | `ROW_NUMBER() QUALIFY = 1` |
| 3 | `order_payments` | `not_defined` 3件 | `'unknown'` に変換 |
| 4 | `geolocation` | 1郵便番号に複数座標 | `AVG(lat/lng)` で集約 |
| 5 | `customers` / `sellers` | `city` の表記揺れ | 正規化 |
