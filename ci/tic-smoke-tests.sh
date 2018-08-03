#!/usr/bin/env bats

restricted_payload=$(cat <<EOF
{"email":"smoke@${RESTRICTED_DOMAIN}"}
EOF
)

unrestricted_payload=$(cat <<EOF
{"email":"smoke@${UNRESTRICTED_DOMAIN}"}
EOF
)

gorouter_ip=$(
  bosh -d "${BOSH_DEPLOYMENT_NAME}" vms --json \
    | jq -r '.Tables[0].Rows[] | select(.instance | startswith("diego-cell/")) | .ips' \
    | head -n 1
)

@test "restricted user | address allowed" {
  resp=$(curl -s \
    http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "401" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "10002" ]
}

@test "restricted user | address forbidden" {
  resp=$(curl -s \
    http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${SOURCE_ADDRESS_FORBIDDEN}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "restricted user | secret allowed | proxy allowed | address allowed (X-Client-IP)" {
  resp=$(curl -s \
    http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: ${TIC_SECRET_ALLOWED}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "401" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "10002" ]
}

@test "restricted user | secret allowed | proxy forbidden | address allowed (X-Client-IP)" {
  resp=$(curl -s \
    http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_FORBIDDEN}" \
    -H "X-TIC-Secret: ${TIC_SECRET_ALLOWED}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "restricted user | secret forbidden | proxy allowed | address allowed (X-Client-IP)" {
  resp=$(curl -s \
    http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: ${TIC_SECRET_FORBIDDEN}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "restricted user | secret allowed | proxy allowed | address forbidden (X-Client-IP)" {
  resp=$(curl -s \
    http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: ${TIC_SECRET_ALLOWED}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_FORBIDDEN}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "restricted user | secret empty | proxy allowed | address allowed (X-Client-IP)" {
  resp=$(curl -s \
    http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: " \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "unrestricted user" {
  resp=$(curl -s \
    http://${gorouter_ip}:${GOROUTER_PORT:-80}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${unrestricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${SOURCE_ADDRESS_FORBIDDEN}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "401" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "10002" ]
}
