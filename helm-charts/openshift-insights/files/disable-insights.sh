#!/bin/bash
# the script removes cloud.openshift.com key from global pull secret
# removing the credential for cloud.openshift.com disable remote health reporting for insights operator

set -euo pipefail

# use environment variable instead
# INSIGHTS_ENTRY="cloud.openshift.com"

updated_pull_secret=$(oc -n openshift-config extract secret/pull-secret --to=- | jq "del(.auths[\"${INSIGHTS_ENTRY}\"])" | base64 -w0)

oc -n openshift-config patch secret/pull-secret -p "{
  \"data\": {
    \".dockerconfigjson\": \"${updated_pull_secret}\"
  }
}"

# no insights operator pod restart required; might take a few minutes for the change to take effect
# uncomment the line below to force the change to take effect immediately
# oc -n openshift-insights delete pod --selector app=insights-operator
