#!/usr/bin/env bash

MAX_ATTEMPTS=10

# NAMESPACE=openshift-logging
# OBC_CONFIGMAP=loki-s3-bucket-obc
# OBC_SECRET==loki-s3-bucket-obc
# S3_BUCKET_SECRET=loki-s3-bucket

command1="oc -n ${NAMESPACE} get configmap ${OBC_CONFIGMAP}"
command2="oc -n ${NAMESPACE} get secret ${OBC_SECRET}"

continue=0
attempt=0
echo  "Waiting for ObjectBucketClaim ConfigMap ${OBC_CONFIGMAP} and secret ${OBC_SECRET}..."
while [ ${attempt} -lt ${MAX_ATTEMPTS} ]; do
  if $command1 &> /dev/null && $command2 &> /dev/null; then
    continue=1
    break
  else
    attempt=$((attempt + 1))
    echo "Attempt ${attempt}: ObjectBucketClaim ConfigMap (${OBC_CONFIGMAP}) and/or Secret ${OBC_SECRET} not available, waiting..."
    sleep 3
  fi
done

set -euo pipefail    # fail script if any command or pipeline failed

if [ "${continue}" -eq 1 ]; then
  # a bit inefficient getting each property individually, but its simpler, and sync hook does not run frequently
  bucket_name="$(oc -n ${NAMESPACE} get configmap ${OBC_CONFIGMAP} -o jsonpath='{.data.BUCKET_NAME}')"
  bucket_host="$(oc -n ${NAMESPACE} get configmap ${OBC_CONFIGMAP} -o jsonpath='{.data.BUCKET_HOST}')"
  bucket_port="$(oc -n ${NAMESPACE} get configmap ${OBC_CONFIGMAP} -o jsonpath='{.data.BUCKET_PORT}')"
  access_key_id="$(oc -n ${NAMESPACE} extract secret/${OBC_SECRET} --to=- --keys=AWS_ACCESS_KEY_ID 2> /dev/null)"
  access_key_secret="$(oc -n ${NAMESPACE} extract secret/${OBC_SECRET} --to=- --keys=AWS_SECRET_ACCESS_KEY 2> /dev/null)"
  set +e
  oc -n ${NAMESPACE} delete secret ${S3_BUCKET_SECRET} &> /dev/null
  set -e
  oc -n ${NAMESPACE} create secret generic ${S3_BUCKET_SECRET} -o yaml --dry-run=client \
    --from-literal=bucketnames=${bucket_name} \
    --from-literal=endpoint="https://${bucket_host}:${bucket_port}" \
    --from-literal=region="" \
    --from-literal=access_key_id=${access_key_id} \
    --from-literal=access_key_secret=${access_key_secret} \
    | oc apply -f -
else
  echo "Failed: ObjectBucketClaim configMap and secret do not exist"
  exit 1
fi
