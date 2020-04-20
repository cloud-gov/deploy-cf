#!/bin/bash

# Tests various UAA endpoints for known vulnerabilities. 
# See: https://github.com/cloud-gov/private/issues/117

set -e

# Endpoint should be disabled (GET): /create_account 
status_code=$(curl ${UAA_URL}/create_account \
  --silent \
  --output /dev/null \
  -w "%{http_code}")
if [[ "${status_code}" != "403" ]]; then
  echo "ERROR: Endpoint /create_account returned incorrect status code. Expected: 403, Got: ${status_code}"
  exit 1
fi

# Endpoint should be disabled (POST): /create_account.do 
url_no_protocol=${UAA_URL#"https://"}
status_code=$(curl ${UAA_URL}/create_account.do \
  --silent \
  --output /dev/null \
  -w "%{http_code}" \
  -H "authority: ${url_no_protocol}" \
  -H "pragma: no-cache" \
  -H "cache-control: no-cache" \
  -H "upgrade-insecure-requests: 1" \
  -H "origin: ${UAA_URL}" \
  -H "content-type: application/x-www-form-urlencoded" \
  -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" \
  -H "sec-fetch-site: same-origin" \
  -H "sec-fetch-mode: navigate" \
  -H "sec-fetch-user: ?1" \
  -H "sec-fetch-dest: document" \
  -H "referer: ${UAA_URL}/create_account" \
  -H "accept-language: en-US,en;q=0.9" \
  -H "cookie: JSESSIONID=OGNiNGY1N2QtNzAzYi00ODM3LTlmNjktZWM3NTkwMjgzMjQy; __VCAP_ID__=48b92696-54d4-49c9-40ad-58e9a1516ad6; X-Uaa-Csrf=K0LnbQ6Y9dCUVPqC6eV8tE" \
  --data "X-Uaa-Csrf=K0LnbQ6Y9dCUVPqC6eV8tE&client_id=&redirect_uri=&email=security%40cloud.gov&password=ACCOUNT-FOR-BUG-BOUNTY&password_confirmation=ACCOUNT-FOR-BUG-BOUNTY&submit=Send+activation+link")
if [[ "${status_code}" != "403" ]]; then
  echo "ERROR: POST to endpoint /create_account.do returned incorrect status code. Expected: 403, Got: ${status_code}"
  exit 1
fi
