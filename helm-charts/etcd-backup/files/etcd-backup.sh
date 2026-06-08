#!/bin/bash

BACKUP_PATH=/home/core/backups
CLUSTER_OPERATOR_PATTERN="True"
ENCRYPTION_PATTERN="EncryptionCompleted"
MAX_ATTEMPTS=180       # would result in waiting up to ~15min for cluster to be ready

attempt=0
echo  "Waiting for etcd encryption and cluster operators update/reconciliation to complete..."
while [ ${attempt} -lt ${MAX_ATTEMPTS} ]; do
  output1="$(oc get co -o=jsonpath='{range .items[*].status.conditions[?(@.type=="Progressing")]}{.status}{","}')"
  output2="$(oc get openshiftapiserver cluster -o=jsonpath='{range .status.conditions[?(@.type=="Encrypted")]}{.reason}' | grep $ENCRYPTION_PATTERN)"
  if [[ ! "${output1}" =~ "${CLUSTER_OPERATOR_PATTERN}" ]] && [[ "${output2}" == "${ENCRYPTION_PATTERN}" ]]; then
    break
  fi
  attempt=$((attempt + 1))
  echo "Attempt ${attempt}: cluster not ready, waiting..."
  sleep 5
done

set -euo pipefail    # fail script if any command of pipeline failed

echo -e "\nstarting backup at $(date '+%F %T %Z') ..."
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
