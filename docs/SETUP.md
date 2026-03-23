# 環境構築ガイド

> このドキュメントは初回セットアップ手順と、環境構築で判明したハマりポイントをまとめたもの。
> 2026-03に実際の構築作業から得た知見を反映している。

---

## 前提条件

- GCPアカウント・プロジェクト（`ec-data-platform-2026`）作成済み
- `gcloud` CLI インストール済み
- `gh` CLI インストール済み（GitHub CLI）
- Python 3.12+、dbt-bigquery インストール済み

---

## 1. ローカル開発環境セットアップ

### 1-1. Python仮想環境 & dbtインストール

```bash
cd ec-data-platform
python3 -m venv .venv
source .venv/bin/activate
pip install -r ec_data_platform/requirements.txt
```

### 1-2. GCP認証（ローカルdbt用）

```bash
gcloud auth application-default login
gcloud config set project ec-data-platform-2026
```

> **ポイント：** ローカルの dbt は `gcloud auth application-default login` による
> ADC（Application Default Credentials）で認証する。
> サービスアカウントキーは不要。

### 1-3. dbt接続確認

```bash
cd ec_data_platform
DBT_BQ_PROJECT=ec-data-platform-2026 dbt debug
```

---

## 2. BigQueryデータセット初期セットアップ（EC-4: 初回のみ）

### 2-1. ローデータのBQロード

```bash
cd ec_data_platform
bash scripts/load_to_bq.sh
```

> **重要：`01_import` の生テーブルは削除しない**
>
> `load_to_bq.sh` が作成する生テーブル（`orders`, `order_items` など）は
> `src_*` VIEW の参照先。削除すると全層のdbt実行が壊れる。
> データはGCSにもバックアップされているため、誤って削除した場合は再実行する。

### 2-2. BQリージョン

すべてのデータセットは **`asia-northeast1`（東京）** に作成されている。
クエリやdbtのprofiles.ymlで `location` を指定する際は必ずこのリージョンを使う。

```yaml
# profiles.yml
location: asia-northeast1  # ← US や asia-northeast2 は不可
```

---

## 3. GitHub Actions CI/CD セットアップ（初回のみ）

### 3-1. サービスアカウント作成

GitHub ActionsはADCが使えないため、専用のサービスアカウントが必要。

```bash
# サービスアカウント作成
gcloud iam service-accounts create github-actions-dbt \
  --display-name="GitHub Actions dbt" \
  --project=ec-data-platform-2026

# 権限付与（BigQueryデータ編集 + ジョブ実行）
gcloud projects add-iam-policy-binding ec-data-platform-2026 \
  --member="serviceAccount:github-actions-dbt@ec-data-platform-2026.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding ec-data-platform-2026 \
  --member="serviceAccount:github-actions-dbt@ec-data-platform-2026.iam.gserviceaccount.com" \
  --role="roles/bigquery.jobUser"

# JSONキー生成
gcloud iam service-accounts keys create /tmp/github-actions-dbt-key.json \
  --iam-account=github-actions-dbt@ec-data-platform-2026.iam.gserviceaccount.com \
  --project=ec-data-platform-2026
```

### 3-2. GitHub Secretsに登録

```bash
# gh CLI で登録（リポジトリのSettings → Secrets → Actionsに保存される）
gh secret set GOOGLE_CREDENTIALS_JSON < /tmp/github-actions-dbt-key.json \
  --repo torimimasataka/ec-data-platform

gh secret set DBT_BQ_PROJECT --body "ec-data-platform-2026" \
  --repo torimimasataka/ec-data-platform

# 確認
gh secret list --repo torimimasataka/ec-data-platform
```

| Secret名 | 値 |
|---|---|
| `GOOGLE_CREDENTIALS_JSON` | サービスアカウントJSONの中身（全文） |
| `DBT_BQ_PROJECT` | `ec-data-platform-2026` |

> **ポイント：** シークレットが設定されていないと、ワークフローは即座に失敗する（6秒で落ちる）。
> `gh secret list` で確認できるのはシークレット名のみ（値は確認不可）。

### 3-3. ワークフローファイルの場所

GitHub Actionsのワークフローは **リポジトリルートの `.github/workflows/`** に置く必要がある。
サブディレクトリ（例：`ec_data_platform/.github/workflows/`）には置いても動かない。

```
ec-data-platform/              ← リポジトリルート
  .github/
    workflows/
      dbt_run.yml              ← ここに置く（動く）
  ec_data_platform/
    .github/                   ← ここに置いても動かない
```

---

## 4. CI設計の考え方

### なぜ `02_preprocess+` のみ実行するのか

```
01_import  → 生テーブル（bq load で作成、永続）+ src_* VIEW（dbt管理）
02_preprocess+ → 変換ロジック（dbt管理、CIで毎回再実行）
```

CIの目的は「変換ロジックが壊れていないか検証すること」。
`01_import` の生テーブルは静的なデータであり、CIが触るべきものではない。

```yaml
# .github/workflows/dbt_run.yml
- name: dbt run
  working-directory: ec_data_platform
  run: dbt run --target prod --select 02_preprocess+

- name: dbt test
  working-directory: ec_data_platform
  run: dbt test --target prod --select 02_preprocess+
```

---

## 5. ハマりポイントまとめ

| 症状 | 原因 | 対処 |
|---|---|---|
| CIが6秒で失敗 | GitHub Secretsが未設定 | `gh secret set` で2つ設定 |
| `requirements.txt not found` エラー | `cache: pip` があるのに `requirements.txt` がない | `ec_data_platform/requirements.txt` を作成 |
| `Dataset not found in location US` | profiles.yml の location が `US` になっている | `asia-northeast1` に修正 |
| `Table 01_import.orders was not found` | 生テーブルが削除されている | `load_to_bq.sh` を再実行 |
| ワークフローが起動しない | `.github/workflows/` がリポジトリルートにない | ルートの `.github/workflows/` に移動 |
| ローカルではdbt動くがCIで動かない | ローカルはADC、CIはサービスアカウントが必要 | 3節のサービスアカウント設定を実施 |
