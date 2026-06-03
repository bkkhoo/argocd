#!/bin/bash
set -euo pipefail

BACKUP_PATH=/home/core/backups

echo "starting backup at $(date '+%F %T %Z') ..."
chroot /host sudo -E /usr/local/bin/cluster-backup.sh "${BACKUP_PATH}"

echo -e "\ncompressing snapshot db..."
gzip -9 /host/${BACKUP_PATH}/*.db

echo -e "\ntransferring backup files..."
mv -v /host/${BACKUP_PATH}/*.db.gz ${SNAPSHOT_DB_BACKUP_PATH}
mv -v /host/${BACKUP_PATH}/*.tar.gz ${STATIC_RESOURCES_BACKUP_PATH}

echo -e "\nremoving old backup files..."
find ${SNAPSHOT_DB_BACKUP_PATH} -type f -mtime "+${BACKUP_RETENTION_DAYS}" | xargs rm -rf
find ${STATIC_RESOURCES_BACKUP_PATH} -type f -mtime "+${BACKUP_RETENTION_DAYS}" | xargs rm -rf

echo -e "\nlist snapshot db backups"
ls -lh ${SNAPSHOT_DB_BACKUP_PATH} | grep snapsho
echo -e "\nlist static resources backups"
ls -lh ${STATIC_RESOURCES_BACKUP_PATH} | grep static_kuberesources
echo -e "\nbackup completed at $(date '+%F %T %Z')"
