#!/bin/bash

set -eux

restricted_payload=$(cat <<EOF
{"email":"smoke@${RESTRICTED_DOMAIN}"}
EOF
)

unrestricted_payload=$(cat <<EOF
{"email":"smoke@${UNRESTRICTED_DOMAIN}"}
EOF
)

gorouter_ip=$(dig +short "@${BOSH_ADDRESS}" "${GOROUTER_ADDRESS}")

check_resp() {
  body="$1"
  expected_http_code="$2"
  expected_error_code="$3"

  http_code=$(echo "${body}" | tail -n 1)
  if [ ${http_code} != ${expected_http_code} ]; then
    echo "Expected http code ${expected_http_code}; got ${http_code}"
    return 1
  fi

  error_code=$(echo "${body}" | head -n -1 | jq -r '.code')
  if [ ${error_code} != "${expected_error_code}" ]; then
    echo "Expected error code ${expected_error_code}; got ${error_code}"
    return 1
  fi
  return 0
}

resp=$(curl -s \
  http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
  -H "Host: ${API_HOSTNAME}" \
  -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
  -H "X-Forwarded-For: ${SOURCE_ADDRESS_ALLOWED}" \
  -w '\n%{http_code}')
check_resp "${resp}" 401 10002

resp=$(curl -s \
  http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
  -H "Host: ${API_HOSTNAME}" \
  -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
  -H "X-Forwarded-For: ${SOURCE_ADDRESS_FORBIDDEN}" \
  -w '\n%{http_code}')
check_resp "${resp}" 403 9162

resp=$(curl -s \
  http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
  -H "Host: ${API_HOSTNAME}" \
  -H "Authorization: $(echo '{}' | base64).$(echo ${unrestricted_payload} | base64).$(echo '{}' | base64)" \
  -H "X-Forwarded-For: ${SOURCE_ADDRESS_FORBIDDEN}" \
  -w '\n%{http_code}')
check_resp "${resp}" 401 10002
