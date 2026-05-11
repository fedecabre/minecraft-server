#!/usr/bin/env bash
set -euo pipefail

# Minecraft Server Backup Script
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BACKUP_DIR="$SCRIPT_DIR/docker/backups"
WORLD_DIR="$SCRIPT_DIR/minecraft-data"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="minecraft_backup_${DATE}.tar.gz"

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$WORLD_DIR" world world_nether world_the_end

# Keep only last 7 backups
find "$BACKUP_DIR" -name '*.tar.gz' -printf '%T@ %p\n' | sort -rn | tail -n +8 | cut -d' ' -f2- | xargs -r rm --

echo "Backup created: $BACKUP_DIR/$BACKUP_NAME"
echo "Size: $(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)"
