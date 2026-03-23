# EC-9: GitHub Actions CI/CDパイプライン設計書

> **対象レイヤー:** インフラ
> **作成日:** 2026-03
> **ステータス:** 完了
> **対象ファイル:** `.github/workflows/dbt_run.yml`

---

## 概要

mainブランチへのpushをトリガーに `dbt run + dbt test` を自動実行するGitHub Actionsパイプラインを設定した。BigQuery接続情報はGitHub Secretsで管理し、ローカルに認証情報を持たない安全な構成にしている。

---

## なぜCI/CDが必要なのか

手動で `dbt run` を実行するだけでは以下の問題が起きる：

- コードをpushしても変換テーブルに反映されない
- テストを忘れてバグが本番に混入する可能性がある
- 誰がいつ実行したかの記録が残らない

GitHub ActionsでCIを組むことで、**mainへのマージ = 自動的にBigQueryへ反映 + テスト実行** となり、常にコードとデータが同期した状態を保てる。

---

## パイプライン構成

### トリガー

| トリガー | 内容 |
|---|---|
| `push: branches: [main]` | mainブランチへのpush時に自動実行 |
| `schedule`（コメントアウト中） | 将来的な定期実行用に`cron: '0 1 * * *'`（JST 10:00）を準備済み |

### ジョブ: `dbt-run`

| ステップ | 内容 |
|---|---|
| Checkout | リポジトリをチェックアウト（actions/checkout@v4） |
| Set up Python | Python 3.12をセットアップ。`cache: pip`で依存関係をキャッシュ |
| Install dbt-bigquery | `dbt-bigquery==1.11.1` をインストール |
| Write Google credentials | GitHub Secrets の `GOOGLE_CREDENTIALS_JSON` を `/tmp/google_credentials.json` に書き出す |
| Set up dbt profiles | `~/.dbt/profiles.yml` を動的生成。接続先: `dbt_prod` dataset、`asia-northeast1` |
| dbt deps | パッケージ（dbt-utils等）をインストール |
| dbt run | `02_preprocess+`（02以降の全レイヤー）を実行 |
| dbt test | `02_preprocess+` のテストを実行 |
| dbt docs generate | mainブランチのみdocを生成 |

### 実行スコープ：なぜ `02_preprocess+` か

```
01_import     → bq loadで取り込んだ永続的な生テーブルを参照するVIEW層
                CIで再実行する必要がない（生データは変わらない）

02_preprocess+ → 変換ロジックが入る層
                コードが変わったら再ビルドが必要 ← ここだけCIで実行
```

---

## GitHub Secrets 設定

| Secret名 | 内容 |
|---|---|
| `DBT_BQ_PROJECT` | BigQueryプロジェクトID（例: `ec-data-platform-2026`） |
| `GOOGLE_CREDENTIALS_JSON` | BigQueryサービスアカウントのJSONキー（全文） |

---

## セキュリティ設計

- 認証情報はすべてGitHub Secretsで管理。リポジトリ上にJSONキーを置かない
- Google credentialsは `/tmp/google_credentials.json` に一時書き出し（ジョブ終了後に自動削除）
- `dbt_prod` datasetに書き込む権限のみを持つサービスアカウントを使用

---

## ファイル構成

```
.github/
└── workflows/
    └── dbt_run.yml    ← CI/CDパイプライン本体
```
