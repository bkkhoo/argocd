# Helm Chart: Imports/Attaches Managed Cluster to RHACM Hub

This Helm chart imports/attaches managed cluster to RHACM hub. The chart expects the following values:
- mandatory values
  - `clusterName` - name of the managed cluster.
  -  `clusterURL` - URL of the managed cluster.
  - `clusterAuthToken` - Bearer token with cluster admin privileges from the managed cluster.
- optional values:
  - `clusterSet` - the name of the clusterSet to assign the managed cluster.
  - `clusterLabels` - additional labels to apply to the managed cluster.

## Usage

1. Create a `values.yaml` file locally:
   ```
   cat << EOF > /tmp/values.yaml
   clusterName: <cluster-name>
   clusterURL: <https-url>
   clusterAuthToken: <token>
   clusterSet: gitops-clusters
   clusterLabels:
     env: dev
     managed-hub: yes
   EOF
   ```

1. Apply the Helm chart:
   ```
   helm template helm-charts/rhacm-import-managed-cluster/ --values /tmp/values.yaml
   ```

1. Clean up
   ```
   rm /tmp/values.yaml
   ```
