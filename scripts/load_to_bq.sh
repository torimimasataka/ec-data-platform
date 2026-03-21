#!/bin/bash
# =============================================================================
# EC Data Platform - ローデータ BQ ロードスクリプト
# GCS へ CSV をアップロード → BigQuery の 01_import データセットに取り込む
#
# 使い方:
#   chmod +x scripts/load_to_bq.sh
#   ./scripts/load_to_bq.sh
#
# 事前条件:
#   - gcloud auth login 済み
#   - gcloud config set project ec-data-platform-2026 済み
# =============================================================================

set -euo pipefail

# ── 設定 ────────────────────────────────────────────────────────────────────
PROJECT_ID="ec-data-platform-2026"
GCS_BUCKET="gs://ec-data-platform-raw"
BQ_DATASET="${PROJECT_ID}:01_import"
RAW_DIR="$(cd "$(dirname "$0")/../.." && pwd)/data/raw"  # ec-data-platform/data/raw/
SCHEMA_DIR="$(cd "$(dirname "$0")" && pwd)/schemas"
LOCATION="asia-northeast1"

echo "========================================"
echo " EC Data Platform - BQ Load Script"
echo "  Project : ${PROJECT_ID}"
echo "  Bucket  : ${GCS_BUCKET}"
echo "  Dataset : 01_import"
echo "========================================"

# ── Step 1: GCS にアップロード ──────────────────────────────────────────────
echo ""
echo "[Step 1] Uploading CSVs to GCS..."
gsutil -m cp "${RAW_DIR}"/*.csv "${GCS_BUCKET}/raw/"
echo "  ✓ Upload complete"

# ── Step 2: BQ にロード（テーブルごと）──────────────────────────────────────
echo ""
echo "[Step 2] Loading tables into BigQuery (01_import)..."

# テーブル定義: "BQテーブル名 GCSファイル名 スキーマファイル名 エンコーディング"
declare -a TABLES=(
  "orders                           olist_orders_dataset.csv                      orders.json                          UTF-8"
  "order_items                      olist_order_items_dataset.csv                 order_items.json                     UTF-8"
  "customers                        olist_customers_dataset.csv                   customers.json                       UTF-8"
  "products                         olist_products_dataset.csv                    products.json                        UTF-8"
  "sellers                          olist_sellers_dataset.csv                     sellers.json                         UTF-8"
  "order_reviews                    olist_order_reviews_dataset.csv               order_reviews.json                   UTF-8"
  "order_payments                   olist_order_payments_dataset.csv              order_payments.json                  UTF-8"
  "geolocation                      olist_geolocation_dataset.csv                 geolocation.json                     UTF-8"
  "product_category_name_translation product_category_name_translation.csv        product_category_name_translation.json UTF-8-BOM"
)

for entry in "${TABLES[@]}"; do
  read -r TABLE_NAME CSV_FILE SCHEMA_FILE ENCODING <<< "${entry}"

  echo ""
  echo "  Loading: ${TABLE_NAME}"
  bq load \
    --project_id="${PROJECT_ID}" \
    --location="${LOCATION}" \
    --source_format=CSV \
    --skip_leading_rows=1 \
    --allow_quoted_newlines \
    --allow_jagged_rows \
    --encoding="${ENCODING}" \
    --replace \
    "${BQ_DATASET}.${TABLE_NAME}" \
    "${GCS_BUCKET}/raw/${CSV_FILE}" \
    "${SCHEMA_DIR}/${SCHEMA_FILE}"

  echo "  ✓ ${TABLE_NAME} loaded"
done

# ── Step 3: 件数確認 ─────────────────────────────────────────────────────────
echo ""
echo "[Step 3] Row count verification..."

declare -a CHECK_TABLES=(
  "orders"
  "order_items"
  "customers"
  "products"
  "sellers"
  "order_reviews"
  "order_payments"
  "geolocation"
  "product_category_name_translation"
)

for TABLE_NAME in "${CHECK_TABLES[@]}"; do
  COUNT=$(bq query \
    --project_id="${PROJECT_ID}" \
    --use_legacy_sql=false \
    --format=csv \
    --quiet \
    "SELECT COUNT(*) FROM \`${PROJECT_ID}.01_import.${TABLE_NAME}\`" \
    | tail -1)
  printf "  %-45s %s rows\n" "${TABLE_NAME}" "${COUNT}"
done

echo ""
echo "========================================"
echo " ✅ All tables loaded successfully!"
echo "========================================"
