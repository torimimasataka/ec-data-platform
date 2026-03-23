# テーブル定義書：prep_order_payments

| 項目 | 値 |
|---|---|
| **論理名** | 支払情報 |
| **物理名** | `ec-data-platform-2026.02_preprocess.prep_order_payments` |
| **ソースファイル** | `olist_order_payments_dataset.csv` |
| **粒度** | 1行 = 1注文内の1支払方法（order_id + payment_sequential の複合キー） |
| **行数** | 103,886件 |
| **層** | 02_preprocess（クレンジング済み） |
| **更新方法** | `bq load --replace`（全件洗い替え） |
| **最終更新日** | 2026-03-21 |

---

## カラム定義

| カラム名 | BQ型 | モード | ユニーク数 | NULL数 | NULL率 | 説明 |
|---|---|---|---|---|---|---|
| `order_id` | STRING | REQUIRED | 99,440 | 0 | 0.0% | 注文ID（FK → orders） |
| `payment_sequential` | INTEGER | NULLABLE | 29 | 0 | 0.0% | 支払連番（複数支払方法を併用した際の枝番） |
| `payment_type` | STRING | NULLABLE | 5 | 0 | 0.0% | 支払方法（下記参照） |
| `payment_installments` | INTEGER | NULLABLE | 24 | 0 | 0.0% | 分割払い回数（最大24回） |
| `payment_value` | FLOAT64 | NULLABLE | 29,077 | 0 | 0.0% | 支払金額（BRL） |

---

## payment_type 値一覧

| 支払方法 | 件数 | 割合 |
|---|---|---|
| `credit_card` | 76,795 | 73.9% |
| `boleto`（銀行振込） | 19,784 | 19.0% |
| `voucher` | 5,775 | 5.6% |
| `debit_card` | 1,529 | 1.5% |
| `not_defined` | 3 | 0.0% |

---

## 特記事項・クレンジング方針

| # | 対象カラム | 内容 | 方針 |
|---|---|---|---|
| 1 | 行数 | 103,886 > orders 99,441 → 1注文で複数支払方法を併用 | 正常。`payment_sequential` で枝番管理 |
| 2 | `payment_type = 'not_defined'` | 3件の未定義値 | 02_preprocess で `NULL` または `'unknown'` に変換 |
| 3 | `payment_installments` | 最大24回の分割払い | 整数型で保持。分割払いフラグ（`is_installment`）を 02_preprocess で追加 |
| 4 | `order_id` | ユニーク数99,440 vs orders99,441 → 1件に支払なし | LEFT JOINで保持 |

---

## テーブル間リレーション

```
prep_order_payments.order_id → prep_orders.order_id（多:1）
```
