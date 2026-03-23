# テーブル定義書：prep_product_category_name_translation

| 項目 | 値 |
|---|---|
| **論理名** | 商品カテゴリ翻訳マスタ |
| **物理名** | `ec-data-platform-2026.02_preprocess.prep_product_category_name_translation` |
| **ソースファイル** | `product_category_name_translation.csv` |
| **粒度** | 1行 = 1カテゴリの翻訳ペア（product_category_name が PK） |
| **行数** | 71件 |
| **層** | 02_preprocess（クレンジング済み） |
| **更新方法** | `bq load --replace`（全件洗い替え） |
| **最終更新日** | 2026-03-21 |

---

## カラム定義

| カラム名 | BQ型 | モード | ユニーク数 | NULL数 | NULL率 | 説明 |
|---|---|---|---|---|---|---|
| `product_category_name` | STRING | REQUIRED | 71 | 0 | 0.0% | カテゴリ名（ポルトガル語・PK） |
| `product_category_name_english` | STRING | NULLABLE | 71 | 0 | 0.0% | カテゴリ名（英語） |

---

## 特記事項

| # | 内容 | 対応 |
|---|---|---|
| 1 | ソースCSVがBOM付きUTF-8 | `load_to_bq.sh` でPythonによりBOMを除去してからロード |
| 2 | productsのカテゴリ数（73種）との差異 | 2件のカテゴリがこのマスタに未登録 → 03_unification でLEFT JOINし、未登録は `'unknown'` |
| 3 | 71件のみ（超小規模マスタ） | シードデータ（`dbt seed`）での管理も検討可 |

---

## テーブル間リレーション

```
prep_product_category_name_translation.product_category_name ← prep_products.product_category_name（1:多）
```
