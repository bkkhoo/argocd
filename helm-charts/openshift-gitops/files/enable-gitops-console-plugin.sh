#!/usr/bin/env bash
#

_plugins="$(oc get consoles.operator.openshift.io cluster -o jsonpath='{.spec.plugins}')"

if [[ ! "gitops-plugin" =~ ${_plugins} ]]; then
  oc patch consoles.operator.openshift.io cluster --type=json \
  --patch='[{"op": "add", "path": "/spec/plugins/-", "value": "gitops-plugin"}]'
fi

# - name: check console plugins
#   register: console_plugins
#   ansible.builtin.command:
#     cmd: oc get consoles.operator.openshift.io cluster -o jsonpath="{.spec.plugins}"

# - name: ensure gitops console plungin is enabled
#   when: "'gitops-plugin' not in console_plugins.stdout"
#   ansible.builtin.command:
#     # > converts line breaks into space; - removes the trailing newline at the end of the block
#     cmd: >-
#       oc patch consoles.operator.openshift.io cluster --type=json
#       --patch='[{"op": "add", "path": "/spec/plugins/-", "value": "gitops-plugin"}]'
