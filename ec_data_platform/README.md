# ec_data_platform

Brazilian E-Commerce (Olist) データ分析基盤 — dbt プロジェクト

## アーキテクチャ（GATE 5層構造）

```
01_import       → GCSからBQへのローデータ取り込み（スキーマ定義）
02_preprocess   → クレンジング・型変換・表記揺れ対応
03_unification  → トランザクション×マスタ統合テーブル
04_intermediate → 分析粒度ごとの中間テーブル（顧客×月、カテゴリ×月 等）
05_application  → Looker Studio向け最終テーブル
```

## セットアップ

### 1. 仮想環境 & dbt インストール

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install dbt-bigquery==1.11.1
```

### 2. GCP 認証（ローカル開発）

```bash
gcloud auth application-default login
export DBT_BQ_PROJECT=<your-gcp-project-id>
```

### 3. dbt パッケージインストール

```bash
dbt deps
```

### 4. 接続確認

```bash
dbt debug
```

### 5. 実行

```bash
dbt run        # 全モデル実行
dbt test       # テスト実行
dbt docs serve # ドキュメント確認
```

## GitHub Actions

`main` ブランチへの push で自動的に `dbt run` + `dbt test` が実行されます。

### 必要な GitHub Secrets

| Secret名 | 内容 |
|---|---|
| `DBT_BQ_PROJECT` | GCPプロジェクトID |
| `GOOGLE_CREDENTIALS_JSON` | サービスアカウントキー（JSON）の中身 |

## SQLコーディング規約

- 予約語は大文字、テーブル名・カラム名は小文字 snake_case
- `SELECT *` 禁止
- `RIGHT JOIN` 禁止（`LEFT JOIN` に統一）
- `SAFE_DIVIDE` でゼロ除算対策
- WITH句を優先（サブクエリのネスト禁止）
