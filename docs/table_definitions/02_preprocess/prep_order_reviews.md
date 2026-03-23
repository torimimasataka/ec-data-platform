# テーブル定義書：prep_order_reviews

| 項目 | 値 |
|---|---|
| **論理名** | 注文レビュー |
| **物理名** | `ec-data-platform-2026.02_preprocess.prep_order_reviews` |
| **ソースファイル** | `olist_order_reviews_dataset.csv` |
| **粒度** | 1行 = 1注文に対する1レビュー（review_id + order_id の複合で識別） |
| **行数** | 99,224件 |
| **層** | 02_preprocess（クレンジング済み） |
| **更新方法** | `bq load --replace`（全件洗い替え） |
| **最終更新日** | 2026-03-21 |

---

## カラム定義

| カラム名 | BQ型 | モード | ユニーク数 | NULL数 | NULL率 | 説明 |
|---|---|---|---|---|---|---|
| `review_id` | STRING | REQUIRED | 98,410 | 0 | 0.0% | レビューID（重複814件あり） |
| `order_id` | STRING | REQUIRED | 98,673 | 0 | 0.0% | 注文ID（FK → orders） |
| `review_score` | INTEGER | NULLABLE | 5 | 0 | 0.0% | レビュースコア（1〜5点） |
| `review_comment_title` | STRING | NULLABLE | 4,527 | 87,656 | 88.3% | レビュータイトル（任意） |
| `review_comment_message` | STRING | NULLABLE | 36,159 | 58,247 | 58.7% | レビュー本文（任意） |
| `review_creation_date` | TIMESTAMP | NULLABLE | 636 | 0 | 0.0% | レビュー作成日時 |
| `review_answer_timestamp` | TIMESTAMP | NULLABLE | 98,248 | 0 | 0.0% | 回答タイムスタンプ |

---

## review_score 分布

| スコア | 件数 | 割合 | 評価 |
|---|---|---|---|
| 5 | 57,328 | 57.8% | 非常に良い |
| 4 | 19,142 | 19.3% | 良い |
| 3 | 8,179 | 8.2% | 普通 |
| 2 | 3,151 | 3.2% | 悪い |
| 1 | 11,424 | 11.5% | 非常に悪い |

> スコア5が約58%を占める一方、スコア1も11.5%と高め → 満足度の二極化傾向あり

---

## 特記事項・クレンジング方針

| # | 対象カラム | 内容 | 方針 |
|---|---|---|---|
| 1 | `review_id` | ユニーク数98,410 vs 行数99,224 → **814件の重複** | 02_preprocess で `ROW_NUMBER() OVER(PARTITION BY review_id ORDER BY review_answer_timestamp DESC) QUALIFY = 1` で排除 |
| 2 | `review_comment_title` | 88.3% NULL（任意項目） | そのまま保持 |
| 3 | `review_comment_message` | 58.7% NULL（任意項目） | そのまま保持 |
| 4 | `order_id` | ユニーク数98,673 vs orders99,441 → 768件にレビューなし | LEFT JOINで保持 |

---

## テーブル間リレーション

```
prep_order_reviews.order_id → prep_orders.order_id（多:1）
```
