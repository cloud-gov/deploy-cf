#!/bin/bash

set -eu

UAA_URL=$(echo "${UAA_URL}" | sed 's/\/$//')
CF_API_URL=$(echo "${CF_API_URL}" | sed 's/\/$//')

access_token=$(curl -s -u "${UAA_CLIENT_ID}:${UAA_CLIENT_SECRET}" "${UAA_URL}/oauth/token" -d "grant_type=client_credentials" \
  | jq -r ".access_token")

cfcurl() {
  curl -H "Authorization: Bearer ${access_token}" -H "Accept: application/json" "$@"
}

paginate() {
  local query=$1
  local selector=$2

  local page next_url results
  page=$(cfcurl -s "${CF_API_URL}${query}")
  next_url=$(echo -n "${page}" | jq -r '.pagination.next.href // ""')
  results=$(echo -n "${page}" | jq -r "${selector}")
  while [ -n "${next_url}" ]; do
    page=$(cfcurl -s "${next_url}")
    next_url=$(echo -n "${page}" | jq -r '.pagination.next.href // ""')
    results="${results}\n$(echo -n "${page}" | jq -r "${selector}")"
  done

  echo "${results}"
}

uaapaginate() {
  query=$1
  selector=$2

  local page results start_index items_per_page total_results
  start_index=1
  page=$(cfcurl -Gs "${UAA_URL}${query}" -d "startIndex=${start_index}")
  items_per_page=$(echo -n "${page}" | jq -r '.itemsPerPage')
  total_results=$(echo -n "${page}" | jq -r '.totalResults')
  results=$(echo -n "${page}" | jq -r "${selector}")
  while [ "${start_index}" -lt "${total_results}" ]; do
    page=$(cfcurl -Gs "${UAA_URL}${query}" -d "startIndex=${start_index}")
    start_index=$((start_index + items_per_page))
  done

  echo "${results}"
}

# Get known clients from broker
service_label="cloud-gov-identity-provider"

service_guid=$(cfcurl "/v3/service_offerings?names=${service_label}" | jq -r '.resources[0].guid')
service_plan_guids=$(paginate "/v3/service_plans?service_offering_guids=${service_guid}" ".resources[].guid")

service_plan_list=$(echo "${service_plan_guids}" | paste -sd "," -)
service_instance_guids=$(paginate "/v3/service_instances?service_plan_guids=${service_plan_list}" ".resources[].guid")

service_instance_list=$(echo "${service_instance_guids}" | paste -sd "," -)
service_binding_guids=$(paginate "/v3/service_credential_bindings?type=app&service_instance_guids=${service_instance_list}" ".resources[].guid")
service_key_guids=$(paginate "/v3/service_credential_bindings?type=key&service_instance_guids=${service_instance_list}" ".resources[].guid")

# Get known clients from manifests
upstream_clients=$(cat cf-deployment/cf-deployment.yml \
  | spruce json \
  | jq -r '.instance_groups[] | select(.name == "uaa") | .jobs[] | select(.name == "uaa") | .properties.uaa.clients | keys[]')

cg_clients=$(cat cf-manifests/bosh/opsfiles/clients.yml \
  | grep -ioE '\/clients\/[0-9a-z_-]+\??$' \
  | sed 's/\?//' | sed 's/\/clients\///')

# Diff existing clients against expected
clients=$(uaapaginate "/oauth/clients" ".resources[] | .client_id")

whitelist="admin"
if [ -n "${WHITELIST:-}" ]; then
  whitelist=$(cat <<EOF
${whitelist}
$(echo "${WHITELIST}" | tr " " "\n")
EOF
)
fi

known_clients=$(cat <<EOF
${whitelist}
${service_instance_guids}
${service_binding_guids}
${service_key_guids}
${upstream_clients}
${cg_clients}
EOF
)

metrics=$(mktemp)
for client in ${clients}; do
  echo "${client}"
  value=0
  if echo "${client}" | grep -Fxf <(echo "${known_clients}"); then
    value=1
  fi
  cat >> "${metrics}" <<EOF
uaa_client_audit{instance="${client}"} ${value}
EOF
done

uaa_url=$(echo "${UAA_URL}" | sed 's/https:\/\///')
curl -X DELETE "${GATEWAY_HOST}:${GATEWAY_PORT:-9091}/metrics/job/uaa_client_audit/uaa_url/${uaa_url}"
curl --data-binary @${metrics} "${GATEWAY_HOST}:${GATEWAY_PORT:-9091}/metrics/job/uaa_client_audit/uaa_url/${uaa_url}"
