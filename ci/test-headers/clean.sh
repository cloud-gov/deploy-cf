#! /bin/bash

set -e

ORG=$CF_ORG
DOMAIN=$CF_APP_DOMAIN
SPACE="header-tests"
APP_NAME="test-headers"


## CF Auth
cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

## Delete apps

# Change to target space
cf target -o $ORG -s $SPACE

# Delete app
cf delete $APP_NAME -f

## Delete spaces
cf delete-space $SPACE -o $ORG -f

## Delete org
cf delete-org $ORG -f
