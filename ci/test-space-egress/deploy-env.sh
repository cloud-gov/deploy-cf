#! /bin/bash

set -e

ORG=$CF_ORG
QUOTA=$CF_QUOTA
DOMAIN=$CF_APP_DOMAIN
SPACE_NO_EGRESS="no-egress"
SPACE_CLOSED_EGRESS="closed-egress"
SPACE_OPEN_EGRESS="open-egress"
ASG_TRUSTED_LOCAL_NETWORKS_INTERNAL_EGRESS="trusted_local_networks_egress"
ASG_PUBLIC_NETWORKS_EGRESS="public_networks_egress"
ASG_DNS_EGRESS="dns_egress"

# CF Auth
cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

# Go into test directory
pushd cf-manifests/ci/test-space-egress

## Create org

cf create-org $ORG

## Assign a quota

cf set-org-quota $ORG $QUOTA

## Create spaces

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  cf create-space $space -o $ORG
done

## Apply security groups

### Bind to closed egress space
cf bind-security-group $ASG_TRUSTED_LOCAL_NETWORKS_INTERNAL_EGRESS $ORG --space $SPACE_CLOSED_EGRESS

### Bind to open egress space
cf bind-security-group $ASG_TRUSTED_LOCAL_NETWORKS_INTERNAL_EGRESS $ORG --space $SPACE_OPEN_EGRESS
cf bind-security-group $ASG_PUBLIC_NETWORKS_EGRESS $ORG --space $SPACE_OPEN_EGRESS
cf bind-security-group $ASG_DNS_EGRESS $ORG --space $SPACE_OPEN_EGRESS

## Push apps

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  # target the correct space
  cf target -o $ORG -s $space

  # push the app
  cf push $space-app \
    --no-manifest \
    -b python_buildpack \
    -c "uvicorn main:app --port 8080 --host 0.0.0.0" \
    -m "128MB" \
    -k "512MB" \
    --no-route

  # map the route
  cf map-route $space-app $DOMAIN --hostname app-test-$space
done
