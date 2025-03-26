#!/bin/bash

# This script creates a daily backup of important directories.

# Define the source directories to backup
source_dirs=("/Users/leon/Documents" "/Users/leon/Pictures")

# Define the destination directory for the backup
dest_dir="/Volumes/BackupDrive/DailyBackups"

# Define the timestamp format
timestamp=$(date +%Y-%m-%d)

# Define the backup filename
backup_file="backup_${timestamp}.tar.gz"

# Create the destination directory if it doesn't exist
mkdir -p "$dest_dir"

# Create the backup
tar -czvf "$dest_dir/$backup_file" "${source_dirs[@]}"

# Verify the backup
if [ $? -eq 0 ]; then
  echo "Backup created successfully: $dest_dir/$backup_file"
else
  echo "Backup failed."
  exit 1
fi

# Remove backups older than 7 days
find "$dest_dir" -name "backup_*" -type f -mtime +7 -delete

echo "Old backups removed."

exit 0