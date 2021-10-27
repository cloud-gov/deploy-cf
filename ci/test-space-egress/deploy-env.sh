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

# Function for waiting on a service instance to finish being processed.
wait_for_service_instance() {
  local service_name=$1
  local guid=$(cf service --guid $service_name)
  local status=$(cf curl /v2/service_instances/${guid} | jq -r '.entity.last_operation.state')

  while [ "$status" == "in progress" ]; do
    sleep 60
    status=$(cf curl /v2/service_instances/${guid} | jq -r '.entity.last_operation.state')
  done
}

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

## Create databases

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  # target the correct space
  cf target -o $ORG -s $space

  # Create the db service instance
  cf create-service aws-rds micro-psql $space-db
done

## Wait for databases to create

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  # target the correct space
  cf target -o $ORG -s $space

  # Wait for the database
  wait_for_service_instance $space-db
done

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

  # bind db
  cf bind-service $space-app $space-db

  # restage app
  cf restage $space-app
done
