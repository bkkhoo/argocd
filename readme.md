# Overview

This diagram illustrates how the different components in the Multicluster Global Hub come together to deliver multicluster management at very high scale.  The root operator is the [global-hub-app-of-apps` ArgoCD application](./apps/00-global-hub-app-of-apps/), which automatically syncs manifests from GitHub to managed hubs and managed clusters.

![Multiluster Global Hub](./images/multicluster-global-hub.png)

## Repository Folders

```bash
├── apps                                # contains folders of argocd applications and applicationSets
│   ├── 00-global-hub-app-of-apps       # app-of-apps deployment of multicluster global hub
│   │   └── base
│   ├── 01-managed-hub-app-of-apps      # app-of-apps deployment of managed hub
│   │   ├── base
│   │   ├── dev
│   │   ├── prod
│   │   └── uat
│   ├── 02-managed-hub-bootstrap        # apps to bootstrap managed hub, contains:
│   │   ├── dev                         #   1. manifests to deploy rhacm and openshift-gitops
│   │   ├── prod                        #   2. manifests to deploy rhacm integration with openshift-gitops
│   │   └── uat                         #   3. manifests in managed-hub-app-of-apps
│   ├── cluster-config                  # base manaaged cluster config (self-provisioner, motd, catalog source, etc)
│   │   └── base
│   ├── openshift-compliance            # other applications/operators, one folder for each
│   │   └── base
.
--- snip --- # other helm charts
.
├── bootstrap                           # ansible playbook to bootstrap multicluster global hub
│   └── ansible
│       └── tasks
├── helm-charts                         # helm charts, one folder for each; the charts are referred by
│   ├── multicluster-global-hub         # argocd applications/applicationSets in the apps folder
│   │   └── templates
│   │       ├── global-hub
│   │       └── operator
│   ├── openshift-compliance
│   │   └── templates
│   │       ├── operator
│   │       └── scan
.
--- snip --- # other helm charts
.
├── kustomize-deployments               # kustomize-deployments, one folder for each; the deployments are referred by
│   ├── motd                            # argocd applications/applicationSets in the apps folder
│   │   └── base
│   ├── openshift-insights
│   │   └── base
.
--- snip --- # other helm charts
.
├── rhacm-policies                      # rhacm policies
│   └── base
│       ├── config
│       │   └── rhacs
│       └── monitor
└── root-app                            # root apps; app of apps deploys apps defined here
    ├── global-hub                      # for multicluster global hub
    │   └── base
    └── managed-hub                     # for managed hub of each env
        ├── dev
        ├── prod
        └── uat
```

## Usage

### MultiCluster Global Hub Use Case

This is a use case where a MultiCluster Global Hub manages a number of RHACM managed hub clusters, and each managed hub cluster manages a number of manageClusters.

The commands below deploys the following components on the global Hub cluster:
- RHACM
- OpenShift GitOps
- Enable RHACM integration with OpenShift GitOps
- MultiCluster Global Hub
- ArgoCD app-of-apps for global hub (`root-app/global-hub/base`) which deploys:
  - ArgoCD app-of-apps for managed hub (`root-app/managed-hub/<dev|uat|prod>`) to dev/uat/prod managed hubs:
    - dev managed hubs labels: `managed-hub=yes`, `env=dev`
    - uat managed hubs labels: `managed-hub=yes`, `env=uat`
    - prod managed hubs labels: `managed-hub=yes`, `env=prod`
  - RHACM policies (`apps/rhacm-policies/base`) to `local-cluster`
  - cluster config (`apps/cluster-config/base`) such as disable self provisioner, disable insights/telemetry services, etc to `local-cluster`
  - other ArgoCD applications to `local-cluster`

```bash
ansible-playbook -i localhost, bootstrap/ansible/bootstrap-global-hub.yaml -e config=basic

# global hub manages manged hubs for multiple environments
oc apply -k apps/00-global-hub-app-of-apps/base
```

**Notes**:
- Make sure to run playbook from host with `oc` and `helm` command line tools.
- Make sure to `oc login` to the OpenShift cluster with `custer-admin` privileges before running the Ansible playbook.

### Regular RHACM Use Case

This is a use case where a regular RHACM hub cluster manages a number of manageClusters.

The commands below deploys the following components on the global Hub cluster:
- RHACM
- OpenShift GitOps
- RHACM integration with OpenShift GitOps
- ArgoCD app-of-apps for managed hub (`root-app/managed-hub/<dev|uat|prod>`) to dev/uat/prod managed hubs which deploys:
  - RHACM policies (`apps/rhacm-policies/base`) to `local-cluster`
  - cluster config (`apps/cluster-config/base`) such as disable self provisioner, disable insights/telemetry services, etc to managed clusters
  - other ArgoCD applications to managed clusters

```bash
ansible-playbook -i localhost, bootstrap/ansible/bootstrap-regular-rhacm-hub.yaml -e config=basic

# dev environment
oc apply -k apps/01-managed-hub-app-of-apps/dev
```

## Notes

1. The RHACM PolicyGenerator does not come preinstalled in the OpenShift GitOps container image, use init container to copy PolicyGenerator binary from RHACM application subscription container image. See https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/gitops/index#integrate-pol-gen-ocp-gitops for more details.

1. ArgoCD disabled external plugins by default for security reasons, preventing external plugins from loading:
   - To use Helm charts within an ArgoCD Application that utilizes Kustomize, the `--enable-helm` flag must be enabled. For OpenShift GitOps, this is configured via by adding `kustomizeBuildOptions: --enable-helm` to `argocds.argoproj.io/openshift-gitops` resource.
   - To use RHACM PolicyGenerator within an ArgoCD Application that utilizes Kustomize, the `--enable-alpha-plugins` flag must be enabled. For OpenShift GitOps, this is configured via by adding `kustomizeBuildOptions: --enable-helm` to `argocds.argoproj.io/openshift-gitops` resource.

1. The default configuration of the ArgoCD server does not grant any privileges to user login via external identity provider (such as OpenShift); RBAC is configured by changing the `rbac` of `argocds.argoproj.io/openshift-gitops` resource. See https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/ for more details.

1. The `argocd.argoproj.io/managed-by: openshift-gitops` label is used to grant ArgoCD namespace Admin privileges to manage resources in other target namespaces.

1. OpenShift GitOps v1.20.x does not support Helm lookup function. See https://github.com/argoproj/argo-cd/issues/21745 for more details.

1. For Application/ApplicationSet that deploys Custom Resource (CR) alongside or before their operator (which deploys Custom Resource Definitions, CRDs) are deployed/registered in the cluster, the `argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true` annotation should be added to the instance/operand/CR manifest. The `SkipDryRunOnMissingResource=true` sync option allows ArgoCD to bypass dry-run validation.

1. On `in-cluster` (local cluster where ArgoCD is deployed), the ServiceAccount `openshift-gitops-argocd-application-controller` in `openshift-gitops` namespace does not have enough privileges to add/delete/update some resources (such as `configs.samples.operator.openshift.io`), the `supplementary-rbac-argocd-application-controller` ClusterRole/ClusterRoleBinding grants supplementary privileges to the ServiceAccount. Without the supplementary privileges, ArgoCD will failed to sync with the following error:
   ```
   Failed last sync attempt to [df95491967903498aea9898a72c5cb202650222c df95491967903498aea9898a72c5cb202650222c df95491967903498aea9898a72c5cb202650222c]: one or more objects failed to apply, reason: error when patching "/dev/shm/4227123794": configs.samples.operator.openshift.io "cluster" is forbidden: User "system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller" cannot patch resource "configs" in API group "samples.operator.openshift.io" at the cluster scope (retried 5 times).
   ```

   **Notes**:
   - For remote clusters, ArgoCD uses the ServiceAccount token (`argocd-manager` ServiceAccount in `kube-system` namespace) when appliying resources on those clusters, the token has `cluster-admin` privileges.

1. All RHACM ManagedClusters, except the `local-cluster`, should be added to the `gitops-clusters` ClusterSet.

## Issues

1. For RHACS, need to find a way to distribute `cluster-registration-secret` secret from hub to managed/remote cluster. The secret is required for RHACS SecuredCluster deployment.

## Reference

ArgoCD resource ordering:
- https://oneuptime.com/blog/post/2026-02-26-argocd-ordering-priority-multiple-sources/view

OpenShift GitOps sync is failing in user namespace:
- https://access.redhat.com/solutions/6012601

### Login to Hub OpenShift GitOps

```
argocd login "$(oc -n openshift-gitops get route openshift-gitops-server -o jsonpath={'.spec.host}'):443" \
  --skip-test-tls --username admin \
  --password "$(oc -n openshift-gitops get secret openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)"
```

### Add Clusters to ArgoCD

**Note**: This is not required when RHACM integration with OpenShift GitOps is enabled. RHACM automatically adds ManageClusters to OpenShift GitOps. and syncs all labels on the ManageClusters to ArgoCD clusters.

```
argocd cluster add cluster01 --server="$(oc -n openshift-gitops get route openshift-gitops-server -o jsonpath='{.spec.host}')" --label rhacs-secured-cluster=enable --insecure --yes
```

The command performs the followings:
- on the target/managed cluster:
  - creates `argocd-manager` ServiceAccount in `kube-system` namespace.
  - grants `argocd-manager` ServiceAccount cluster-admin privileges (ClusterRole: `argocd-manager-role`, ClusterRoleBinding: `argocd-manager-role-binding`).
  - creates a bearer token (that never expire, no `exp` claim) with the `argocd-manager` ServiceAccount.
- on the hub cluster:
  - create a secret with the properties:
    - name: cluster01
    - server: url of the target/managed
    - config: dict containing bearer token (`bearerToken`)
