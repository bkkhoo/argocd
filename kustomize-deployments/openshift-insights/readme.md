# Opting Out of Remote Heath and Usage Data Reporting

Customers can opt out of reporting health and usage data. Red Hat strongly recommends leaving health and usage reporting enabled for pre-production and test clusters even if it is necessary to opt out for production clusters. This allows Red Hat to be a participant in qualifying OpenShift Container Platform in your environments and react more rapidly to product issues.

Some of the consequences of opting out of having a connected cluster are:
- Red Hat will not be able to monitor the success of product upgrades or the health of your clusters without a support case being opened.
- Red Hat will not be able to use configuration data to better triage customer support cases and identify which configurations our customers find important.
- The OpenShift Cluster Manager will not show data about your clusters including health and usage information.
- Your subscription entitlement information must be manually entered via console.redhat.com without the benefit of automatic usage reporting.

**Notes**:
- After disabling reporting health and usage data, manually register the cluster to link:https://console.redhat.com/openshift/register[Red Hat Hybrid Cloud Console].
- Use the following command to retrieve the Cluster ID of the cluster:
  ```
  oc get clusterversions.config.openshift.io version -o jsonpath="{.spec.clusterID}"
  ```

## Reference

- https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/support/remote-health-monitoring-with-connected-clusters#insights-operator-new-pull-secret_remote-health-reporting
- https://manuvaldi.github.io/openshift-disconnected-workshop/openshift-disconnected-workshop/08-Insights-and-Telemetry.html
