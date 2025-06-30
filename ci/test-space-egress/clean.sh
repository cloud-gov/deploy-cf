#! /bin/bash

set -e

ORG=$CF_ORG
DOMAIN=$CF_APP_DOMAIN
SPACE_CLOSED_EGRESS="closed-egress"
SPACE_RESTRICTED_EGRESS="restricted-egress"
SPACE_PUBLIC_EGRESS="public-egress"


## CF Auth
cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

## Delete apps

for space in $SPACE_CLOSED_EGRESS $SPACE_RESTRICTED_EGRESS $SPACE_PUBLIC_EGRESS
do
  # Change to target space
  cf target -o $ORG -s $space

  # Delete app
  cf delete $space-app -f

  # Delete app route
  cf delete-route $DOMAIN --hostname app-test-$space -f

  # Delete service instance db
  cf delete-service $space-db -f -w
done

## Delete spaces

for space in $SPACE_CLOSED_EGRESS $SPACE_RESTRICTED_EGRESS $SPACE_PUBLIC_EGRESS
do
  cf delete-space $space -o $ORG -f
done

## Delete org

cf delete-org $ORG -f
