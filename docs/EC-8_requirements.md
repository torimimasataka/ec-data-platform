# EC-8: 05_application 設計書（ダッシュボード向けデータマート）

> **対象レイヤー:** `05_application`
> **作成日:** 2026-03
> **ステータス:** 完了（11テーブル実装済み）
> **依存レイヤー:** `03_unification`（明細粒度）、`04_intermediate`（集計粒度）

---

## 設計思想

### なぜ05_applicationが必要か

よくあるアンチパターン：

```
03_unification（明細粒度・全カラム）
　└── Streamlit で全ページを直接クエリ
　　　→ 毎回JOINと集計が走り、計算コスト増・描画が重くなる
```

今回のベストプラクティス：

```
04_intermediate（集計済み・軽量）
　└── 05_application（ページ特化マート）
　　　└── Streamlit（集計不要・高速）

03_unification（明細粒度）
　└── 05_application（日次・時間帯・ドリルダウン専用マート）
　　　└── Streamlit（詳細ページのみ）
```

### レイヤー別の役割分担

| レイヤー | 粒度 | Streamlitからの接続 |
|---|---|---|
| `03_unification` | 明細（1行=1注文明細） | ❌ 直接接続しない |
| `04_intermediate` | 集計（月次・顧客・カテゴリ等） | ❌ 直接接続しない |
| `05_application` | ページ最適化済み | ✅ ここだけ接続する |

### 05_applicationの設計原則

1. **1ページ1マート** — Streamlit の各ページに対応するテーブルを1つ用意する
2. **Python側で集計させない** — GROUP BY・JOIN・計算をBigQueryで完結させる
3. **必要カラムのみ** — `SELECT *` 禁止、ページで使うカラムだけを渡す
4. **サマリ系は04から継承** — `04_intermediate` の集計テーブルをそのまま活用
5. **日次・時間帯・ドリルダウンは03から直接集計** — `03_unification.unf_order_items` を参照

---

## ダッシュボード構成と対応マート（実装済み）

```
Page 1: サマリ（概況）              ← app_summary_kpi
                                    ← app_category_customer_kpi（カテゴリフィルター時の顧客KPI）
                                    ← app_state_customer_kpi   （州フィルター時の顧客KPI）
                                    ← app_cross_monthly        （カテゴリ×州 同時フィルター時）
Page 2: 売上・トレンド分析          ← app_sales_trend
Page 3: 顧客分析（RFMセグメント）   ← app_customer_rfm
Page 4: 顧客分析（コホートリテンション） ← app_cohort_retention
Page 5: 商品・カテゴリ分析          ← app_category_performance
Page 6: 地域分析                   ← app_geo_summary
Page 7: 配送・品質分析              ← app_delivery_quality
Page 8: 注文明細（ドリルダウン）    ← app_order_detail
Page 9: 日次トレンド分析            ← app_daily_kpi
Page 10: カテゴリ別日次時系列       ← app_daily_category
Page 11: 時間帯・曜日分析（ヒートマップ） ← app_hourly_kpi
```

---

## テーブル一覧まとめ

| テーブル名 | ダッシュボードページ | ソース | 粒度 | 行数（概算） |
|---|---|---|---|---|
| `app_summary_kpi` | サマリ（概況） | `t_order_kpi_monthly` | 月次 | 23行 |
| `app_sales_trend` | 売上・トレンド分析 | `t_category_monthly` | カテゴリ × 月次 | 1,200行 |
| `app_customer_rfm` | 顧客分析（RFM） | `t_customer_all` | 顧客 | 93,400行 |
| `app_cohort_retention` | 顧客分析（コホート） | `t_cohort_monthly` | コホート × 月次 | 219行 |
| `app_category_performance` | 商品・カテゴリ分析 | `t_category_monthly` | カテゴリ × 月次 | 1,200行 |
| `app_geo_summary` | 地域分析 | `t_state_monthly` | 州 × 月次 | 556行 |
| `app_delivery_quality` | 配送・品質分析 | `t_delivery_monthly` | 月次 | 23行 |
| `app_order_detail` | 注文明細（ドリルダウン） | `unf_order_items` | 注文明細 | 110,200行 |
| `app_daily_kpi` | 日次トレンド分析 | `unf_order_items` | 日次 | 612行 |
| `app_daily_category` | カテゴリ別日次時系列 | `unf_order_items` | カテゴリ × 日次 | 18,800行 |
| `app_hourly_kpi` | 時間帯・曜日分析 | `unf_order_items` | 時間帯 × 曜日 | 168行 |
| `app_category_customer_kpi` | サマリ補助（カテゴリフィルター時） | `unf_order_items` | カテゴリ × 月次 | 1,200行 |
| `app_state_customer_kpi` | サマリ補助（州フィルター時） | `unf_order_items` | 州 × 月次 | 556行 |
| `app_cross_monthly` | サマリ補助（カテゴリ×州 同時フィルター時） | `unf_order_items` | カテゴリ × 州 × 月次 | 〜18,000行 |

---

## 主要な実装ポイント

### BigQuery WINDOW関数の活用

| 指標 | WINDOW関数 | 対象テーブル |
|---|---|---|
| YTD（年累計） | `SUM() OVER (PARTITION BY year ORDER BY month ROWS UNBOUNDED PRECEDING)` | `app_summary_kpi` |
| 前年同月比（YoY） | `LAG(sum_price, 12) OVER (PARTITION BY category ORDER BY month)` | `app_sales_trend` |
| 月次ランキング | `RANK() OVER (PARTITION BY month ORDER BY revenue DESC)` | `app_category_performance` |
| 7日移動平均 | `AVG(revenue) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` | `app_daily_kpi`, `app_daily_category` |
| 30日移動平均 | `AVG(revenue) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)` | `app_daily_kpi` |
| ヒートマップ正規化 | `SAFE_DIVIDE(val - MIN() OVER(), MAX() OVER() - MIN() OVER())` | `app_hourly_kpi` |

### QUALIFY ROW_NUMBER() によるgeolocation重複排除

`unf_order_items` のgeolocation JOINが多対1のため明細が重複する。
`app_order_detail` では以下で排除：

```sql
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY order_id, order_item_id
    ORDER BY order_purchase_timestamp
) = 1
```

### RFMセグメント定義

R/F/Mスコアをそれぞれ1〜4点（NTILE(4)）で計算し、合計スコア（3〜12）に基づき7セグメントに分類：

| セグメント | 条件 |
|---|---|
| Champions | rfm_total_score >= 10 |
| Loyal | rfm_total_score >= 8 |
| Promising | rfm_r_score >= 3 AND rfm_total_score >= 6 |
| Need Attention | rfm_r_score >= 2 AND rfm_total_score >= 5 |
| At Risk | rfm_r_score <= 2 AND rfm_total_score >= 5 |
| Cannot Lose | rfm_r_score = 1 AND rfm_f_score >= 3 |
| Hibernating | それ以外 |

### ブラジル州 ISO コードマッピング

`app_geo_summary` でジオマップ用に `BR-SP` 形式に変換。
`t_state_monthly` の2文字州コード（`SP`）に `BR-` プレフィックスを付与：

```sql
CONCAT('BR-', customer_state) AS state_code_iso
```

---

## データフロー全体図

```
03_unification
  └── unf_order_items ──┬──────────────────────────────────────► app_order_detail
                        ├──────────────────────────────────────► app_daily_kpi
                        ├──────────────────────────────────────► app_daily_category
                        └──────────────────────────────────────► app_hourly_kpi

04_intermediate
  ├── t_order_kpi_monthly ───────────────────────────────────────► app_summary_kpi
  ├── t_category_monthly ────────────────────────────────────────► app_sales_trend
  │                                                                app_category_performance
  ├── t_customer_all ─────────────────────────────────────────────► app_customer_rfm
  ├── t_cohort_monthly ───────────────────────────────────────────► app_cohort_retention
  ├── t_state_monthly ────────────────────────────────────────────► app_geo_summary
  └── t_delivery_monthly ─────────────────────────────────────────► app_delivery_quality
```
