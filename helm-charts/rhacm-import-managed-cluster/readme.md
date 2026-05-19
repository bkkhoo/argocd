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
     managed-hub: "yes"
   EOF
   ```

   **Notes**:
   - The label selector uses the `Exists` or `DoesNotExist` operator on `clusterLabels.managed-hub` label, which verifies the label's presence regardless of its value.
   - If the value of the `clusterLabels.managed-hub` label is a boolean, it must be quoted. Unquoted boolean values will result in the following error:
     ```
     unable to decode "STDIN": json: cannot unmarshal bool into Go struct field ObjectMeta.metadata.labels of type string
     Error from server (Invalid): error when creating "STDIN": KlusterletAddonConfig.agent.open-cluster-management.io "dev-hub01" is invalid: spec.clusterLabels.managed-hub: Invalid value: "boolean": spec.clusterLabels.managed-hub in body must be of type string: "boolean"
     ```

1. Apply the Helm chart:
   ```
   helm template helm-charts/rhacm-import-managed-cluster/ --values /tmp/values.yaml
   ```

1. Clean up
   ```
   rm /tmp/values.yaml
   ```
