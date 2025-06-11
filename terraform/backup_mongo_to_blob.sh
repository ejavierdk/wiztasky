#!/usr/bin/env bash
set -euo pipefail

# Variables
STORAGE_ACCOUNT="tfwizstoragejavierlab"
CONTAINER_NAME="backups"

# Timestamp for this run
TS=$(date +%Y%m%d%H%M)
DUMP_DIR="/tmp/mongodump/backup-all-mongodb-${TS}"
ARCHIVE_PATH="${DUMP_DIR}.gz"

echo "Starting full MongoDB backup at ${TS}"
mongodump --gzip --archive="${ARCHIVE_PATH}"

echo "Logging in via managed identity..."
az login --identity

echo "Uploading backup to storage account ${STORAGE_ACCOUNT}, container ${CONTAINER_NAME}"
az storage blob upload \
  --auth-mode login \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$CONTAINER_NAME" \
  --name "backup-all-mongodb-${TS}.gz" \
  --file "$ARCHIVE_PATH"

echo "Backup upload complete at $(date +%Y%m%d%H%M)"
