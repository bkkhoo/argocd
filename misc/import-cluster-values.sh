: << 'COMMENT'
./misc/import-cluster-values.sh dev-hub01 yes
./misc/import-cluster-values.sh prod-hub01 yes
./misc/import-cluster-values.sh prod-cluster01
./misc/import-cluster-values.sh prod-cluster02
COMMENT

cluster_name=${1}
managed_cluster=${2}
env="${cluster_name%%-*}"

echo "clusterName: $cluster_name" > /tmp/values.yaml
echo "clusterURL: $(oc whoami --show-server)" >> /tmp/values.yaml
echo "clusterAuthToken: $(oc whoami --show-token)" >> /tmp/values.yaml
echo "clusterSet: gitops-clusters" >> /tmp/values.yaml
echo "clusterLabels:" >> /tmp/values.yaml
echo "  env: $env" >> /tmp/values.yaml
if [ -n "$managed_cluster" ]; then
  echo "  managed-hub: 'yes'" >> /tmp/values.yaml
fi
