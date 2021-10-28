#! /bin/bash

set -e

ORG=$CF_ORG
DOMAIN=$CF_APP_DOMAIN
SPACE_NO_EGRESS="no-egress"
SPACE_CLOSED_EGRESS="closed-egress"
SPACE_OPEN_EGRESS="open-egress"


## CF Auth
cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

## Delete apps

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  # Change to target space
  cf target -o $ORG -s $space

  # Delete app
  cf delete $space-app -f

  # Delete app route
  cf delete-route $DOMAIN --hostname app-test-$space -f

  # Delete service instance db
  cf delete-service $space-db -f
done

## Delete spaces

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  cf delete-space $space -o $ORG -f
done

## Delete org

cf delete-org $ORG -f
