#!/usr/bin/env bash

NAMESPACE="open-cluster-management-observability"
OBC_CONFIGMAP="observability-rhacm-s3-obc"
OBC_SECRET="observability-rhacm-s3-obc"
THANOS_OBJECT_STORAGE_SECRET="observability-rhacm-s3"
INSECURE_SKIP_VERIFY="false"
CA_CONFIGMAP="openshift-service-ca.crt"
CA_KEY="service-ca.crt"
OBJECT_STORAGE_CA_SECRET="object-storage-ca"

MAX_ATTEMPTS=10

command1="oc -n ${NAMESPACE} get configmap ${OBC_CONFIGMAP}"
command2="oc -n ${NAMESPACE} get secret ${OBC_SECRET}"

continue=0
attempt=0
echo  "Waiting for ObjectBucketClaim ConfigMap ${OBC_CONFIGMAP} and secret ${OBC_SECRET}..."
while [ ${attempt} -lt ${MAX_ATTEMPTS} ]; do
  if $command1 &> /dev/null && $command2 &> /dev/null; then
  # if $command1 && $command2; then
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
  modified_ca_key="${CA_KEY//./\\.}"      # escape . character
  object_storage_ca="$(oc -n ${NAMESPACE} get configmap ${CA_CONFIGMAP} -o jsonpath={.data[\'${modified_ca_key}\']} | base64 -w0)"
  set +e
  oc -n ${NAMESPACE} delete secret ${OBJECT_STORAGE_CA_SECRET} &> /dev/null
  oc -n ${NAMESPACE} delete secret ${THANOS_OBJECT_STORAGE_SECRET} &> /dev/null
  set -e
  cat << EOF | oc apply -f -
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: ${OBJECT_STORAGE_CA_SECRET}
  namespace: ${NAMESPACE}
data:
  ca.crt: ${object_storage_ca}
EOF
  cat << EOF | oc apply -f -
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: ${THANOS_OBJECT_STORAGE_SECRET}
  namespace: ${NAMESPACE}
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket: ${bucket_name}
      endpoint: ${bucket_host}:${bucket_port}
      insecure: ${INSECURE_SKIP_VERIFY}
      access_key: ${access_key_id}
      secret_key: ${access_key_secret}
      http_config:
        tls_config:
          ca_file: /etc/s3-buckets/certs/ca.crt
          insecure_skip_verify: ${INSECURE_SKIP_VERIFY}
EOF
else
  echo "Failed: ObjectBucketClaim configMap and secret do not exist"
  exit 1
fi
