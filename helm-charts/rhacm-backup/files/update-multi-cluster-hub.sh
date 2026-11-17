#!/usr/bin/env bash

# SUBSCRIPTION_SOURCE=redhat-operators
# SUBSCRIPTION_SOURCE_NAMESPACE=openshift-marketplace
# SUBSCRIPTION_CHANNEL=stable
# INSTALL_PLAN_APPROVAL=Automatic
MAX_ATTEMPTS=60

echo "update MultiClusterHub resource to enable cluster-backup"
cat <<EOF | oc apply --filename -
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  name: multiclusterhub
  namespace: open-cluster-management
  annotations:
    installer.open-cluster-management.io/oadp-subscription-spec: "{\"source\": \"${SUBSCRIPTION_SOURCE}\",\"sourceNamespace\": \"${SUBSCRIPTION_SOURCE_NAMESPACE}\",\"channel\": \"${SUBSCRIPTION_CHANNEL}\",\"installPlanApproval\": \"${INSTALL_PLAN_APPROVAL}\"}"
spec:
  overrides:
    components:
      - name: cluster-backup
        enabled: true
        configOverrides: {}
EOF

csv_succeeded=0
attempt=0
exit_status=1
echo  "Waiting for OADP operator installation..."
while [ "${exit_status}" -ne 0 ] && [ "${attempt}" -lt "${MAX_ATTEMPTS}" ]; do
  attempt=$((attempt + 1))
  oc --namespace open-cluster-management-backup get clusterserviceversion | grep -E 'oadp-operator.*Succeeded' &> /dev/null
  exit_status=$?
  if [ "${exit_status}" -eq 0 ]; then
    csv_succeeded=1
    break
  else
    echo "Attempt ${attempt}: OADP operator installation not complete yet, waiting..."
    sleep 3
  fi
done

if [ "${csv_succeeded}" -eq 1 ]; then
  echo "MultiClusterHub's cluster-backup enabled, and OADP operator deployment completed"
  exit 0
else
  echo "The OADP operator deployment did not complete within the specified time"
  exit 1
fi
