The `deploymentType` helm value is introduced to allow more flexible use of the helm chart:
- Ansible usage: the operator must be deployed first, the instance can only be deployed after the operator's CSV reached `Succeeded` phase.
- ArgoCD usage: the sync-waves annotation in the YAML templates ensure resources are deployed in orderly manner.

The `deploymentType` accepts:
- `operator`: deploys OpenShift GitOps operator only.
- `argocd`: deploys ArgoCD instance; actually reconfigure the instance only since the operator is set to automatically deploy ARgoCD instance.
- `all`: default, deploys both operator and ArgoCD instance.
