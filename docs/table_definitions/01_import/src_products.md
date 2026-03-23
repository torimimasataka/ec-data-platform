# テーブル定義書：src_products

| 項目 | 値 |
|---|---|
| **論理名** | 商品マスタ |
| **物理名** | `ec-data-platform-2026.01_import.src_products` |
| **ソースファイル** | `olist_products_dataset.csv` |
| **粒度** | 1行 = 1商品（product_id が PK） |
| **行数** | 32,951件 |
| **層** | 01_import（ローデータ） |
| **更新方法** | `bq load --replace`（全件洗い替え） |
| **最終更新日** | 2026-03-21 |

---

## カラム定義

| カラム名 | BQ型 | モード | ユニーク数 | NULL数 | NULL率 | 説明 |
|---|---|---|---|---|---|---|
| `product_id` | STRING | REQUIRED | 32,951 | 0 | 0.0% | 商品ID（PK） |
| `product_category_name` | STRING | NULLABLE | 73 | 610 | 1.9% | カテゴリ名（ポルトガル語） |
| `product_name_lenght` | INTEGER | NULLABLE | 66 | 610 | 1.9% | 商品名文字数（※スペルミス: lenght） |
| `product_description_lenght` | INTEGER | NULLABLE | 2,960 | 610 | 1.9% | 説明文字数（※スペルミス: lenght） |
| `product_photos_qty` | INTEGER | NULLABLE | 19 | 610 | 1.9% | 商品写真枚数 |
| `product_weight_g` | FLOAT64 | NULLABLE | 2,204 | 2 | 0.0% | 重量（g） |
| `product_length_cm` | FLOAT64 | NULLABLE | 99 | 2 | 0.0% | 梱包長さ（cm） |
| `product_height_cm` | FLOAT64 | NULLABLE | 102 | 2 | 0.0% | 梱包高さ（cm） |
| `product_width_cm` | FLOAT64 | NULLABLE | 95 | 2 | 0.0% | 梱包幅（cm） |

---

## product_category_name 上位5カテゴリ

| カテゴリ（ポルトガル語） | 英語 | 商品数 |
|---|---|---|
| cama_mesa_banho | bed_bath_table | 3,029 |
| esporte_lazer | sports_leisure | 2,867 |
| moveis_decoracao | furniture_decor | 2,657 |
| beleza_saude | health_beauty | 2,444 |
| utilidades_domesticas | housewares | 2,335 |

---

## 特記事項・クレンジング方針

| # | 対象カラム | 内容 | 方針 |
|---|---|---|---|
| 1 | `product_category_name` 等 | 610件が一括NULL（データ欠損） | `COALESCE(..., 'unknown')` で補完 |
| 2 | `product_name_lenght` / `product_description_lenght` | カラム名のスペルミス（正: length） | ソースのまま保持。02_preprocess で正規化カラム名にエイリアス |
| 3 | `product_category_name` | 73種 vs 翻訳マスタ71種 → 2件がマスタ未登録 | `product_category_name_translation` とLEFT JOINしてNULL → `'unknown'` |

---

## テーブル間リレーション

```
src_products.product_id          ← src_order_items.product_id              （1:多）
src_products.product_category_name → src_product_category_name_translation.product_category_name（多:1）
```
