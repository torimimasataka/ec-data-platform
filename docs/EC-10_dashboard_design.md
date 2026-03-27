# EC-10: Streamlit サマリダッシュボード 設計仕様書

> **ステータス:** Page 1 実装完了
> **対象ページ:** Page 1 - サマリ（概況）
> **実装ファイル:** `streamlit_app/app.py` / `streamlit_app/utils/bigquery.py`
> **データソース:** `05_application` レイヤー（下記テーブル一覧参照）

---

## デザイン方針

- **白背景・ミニマルデザイン** — 余白多め、情報密度を抑える
- **カラーパレット:**

| 変数名 | HEX | 用途 |
|---|---|---|
| `orange` | `#E8743B` | プライマリ・強調バー・ピエ |
| `orange_light` | `#F5C6A8` | 非選択バー |
| `orange_pale` | `#FDF0E8` | 背景アクセント |
| `gray_dark` | `#1A1A1A` | テキスト本文 |
| `gray_mid` | `#6B6B6B` | サブテキスト・軸ラベル |
| `gray_light` | `#E8E8E8` | グリッド・非強調バー |
| `gray_bg` | `#F5F5F5` | KPIカード背景 |
| `red` | `#CC3333` | マイナス増減 |
| `green` | `#2E7D32` | プラス増減 |
| `border` | `#DEDEDE` | カード・コンテナ境界線 |

- **PIE_COLORS（ドーナツグラフ用）:** オレンジグラデーション8色 + グレー（Others）
- **フォント:** Helvetica Neue（全コンポーネント統一）
- **レイアウト:** `layout="wide"`、`max-width: 1440px`、`padding: 48px 64px 64px`
- **対象デバイス:** PC表示メイン（モバイル対応不要）
- **Streamlit UI非表示:** MainMenu・footer・header を CSS で `visibility: hidden`

---

## ページレイアウト

```
┌──────────────────────────────────────────────────────────────┐
│  ヘッダー: "EC Sales Dashboard"                               │
│  サブテキスト: "Brazilian e-commerce — Sales overview & trends" │
├──────────────────────────────────────────────────────────────┤
│  スライサーバー（border=True コンテナ）                        │
│  [Period ▼]  [Category (multiselect)]  [State (multiselect)] │
├──────────────────────────────────────────────────────────────┤
│  Section: KEY METRICS                                        │
│  [Revenue] [Orders] [AOV] [Customers] [Repeat Rate] [YTD]   │
├──────────────────────────────────────────────────────────────┤
│  Section: MONTHLY TRENDS                                     │
│  月次売上（棒）+ 注文数（折れ線）複合グラフ（クリックで月選択）  │
├──────────────┬───────────────────────────────────────────────┤
│  Section:    │  Section:                                     │
│  CATEGORY    │  STATE RANKING                                │
│  PERFORMANCE │                                               │
│  Top10横棒   │  Top10横棒                                    │
├──────────────┴───────────────────────────────────────────────┤
│  Section: REVENUE & ORDER SHARE                              │
│  [Category Revenue Share ドーナツ] [State Order Share ドーナツ]│
└──────────────────────────────────────────────────────────────┘
```

---

## データ読み込み設計

- **方針:** 全データを起動時に一括ロード（`@st.cache_data(ttl=3600)`）し、フィルタリングはPython側で実施（BQへの再クエリなし）
- **接続:** `google-cloud-bigquery`、プロジェクト `ec-data-platform-2026`、リージョン `asia-northeast1`

| 関数 | テーブル | 取得カラム |
|---|---|---|
| `load_summary_kpi()` | `app_summary_kpi` | `SELECT *` |
| `load_category_monthly()` | `app_category_performance` | `product_category_name_english`, `order_month`, `sum_price_month`, `cnt_orders_month`, `cnt_unique_customers_month` |
| `load_geo_monthly()` | `app_geo_summary` | `customer_state`, `state_name_en`, `order_month`, `cnt_orders_month`, `sum_price_month`, `cnt_unique_customers_month` |
| `load_category_customer_kpi()` | `app_category_customer_kpi` | `product_category_name_english`, `order_month`, `cnt_unique_customers_month`, `cnt_repeat_customers_month`, `repeat_customer_rate_month` |
| `load_state_customer_kpi()` | `app_state_customer_kpi` + `app_geo_summary`（JOIN） | `customer_state`, `state_name_en`, `order_month`, `cnt_unique_customers_month`, `cnt_repeat_customers_month`, `repeat_customer_rate_month` |
| `load_cross_monthly()` | `app_cross_monthly` | `product_category_name_english`, `customer_state`, `state_name_en`, `DATE(order_month)`, `sum_price_month`, `cnt_orders_month` |

> `app_cross_monthly` はカテゴリ × 州の同時フィルター時に使用するクロステーブル。
> `state_name_en` はテーブル内に直接保持（dbt ビルド時に JOIN 済み）。
> `order_month` は BigQuery 上 TIMESTAMP（UTC）型のため、クエリ側で `DATE()` キャストして `app_summary_kpi`（DATE型）との `.isin()` 比較を正常化している。

---

## フィルター設計

スライサーバーは `st.container(border=True)` 内に `st.columns([2,2,2])` で3列配置。

| フィルター | コンポーネント | オプション | デフォルト |
|---|---|---|---|
| Period | `st.selectbox` | 年別（最新年〜）+ "Last 12 months" / "Last 6 months" / "All time" | 最新年 |
| Category | `st.multiselect` | 全カテゴリ名（英語） | [] = All |
| State | `st.multiselect` | 全州名（`state_name_en`） | [] = All |

### フィルター適用ロジック

| フィルター状態 | トレンドデータソース | カテゴリTop10 | 州Top10 |
|---|---|---|---|
| なし | `df_kpi`（`app_summary_kpi`） | `df_catm` | `df_geom` |
| Category のみ | `df_catm` 集計 | `df_catm` | `df_cross`（カテゴリ絞込み） |
| State のみ | `df_geom` 集計 | `df_cross`（州絞込み） | `df_geom` |
| Category + State | `df_cross` 集計 | `df_cross`（両絞込み） | `df_cross`（両絞込み） |

> Category/State フィルター時はレビュースコアが `NaN`（トレンドグラフの折れ線③は非表示）

---

## スクロール位置保持

リラン時にページトップへ戻る Streamlit デフォルト挙動を抑制するため、`streamlit.components.v1.html` で JavaScript を注入。
`window.parent.sessionStorage` に `ec_scroll` キーでスクロール位置を200ms間隔で保存し、`window.scrollTo` と `scrollTop` setter をオーバーライドして復元。

---

## コンポーネント詳細

### ヘッダー

| 要素 | 実装 |
|---|---|
| タイトル | `EC Sales Dashboard`（28px / 700 / `gray_dark`） |
| サブテキスト | `Brazilian e-commerce — Sales overview & trends`（14px / `gray_mid`） |
| 区切り | 下ボーダー（`1px solid #DEDEDE`） |

---

### KPIカード（6枚 / `st.columns(6)`）

カスタム HTML/CSS で実装（`kpi-card` / `kpi-label` / `kpi-value` クラス）。
カード背景 `#F5F5F5`、角丸 12px、border `1px solid #DEDEDE`。

| # | ラベル | 指標 | 増減比較 | 表示形式 |
|---|---|---|---|---|
| 1 | Monthly Revenue | `sum_price_month` | 前月比 | `fmt_currency`（¥M / ¥K 省略形） |
| 2 | Orders | `cnt_orders_month` | 前月比 | カンマ区切り整数 |
| 3 | Avg Order Value | `sum_price_month / cnt_orders_month` | 前月比 | `¥{aov:,.1f}` |
| 4 | Unique Customers | `cnt_active_customers_month`（フィルター時は補助テーブルで集計） | 前月比（フィルター時はなし） | カンマ区切り整数 |
| 5 | Repeat Rate | `repeat_customer_rate_month`（フィルター時は `cnt_repeat / cnt_unique`） | 前月比（フィルター時はなし） | `{rr*100:.1f}%` |
| 6 | YTD Revenue | 当年1月〜選択月の `sum_price_month` 合計 | なし | `fmt_currency` |

- 増減表示: `▲ X.X% vs prev`（`#2E7D32` 緑）/ `▼ X.X% vs prev`（`#CC3333` 赤）
- 月クリック選択時: 選択月のデータを表示（`sel_month_str` で制御）

---

### 月次トレンドチャート（`make_subplots`）

| 項目 | 設定 |
|---|---|
| チャート種類 | 複合グラフ（棒 + 折れ線） |
| 高さ | 300px |
| 棒（左Y軸） | `sum_price_month` — 選択月: `#E8743B`、非選択月: `#F5C6A8`、bargap=0.35 |
| 折れ線（右Y軸） | `cnt_orders_month` — `#6B6B6B`（グレー）、markers size=4 |
| 左Y軸フォーマット | `tickprefix="¥"`, `tickformat=",.0f"` |
| hovertemplate | `%{x\|%b %Y}<br>Revenue: ¥%{y:,.0f}` / `Orders: %{y:,.0f}` |
| インタラクション | クリックで月選択 → KPIカード・下部チャートに連動。選択時「✕ Clear」ボタン表示 |
| dragmode | `False`（ドラッグ選択無効） |
| ModeBar | 非表示（`displayModeBar: False`） |
| `session_state` | `sel_month_str`（選択月 `YYYY-MM`）、`chart_key_v`（Clear時にキー更新してPlotly選択をリセット） |

> レビュースコア折れ線はカテゴリ/州フィルター時は非表示（`NaN`）。フィルターなし時の表示は未実装・検討中。

---

### カテゴリ Top10 横棒グラフ（左カラム）

| 項目 | 設定 |
|---|---|
| セクションラベル | "CATEGORY PERFORMANCE" |
| チャートタイトル | `Top 10 Categories` + サブ `Revenue · {period}` |
| ディメンション | `product_category_name_english` |
| 指標 | `sum_price_month` の合計（`total_revenue`） |
| 並び順 | 売上降順、上位10件 |
| 色 | 1位: `#E8743B`、2〜10位: `#F5C6A8` |
| テキスト | バー外に `fmt_currency` 表示 |
| 高さ | 380px、右マージン 180px |
| 月ドリルダウン連動 | あり（`sel_month_str` で対象月に絞込み） |
| 州フィルター連動 | あり（`df_cross` 経由） |

---

### 州 Top10 横棒グラフ（右カラム）

| 項目 | 設定 |
|---|---|
| セクションラベル | "STATE RANKING" |
| チャートタイトル | `Top 10 States by Orders` + サブ `Order volume · {period}` |
| ディメンション | `state_name_en`（州の英語フルネーム） |
| 指標 | `cnt_orders_month` の合計（`total_orders`） |
| 並び順 | 注文数降順、上位10件 |
| 色 | 1位: `#E8743B`、2〜10位: `#E8E8E8`（gray_light） |
| テキスト | バー外にカンマ整数表示 |
| 高さ | 380px、右マージン 180px |
| 月ドリルダウン連動 | あり |
| カテゴリフィルター連動 | あり（`df_cross` 経由） |

> ※ Looker Studio 版のジオマップ（Choropleth）は実装しておらず、横棒グラフのランキングに変更。

---

### ドーナツグラフ（Revenue & Order Share）

| 項目 | カテゴリ売上シェア | 州注文シェア |
|---|---|---|
| セクションラベル | "REVENUE & ORDER SHARE" | 同左 |
| チャートタイトル | `Category Revenue Share` | `State Order Share` |
| hole | 0.52 | 0.52 |
| 表示件数 | Top 8 + Others | Top 8 + Others |
| 指標 | `total_revenue` | `total_orders` |
| 色 | `PIE_COLORS`（オレンジグラデーション） | 同左 |
| textinfo | `percent` | `percent` |
| 凡例 | 右側縦並び | 右側縦並び |
| 月・フィルター連動 | あり | あり |

---

## 確定事項・TODO

- [x] カラーパレットをOrangeベースに統一
- [x] スライサーバー（Period / Category / State）
- [x] KPI 6枚（Monthly Revenue / Orders / AOV / Unique Customers / Repeat Rate / YTD）
- [x] 月次トレンド複合グラフ（クリックで月ドリルダウン）
- [x] カテゴリ Top10 横棒グラフ
- [x] 州 Top10 横棒グラフ（Choroplethマップから変更）
- [x] ドーナツグラフ 2枚（カテゴリ売上シェア / 州注文シェア）
- [x] スクロール位置保持（JS注入）
- [x] カテゴリ×州クロスフィルター対応（`app_cross_monthly`）
- [x] ユニバーサルスライサーのバグ修正（クロスフィルター時に相手軸チャートが空白になる問題）
  - 原因1: `app_cross_monthly.order_month` が TIMESTAMP（UTC）型 vs `app_summary_kpi.order_month` が DATE型 → 型不一致で `.isin()` が全 False になりクロステーブルが常に空。`DATE()` キャストで解決。
  - 原因2: `app_geo_summary` と `app_cross_monthly` の `state_name_en` スペル不一致（`Amapa` vs `Amapá` 等）→ `app_geo_summary` 側を `app_cross_monthly` に合わせてアクセント付きに統一し dbt 再ビルド。
- [ ] レビュースコア折れ線（フィルターなし時に表示するか検討中）
