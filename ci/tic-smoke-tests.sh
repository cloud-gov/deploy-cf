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
    | jq -r '.Tables[0].Rows[] | select(.instance | startswith("router/")) | .ips' \
    | head -n 1
)

@test "restricted user from allowed address can reach API" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  # 401 because our Authorization header is bogus
  [ $(echo "${resp}" | tail -n 1) = "401" ]
  # validate the code in the body to make sure it looks like we really reached CAPI
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "10002" ]
}

@test "restricted user from unallowed is blocked by secureproxy when requesting API" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${SOURCE_ADDRESS_FORBIDDEN}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "x-client-ip is trusted when x-forwarded-for is a trusted proxy, allowing restricted user to access API from allowed address" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: ${TIC_SECRET_ALLOWED}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  # 401 because our Authorization header is bogus
  [ $(echo "${resp}" | tail -n 1) = "401" ]
  # validate the code in the body to make sure it looks like we really reached CAPI
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "10002" ]
}

@test "x-client-ip is not trusted when x-forwarded-for is untrusted, disallowing restricted user from accessing API with allowed address in x-client-ip" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_FORBIDDEN}" \
    -H "X-TIC-Secret: ${TIC_SECRET_ALLOWED}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "x-client-ip is not trusted when x-tic-secret is invalid, disallowing restricted user from accessing API with allowed address in x-client-ip" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: ${TIC_SECRET_FORBIDDEN}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "x-client-ip is trusted when x-tic-secret and proxy address are trusted, disallowing restricted user from accessing API with disallowed address in x-client-ip" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: ${TIC_SECRET_ALLOWED}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_FORBIDDEN}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "x-client-ip is not trusted when x-tic-secret is empty, disallowing restricted user from accessing API with allowed address in x-client-ip" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: " \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "unrestricted user can access API from forbidden address" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/v2/apps \
    -H "Host: ${API_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${unrestricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${SOURCE_ADDRESS_FORBIDDEN}" \
    -w '\n%{http_code}')
  # 401 because our Authorization header is bogus
  [ $(echo "${resp}" | tail -n 1) = "401" ]
  # validate the code in the body to make sure it looks like we really reached CAPI
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "10002" ]
}

@test "restricted user can access the dashboard from an allowed address" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/pp/v1/proxy/v2/apps \
    -H "Host: ${DASHBOARD_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  # 401 because our Authorization header is bogus
  [ $(echo "${resp}" | tail -n 1) = "401" ]
  # validate the error message in the body to make sure it looks like we really reached Stratos
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "User session could not be found" ]
}

@test "restricted user cannot access the dashboard from an unallowed address" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/pp/v1/proxy/v2/apps \
    -H "Host: ${DASHBOARD_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${SOURCE_ADDRESS_FORBIDDEN}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "x-client-ip is trusted when x-forwarded-for is a trusted proxy, allowing restricted user to access dashboard from allowed address" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/pp/v1/proxy/v2/apps \
    -H "Host: ${DASHBOARD_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: ${TIC_SECRET_ALLOWED}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  # 401 because our Authorization header is bogus
  [ $(echo "${resp}" | tail -n 1) = "401" ]
  # validate the code in the body to make sure it looks like we really reached Stratos
  [ $(echo "${resp}" | head -n -1 | jq -r '.error') = "User session could not be found" ]
}

@test "x-client-ip is not trusted when x-forwarded-for is untrusted, disallowing restricted user from accessing dashboard with allowed address in x-client-ip" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/pp/v1/proxy/v2/apps \
    -H "Host: ${DASHBOARD_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_FORBIDDEN}" \
    -H "X-TIC-Secret: ${TIC_SECRET_ALLOWED}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "x-client-ip is not trusted when x-tic-secret is invalid, disallowing restricted user from accessing dashboard with allowed address in x-client-ip" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/pp/v1/proxy/v2/apps \
    -H "Host: ${DASHBOARD_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: ${TIC_SECRET_FORBIDDEN}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "x-client-ip is trusted when x-tic-secret and proxy address are trusted, disallowing restricted user from accessing dashboard with disallowed address in x-client-ip" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/pp/v1/proxy/v2/apps \
    -H "Host: ${DASHBOARD_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: ${TIC_SECRET_ALLOWED}" \
    -H "X-Client-IP: ${SOURCE_ADDRESS_FORBIDDEN}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "x-client-ip is not trusted when x-tic-secret is empty, disallowing restricted user from accessing dashboard with allowed address in x-client-ip" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/pp/v1/proxy/v2/apps \
    -H "Host: ${DASHBOARD_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${restricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${PROXY_ADDRESS_ALLOWED}" \
    -H "X-TIC-Secret: " \
    -H "X-Client-IP: ${SOURCE_ADDRESS_ALLOWED}" \
    -w '\n%{http_code}')
  [ $(echo "${resp}" | tail -n 1) = "403" ]
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "9162" ]
}

@test "unrestricted user can access the dashboard from unallowed address" {
  resp=$(curl -s -k \
    ${TIC_PROTOCAL}://${gorouter_ip}:${GOROUTER_PORT:-443}/pp/v1/proxy/v2/apps \
    -H "Host: ${DASHBOARD_HOSTNAME}" \
    -H "Authorization: $(echo '{}' | base64).$(echo ${unrestricted_payload} | base64).$(echo '{}' | base64)" \
    -H "X-Forwarded-For: ${SOURCE_ADDRESS_FORBIDDEN}" \
    -w '\n%{http_code}')
  # 401 because our Authorization header is bogus
  [ $(echo "${resp}" | tail -n 1) = "401" ]
  # validate the error message in the body to make sure it looks like we really reached Stratos
  [ $(echo "${resp}" | head -n -1 | jq -r '.code') = "User session could not be found" ]
}
