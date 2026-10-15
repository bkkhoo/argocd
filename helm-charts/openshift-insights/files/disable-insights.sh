#!/bin/bash
# the script removes cloud.openshift.com key from global pull secret
# removing the credential for cloud.openshift.com disable remote health reporting for insights operator

set -euo pipefail

# use environment variable instead
# INSIGHTS_ENTRY="cloud.openshift.com"

updated_pull_secret=$(oc --namespace openshift-config extract secret/pull-secret --to=- | jq "del(.auths[\"${INSIGHTS_ENTRY}\"])" | base64 --wrap=0)

oc --namespace openshift-config patch secret/pull-secret --patch "{
  \"data\": {
    \".dockerconfigjson\": \"${updated_pull_secret}\"
  }
}"

# no insights operator pod restart required; might take a few minutes for the change to take effect
# uncomment the line below to force the change to take effect immediately
# oc --namespace openshift-insights delete pod --selector app=insights-operator
