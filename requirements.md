# EC データ分析基盤 要件定義書

> **プロジェクト名:** EC Data Platform  
> **データソース:** Brazilian E-Commerce Public Dataset by Olist  
> **最終更新:** 2026-03

---

## 1. プロジェクト概要

### 目的
- ローデータ（CSV）を投入するだけで、データ基盤構築・可視化・ドキュメント生成まで一気通貫で完結するワークフローを構築する
- ベストプラクティスに基づいたデータ分析基盤のポートフォリオ・提案資料として活用する

### ゴールイメージ
```
ローデータCSV投入
　↓ ① データ調査・ドキュメント自動生成
　↓ ② GATE 5層構造に基づくBigQuery基盤構築（dbt管理）
　↓ ③ Looker Studio サマリダッシュボード
　↓ ④ テーブル定義書・ダッシュボードドキュメントをGitHub / Notionに自動生成
```

---

## 2. 使用データ

### Brazilian E-Commerce Public Dataset by Olist

| テーブル | レコード数 | 内容 |
|---|---|---|
| orders | 約99,000件 | 注文ヘッダー |
| order_items | 約112,000件 | 注文明細 |
| customers | 約99,000件 | 顧客情報 |
| products | 約32,000件 | 商品マスタ |
| sellers | 約3,000件 | 販売者マスタ |
| order_reviews | 約99,000件 | レビュー |
| order_payments | 約103,000件 | 支払情報 |
| geolocation | 約100万件 | 郵便番号×緯度経度 |
| product_category | 約70件 | カテゴリ翻訳マスタ |

- **期間:** 2016〜2018年（約2年分）
- **ファイルサイズ:** 全体約100MB
- **取得元:** Kaggle（パブリックデータセット、利用制限なし）

---

## 3. システム構成

### 全体アーキテクチャ

```
[ローデータCSV]
　↓
[GCS - Cloud Storage]  ← ステージングバケット
　↓
[BigQuery] ← dbt で変換・管理（GATE 5層構造）
　↓
[Looker Studio] ← ダッシュボード
　↓
[GitHub] ← コード管理 / ドキュメント（Markdown）
[Notion]  ← ドキュメント（人が読むUI層）
```

### 使用技術スタック

| 用途 | 技術 |
|---|---|
| データ基盤 | BigQuery（GCP） |
| ストレージ | Cloud Storage（GCS） |
| 変換・管理 | dbt Core |
| CI/CD | GitHub Actions |
| コード管理 | GitHub |
| 可視化 | Looker Studio |
| ドキュメント | GitHub（Markdown）+ Notion（MCP連携） |

### GCPプロジェクト
- 既存アカウント（my first project）を使用
- 新規GCPプロジェクトを作成して開発・運用する

---

## 4. データ基盤設計（GATE フレームワーク）

### レイヤー構成

| レイヤー | フォルダ名 | 役割 |
|---|---|---|
| INPUT層 | `01_import` | GCSからBigQueryへのローデータ取り込み。スキーマ定義・ロードコマンド管理 |
| DWH層 | `02_preprocess` | クレンジング・表記揺れ対応・計算カラム追加 |
| DM層（統合） | `03_unification` | トランザクション×マスタの統合テーブル生成 |
| DM層（集計） | `04_intermediate` | 分析粒度ごとの中間テーブル（一次・二次属性） |
| DM層（分析） | `05_application` | 可視化・Looker Studio向けの最終テーブル |

### 03_unification（統合テーブル）設計方針
- `orders` × `order_items` × `customers` × `products` × `sellers` × `order_payments` × `order_reviews` をJOINした統合トランザクションテーブルを作成
- `03_unification` と `05_application` を基本とし、JOINとWHEREのみで構成
- LEFT OUTER JOINを基本とし、RIGHT JOINは使用禁止

### 04_intermediate（中間テーブル）設計方針

> テーブル設計の型・命名規約・KPI指標設計・検算パターンなどの設計思想は **[docs/DATA_MART_DESIGN.md](./DATA_MART_DESIGN.md)** を参照。

**役割:** `unf_order_items`（明細粒度）を分析軸ごとに集計し、「分析基礎の確定集計」を提供する。

#### 作成テーブル一覧

| テーブル名 | 粒度（1行の意味） | 分析用途 |
|---|---|---|
| `t_order_kpi_monthly` | 月次（全体KPI） | 売上・AOV・APV・新規/リピーター率 |
| `t_customer_monthly` | 顧客 × 月 | 月次RFM・主カテゴリ |
| `t_customer_all` | 顧客（全期間） | LTV・RFMプロファイル |
| `t_customer_category_all` | 顧客 × カテゴリ | クロスセル・カテゴリアフィニティ |
| `t_cohort_monthly` | コホート × 月 | リテンション率・コホート売上 |
| `t_category_monthly` | カテゴリ × 月 | カテゴリ別トレンド・シェア |
| `t_product_monthly` | 商品 × 月 | 売れ筋・商品ライフサイクル |
| `t_seller_monthly` | 販売者 × 月 | 販売者別パフォーマンス |
| `t_seller_all` | 販売者（全期間） | 販売者プロファイル |
| `t_state_monthly` | 州 × 月 | 地域別トレンド・ヒートマップ |
| `t_delivery_monthly` | 月次（配送KPI） | 配送日数・オンタイム率・レビュー相関 |

> 詳細なカラム定義・SQL設計は **[docs/EC-7_requirements.md](./EC-7_requirements.md)** を参照。

> **注意:** `sum_payment_value` は注文単位集約済みのため、order_item_id粒度で集計すると重複する。明細金額の集計には `price` + `freight_value` を使う。

### 05_application（分析テーブル）設計方針
- Looker Studio向けに横持ち・フラグ化・集計を最適化したテーブルを配置
- `04_intermediate` を主ソースとし、明細ドリルダウンのみ `03_unification` を参照する
- **1ページ1マート原則** — ダッシュボードの各ページに対応するテーブルを用意し、Looker Studio側でのJOIN・集計を排除する
- 詳細設計は **[docs/EC-8_requirements.md](./EC-8_requirements.md)** を参照

---

## 5. SQLコーディング規約

以下を全レイヤーで統一して適用する。

- **予約語は大文字、テーブル名・カラム名は小文字・snake_case**
- **`SELECT *` 禁止** → カラムを明示
- **`GROUP BY` は列名明示**（番号指定禁止）
- **`RIGHT OUTER JOIN` 禁止** → `LEFT OUTER JOIN` に統一
- **IDはSTRING型**、日付はDATE/TIMESTAMP型、フラグはBOOL型
- **WITH句を優先**（サブクエリのネスト多用禁止）
- **ゼロ除算対策:** `SAFE_DIVIDE` または `NULLIF(分母, 0)`
- **NULL安全:** `NOT IN (subquery)` 禁止 → `NOT EXISTS` を使用
- **日付範囲:** BETWEEN禁止 → 半開区間（`>= AND <`）を使用
- **`QUALIFY`の積極利用:** RANK後の1位抽出に使用

### カラム命名プレフィックス

| プレフィックス | 意味 |
|---|---|
| `sum_` | 合計 |
| `cnt_` | 件数 |
| `first_` | 最初の値 |
| `latest_` | 最後の値 |
| `is_` | フラグ（BOOL） |
| `has_` | 存在フラグ |
| `main_` | 代表値（最頻/最大） |
| `list_` | 一覧文字列 |
| `rate_` / `per_` | 比率・割合 |

> 中間テーブルのSQL実装パターン・検算テンプレートは **[docs/DATA_MART_DESIGN.md](./DATA_MART_DESIGN.md)** を参照。

---

## 6. クレンジング設計（02_preprocess）

ケースバイケースで対応。基本ルールは以下：

| 対象 | 対応方針 |
|---|---|
| NULL値 | カラムの性質に応じて `COALESCE` / `IFNULL` / そのまま保持を選択 |
| 型の不整合 | `SAFE_CAST` で変換、失敗はNULLとして扱う |
| 表記揺れ | CASE文またはマスタテーブルとのJOINで正規化 |
| 重複レコード | `ROW_NUMBER() QUALIFY = 1` で排除 |
| 日付フォーマット不統一 | `PARSE_DATE` / `PARSE_TIMESTAMP` で統一 |
| IDのゼロ落ち | CAST前にSTRINGとして保持 |

---

## 7. dbt プロジェクト構成

```
ec_data_platform/
├── dbt_project.yml
├── profiles.yml
├── models/
│   ├── 01_import/
│   ├── 02_preprocess/
│   ├── 03_unification/
│   ├── 04_intermediate/
│   └── 05_application/
├── tests/
│   └── （検算クエリ）
├── docs/
│   └── （テーブル定義Markdown）
└── .github/
    └── workflows/
        └── dbt_run.yml
```

### GitHub Actions 設定方針
- `main`ブランチへのpushをトリガーに `dbt run` + `dbt test` を自動実行
- BigQuery接続情報はGitHub Secretsで管理
- 将来的にスケジュール実行（cron）に対応できる構成にする

### GitHub Actions 必須設定（初回セットアップ時）

詳細は **[docs/SETUP.md](./docs/SETUP.md)** を参照。

**GitHub Secrets（2つ必須）**

| Secret名 | 値 | 設定場所 |
|---|---|---|
| `DBT_BQ_PROJECT` | `ec-data-platform-2026` | Settings → Secrets → Actions |
| `GOOGLE_CREDENTIALS_JSON` | サービスアカウントJSONの中身 | 同上 |

**サービスアカウント作成コマンド（gcloud CLI）**

```bash
# サービスアカウント作成
gcloud iam service-accounts create github-actions-dbt \
  --display-name="GitHub Actions dbt" \
  --project=ec-data-platform-2026

# 権限付与
gcloud projects add-iam-policy-binding ec-data-platform-2026 \
  --member="serviceAccount:github-actions-dbt@ec-data-platform-2026.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding ec-data-platform-2026 \
  --member="serviceAccount:github-actions-dbt@ec-data-platform-2026.iam.gserviceaccount.com" \
  --role="roles/bigquery.jobUser"

# キー生成
gcloud iam service-accounts keys create /tmp/github-actions-dbt-key.json \
  --iam-account=github-actions-dbt@ec-data-platform-2026.iam.gserviceaccount.com

# GitHub Secretsに登録（gh CLI）
gh secret set GOOGLE_CREDENTIALS_JSON < /tmp/github-actions-dbt-key.json
gh secret set DBT_BQ_PROJECT --body "ec-data-platform-2026"
```

### CI設計方針：01_import は永続レイヤー

`01_import` の生テーブル（`orders`, `order_items` など）は `load_to_bq.sh` で一度ロードしたら**削除しない**。CIはこれらが存在することを前提とし、変換ロジック（`02_preprocess` 以降）のみ再実行する。

```
# CI が実行するコマンド
dbt run  --select 02_preprocess+
dbt test --select 02_preprocess+

# 01_import は実行しない（生テーブルへのVIEWなので再実行不要）
```

**注意：01_import の生テーブルを削除すると `src_*` VIEWが壊れ、CI含め全層が動かなくなる。**

---

## 8. ダッシュボード設計（Looker Studio）

### デザイン方針
- **白背景ベースのミニマルデザイン**
- 使用コンポーネント：KPIカード・時系列折れ線グラフ・ドーナツ円グラフ・表（ランキング）
- チャートの種類はケースバイケースで選択（指標の性質に合わせる）
- 参考：GA4サマリーレポートのレイアウト（カード列 → 時系列 → セグメント別ドーナツ+表の2カラム）

### フェーズ1：サマリダッシュボード（初回スコープ）

1ページ構成のサマリダッシュボード。以下の指標を含む：

| セクション | 指標 |
|---|---|
| 売上サマリ | 総売上・総注文数・平均注文単価 |
| 時系列トレンド | 月次売上推移・注文数推移 |
| 年次比較 | 年次売上・成長率 |
| 顧客サマリ | ユニーク顧客数・新規/リピート比率 |
| 商品サマリ | カテゴリ別売上Top10 |
| 地域サマリ | 州別注文数ヒートマップ（ブラジル） |

### フェーズ2以降（運用フェーズで追加）
- 顧客セグメント分析ページ（RFMセグメント）
- 商品カテゴリ詳細ページ
- 地域別詳細ページ
- レビュー・満足度分析ページ

---

## 9. ドキュメント設計

### GitHubに配置（Markdown）
- `docs/table_definitions/` 配下にテーブルごとのMarkdownを自動生成
- スキーマ・データ型・粒度・行数・欠損情報・概要を記載

### Notionに配置（MCP連携）

**Notion ワークスペース構成（提案）:**

```
📁 EC Data Platform（親ページ）
　├── 📄 プロジェクト概要
　├── 📄 ローデータ調査レポート
　├── 🗄️ テーブル定義書DB（テーブル名・層・粒度・説明・更新日）
　├── 🗄️ ダッシュボードドキュメントDB（ページ名・指標・データソース）
　└── 🗄️ チケット管理DB（タスク・ステータス・優先度・担当・期日）
```

### ドキュメント管理方針
- Claudeで一元生成・メンテナンス
- GitHub（Markdown）が正とし、Notionは人が読むUI層として同期

---

## 10. 初回スコープ（フェーズ1）

| # | タスク | 成果物 |
|---|---|---|
| 1 | GCPプロジェクト・GCS・BigQuery初期設定 | セットアップドキュメント |
| 2 | Olistデータ調査 | ローデータ調査レポート（Markdown + Notion） |
| 3 | dbtプロジェクト初期化・GitHub連携 | GitHubリポジトリ |
| 4 | 01_import: ローデータをBQに取り込み | ロードスクリプト・スキーマ定義 |
| 5 | 02_preprocess: クレンジング | dbt models |
| 6 | 03_unification: 統合テーブル作成 | dbt models |
| 7 | 04_intermediate: 中間テーブル作成 | dbt models |
| 8 | 05_application: 分析テーブル作成 | dbt models |
| 9 | GitHub Actions設定 | CI/CDパイプライン |
| 10 | Looker Studioサマリダッシュボード作成 | ダッシュボード |
| 11 | テーブル定義書生成 | Markdown + Notion |
| 12 | ダッシュボードドキュメント生成 | Notion |

---

## 11. 将来フェーズ（フェーズ2以降）

- 定期データ更新フロー（新規CSVの差分取り込み・BQ MERGE）
- ダッシュボード追加（顧客セグメント・カテゴリ詳細・地域詳細）
- メンバー共有・権限管理フロー
- 分析インサイトのGmail自動送信フロー（Gmail MCP連携）
- Cloud Schedulerによるスケジュール実行

---

## 12. 未決事項・TODO

- [ ] Notionワークスペース構成の確定（親ページ名・DB設計）
- [ ] Looker StudioのGCPアカウント連携確認
- [ ] dbt Cloudを使うか dbt Core + GitHub Actionsのみかの最終確認（→ GitHub Actionsで確定）
- [ ] GCPプロジェクト名の決定
