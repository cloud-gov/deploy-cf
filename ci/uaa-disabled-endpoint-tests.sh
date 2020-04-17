#!/bin/bash

# Tests various UAA endpoints for known vulnerabilities. 
# See: https://github.com/cloud-gov/private/issues/117

set -e

# Endpoint should be disabled (GET): /create_account 
status_code=$(curl --silent \
  --output /dev/null \
  -w "%{http_code}" \
  ${UAA_URL}/create_account)
if [[ "${status_code}" != "403" ]]; then
  echo "ERROR: Endpoint /create_account returned incorrect status code. Expected: 403, Got: ${status_code}"
  exit 1
fi

# Endpoint should be disabled (POST): /create_account.do 
# status_code=$(curl -X POST \
#   --silent \
#   --output /dev/null \
#   -w "%{http_code}" \
#   ${UAA_URL}/create_account.do \
#   --data-urlencode client_id=client-id \
#   --data-urlencode redirect_uri=redirect-uri \
#   --data-urlencode password=password1 \
#   --data-urlencode password_confirmation=password1 \
#   --data-urlencode email=test@example.com)
# if [[ "${status_code}" != "404" ]]; then
#   echo "ERROR: POST to endpoint /create_account.do returned incorrect status code. Expected: 404, Got: ${status_code}"
#   exit 1
# fi
