#! /bin/bash

set -e

ORG=$CF_ORG
QUOTA=$CF_QUOTA
DOMAIN=$CF_APP_DOMAIN
SPACE="header-tests"
ASG_TRUSTED_LOCAL_NETWORKS_INTERNAL_EGRESS="trusted_local_networks_egress"
ASG_PUBLIC_NETWORKS_EGRESS="public_networks_egress"
ASG_DNS_EGRESS="dns_egress"

# CF Auth
cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

# Function for waiting on a service instance to finish being processed.
wait_for_service_instance() {
  local service_name=$1
  local guid=$(cf service --guid $service_name)
  local status=$(cf curl /v3/service_instances/${guid} | jq -r '.last_operation.state')

  while [ "$status" == "in progress" ]; do
    sleep 60
    status=$(cf curl /v3/service_instances/${guid} | jq -r '.last_operation.state')
  done
}

# Go into test directory
pushd cf-manifests/ci/test-headers

## Create org

cf create-org $ORG

## Assign a quota

cf set-org-quota $ORG $QUOTA

## Create spaces

cf create-space $SPACE -o $ORG

## Apply security groups

### Bind to open egress space
cf bind-security-group $ASG_TRUSTED_LOCAL_NETWORKS_INTERNAL_EGRESS $ORG --space $SPACE
cf bind-security-group $ASG_PUBLIC_NETWORKS_EGRESS $ORG --space $SPACE
cf bind-security-group $ASG_DNS_EGRESS $ORG --space $SPACE

## Push app

# target the correct space
cf target -o $ORG -s $SPACE

# push the app
cf push test-headers \
  --no-manifest \
  -b python_buildpack \
  -c "uvicorn main:app --port 8080 --host 0.0.0.0" \
  -m "128MB" \
  -k "512MB" 
