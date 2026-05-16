#!/usr/bin/env bash
#

_plugins="$(oc get consoles.operator.openshift.io cluster -o jsonpath='{.spec.plugins}')"

if [[ ! "gitops-plugin" =~ ${_plugins} ]]; then
  oc patch consoles.operator.openshift.io cluster --type=json \
  --patch='[{"op": "add", "path": "/spec/plugins/-", "value": "gitops-plugin"}]'
fi
