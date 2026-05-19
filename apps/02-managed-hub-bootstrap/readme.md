# Notes

- The `dev`, `uat`, and `prod` folders are not overlays. Setting those folders as overlays will result in the following error when a parent kustomize deployment include multiple overlays, as in `root-app/global-hub/base/kustomization.yaml`.
  ```
  Error: accumulating resources: accumulation err='accumulating resources from '../../../apps/managed-hub-bootstrap/prod/': '/mnt/hgfs/git-repos/argocd/apps/managed-hub-bootstrap/prod' must resolve to a file': recursed merging from path '/mnt/hgfs/git-repos/argocd/apps/managed-hub-bootstrap/prod': may not add resource with an already registered id: ApplicationSet.v1alpha1.argoproj.io/managed-hub-bootstrap.openshift-gitops
  ```

- ArgoCD manages an application's Helm chart values through multiple mechanisms, each with a specific use case and precedence level:
  - helm repository values.yaml (lowest)
  - valueFiles (last file listed wins)
  - values (inline YAML string)
  - valuesObject (inline YAML object)
  - parameters (highest)
