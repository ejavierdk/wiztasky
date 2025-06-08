#!/bin/bash

# Variables
TIMESTAMP=$(date +"%Y%m%d%H%M")
BACKUP_NAME="backup-all-mongodb-$TIMESTAMP"
BACKUP_DIR="/tmp/mongodump"
ARCHIVE_FILE="/tmp/${BACKUP_NAME}.tar.gz"
MONGO_URI="mongodb://wizuser:Sk0le0st@10.0.0.4:27017/?authSource=admin"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting full MongoDB backup at $TIMESTAMP"

# Run mongodump without specifying a database to dump all databases
mongodump --uri="$MONGO_URI" --out "$BACKUP_DIR/$BACKUP_NAME"
if [ $? -ne 0 ]; then
  echo "MongoDB dump failed"
  exit 1
fi

# Compress the dump folder into a single tar.gz archive
tar -czf "$ARCHIVE_FILE" -C "$BACKUP_DIR" "$BACKUP_NAME"
if [ $? -ne 0 ]; then
  echo "Compression failed"
  exit 1
fi

# Upload only the compressed archive to Azure Blob Storage
az storage blob upload \
  --account-name wizstoragejavierlab \
  --account-key "3HdBksRuhkHoKr16DXVkhUnu+DOTuqMxVknGnCkWGQxqhvdOciOA3AySXZODqOmFQqUmihfYe39W+AStDD6g8w==" \
  --container-name backups \
  --file "$ARCHIVE_FILE" \
  --name "$(basename "$ARCHIVE_FILE")"

if [ $? -eq 0 ]; then
  echo "Backup and upload completed successfully."
else
  echo "Backup upload failed."
  exit 1
fi

# Cleanup local dump and archive files
rm -rf "$BACKUP_DIR/$BACKUP_NAME"
rm -f "$ARCHIVE_FILE"
