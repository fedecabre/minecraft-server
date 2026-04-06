#!/bin/bash

# Minecraft Server Backup Script
# This script creates compressed backups of the Minecraft world data

BACKUP_DIR="./docker/backups"
WORLD_DIR="./minecraft-data"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="minecraft_backup_${DATE}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create compressed backup
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$WORLD_DIR" world world_nether world_the_end

# Keep only last 7 backups (optional cleanup)
cd "$BACKUP_DIR"
ls -t *.tar.gz | tail -n +8 | xargs -r rm --

echo "Backup created: $BACKUP_DIR/$BACKUP_NAME"
echo "Backup size: $(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)"