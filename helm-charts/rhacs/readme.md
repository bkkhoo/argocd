The `deploymentType` helm value is introduced to allow more flexible use of the helm chart:
- Ansible usage: the operator must be deployed first, the MultiClusterHub instance can only be deployed after the operator's CSV reached `Succeeded` phase.
- ArgoCD usage: the sync-waves annotation in the YAML templates ensure resources are deployed in orderly manner.

The `deploymentType` accepts:
- `central`: deploys RHACS operator, Central, SecurityPolicy.
- `secure-cluster`: deploy SecuredCluster.
- `all`: default, deploy operator, Central, SecurityPolicy and SecuredCluster.
