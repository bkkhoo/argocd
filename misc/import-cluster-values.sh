: << 'COMMENT'
./misc/import-cluster-values.sh dev-hub01 yes > /tmp/values-dev-hub01.yaml
./misc/import-cluster-values.sh prod-hub01 yes > /tmp/values-prod-hub01.yaml
./misc/import-cluster-values.sh prod-cluster01 > /tmp/values-prod-cluster01.yaml
./misc/import-cluster-values.sh prod-cluster02 > /tmp/values-prod-cluster02.yaml

helm template helm-charts/rhacm-import-cluster/ --values /tmp/values-dev-hub01.yaml | oc apply -f -
helm template helm-charts/rhacm-import-cluster/ --values /tmp/values-prod-hub01.yaml | oc apply -f -
helm template helm-charts/rhacm-import-cluster/ --values /tmp/values-prod-cluster01.yaml | oc apply -f -
helm template helm-charts/rhacm-import-cluster/ --values /tmp/values-prod-cluster02.yaml | oc apply -f -

COMMENT

cluster_name=${1}
managed_cluster=${2}
env="${cluster_name%%-*}"

echo "clusterName: $cluster_name"
echo "clusterURL: $(oc whoami --show-server)"
echo "clusterAuthToken: $(oc whoami --show-token)"
echo "clusterSet: gitops-clusters"
echo "clusterLabels:"
echo "  env: $env"
if [ -n "$managed_cluster" ]; then
  echo "  managed-hub: 'yes'"
fi
