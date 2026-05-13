#!/usr/bin/env bash
#
# expects the following environment variables
# - RHACS_CENTRAL_NAMESPACE
# - RHACM_POLICIES_NAMESPACE

ROX_CENTRAL_ADDRESS=central
PASSWORD_FILE=/var/run/secrets/rhacs/password
CRS_NAME="openshift-clusters-$(date +%s)"
CRS_LIST_FILE=/tmp/crs-list
CRS_JSON_FILE=/tmp/crs.json
MAX_ATTEMPTS=30

rm -f ${CRS_LIST} ${CRS_JSON_FILE}

# if oc -n ${RHACS_CENTRAL_NAMESPACE} get secret/cluster-registration-secret &> /dev/null; then
#   echo "rhacs crs has already been configured"
#   exit 0
# fi

# wait for central to be ready
_attempt_counter=0
echo "waiting for rhacs central endpoint to be available..."
until $(curl --insecure --silent --request GET --head --fail --output /dev/null https://${ROX_CENTRAL_ADDRESS}); do
  if [ ${_attempt_counter} -eq ${MAX_ATTEMPTS} ]; then
    echo "max attempts reached; rhacs central endpoint is not available"
    exit 1
  fi
  printf "."
  _attempt_counter=$((${_attempt_counter}+1))
  echo "made attempt ${_attempt_counter}, waiting..."
  sleep 5
done

_password=$(cat ${PASSWORD_FILE})

echo "get list of rhacs crs"
_status=$(curl --insecure --silent --request GET --user "admin:${_password}" \
  --header "Content-Type: application/json" --header "Accept: application/json" \
  --write-out "%{http_code}" --output ${CRS_LIST_FILE} \
  https://${ROX_CENTRAL_ADDRESS}/v1/cluster-init/crs)
if grep --quiet "${CRS_NAME}" ${CRS_LIST_FILE}; then
  echo "crs already exist, abort"
  exit 1
fi

echo "creating rhacs crs"
_status=$(curl --insecure --silent --request POST --user "admin:${_password}" \
  --header "Content-Type: application/json" --header "Accept: application/json" \
  --write-out "%{http_code}" --output ${CRS_JSON_FILE} \
  --data "{\"name\": \"${CRS_NAME}\", \"validFor\": \"31536000s\"}" \
  https://${ROX_CENTRAL_ADDRESS}/v1/cluster-init/crs-extended)
if [ "${_status}" -eq "200" ]; then
  cat ${CRS_JSON_FILE} | python3 -c "import sys, json; print(json.load(sys.stdin)['crs'])" | base64 -d | \
  oc -n ${RHACS_CENTRAL_NAMESPACE} apply -f -
  echo "rhacs crs (${CRS_NAME}) created and applied"
else
  echo "failed to create crs"
  exit 1
fi

echo "get rhacs crs"
_crs=$(oc -n ${RHACS_CENTRAL_NAMESPACE} get secret cluster-registration-secret -o jsonpath="{.data.crs}" | base64 -d)
echo "get rhacs central hostname"
_central_endpoint=$(oc -n ${RHACS_CENTRAL_NAMESPACE} get routes.route.openshift.io central -o jsonpath="{.spec.host}")

echo "create ${RHACM_POLICIES_NAMESPACE}/rhacs-crs"
oc -n ${RHACM_POLICIES_NAMESPACE} create secret generic rhacs-crs\
  --from-literal=crs="${_crs}" --dry-run=client -o yaml | oc apply -f -

echo "create ${RHACM_POLICIES_NAMESPACE}/rrhacs-central-endpoint"
oc -n ${RHACM_POLICIES_NAMESPACE} create configmap rhacs-central-endpoint \
  --from-literal=centralEndpoint="${_central_endpoint}:443" --dry-run=client -o yaml | oc apply -f -
