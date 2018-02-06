#!/bin/bash

set -eu

uaac target "${UAA_URL}"
uaac token client get "${UAA_CLIENT_ID}" -s "${UAA_CLIENT_SECRET}"
access_token=$(uaac context | grep access_token | sed 's/access_token://' | sed 's/ //g')

cfcurl() {
  curl -H "Authorization: Bearer ${access_token}" "$@"
}

paginate() {
  query=$1
  selector=$2

  local page next_url results
  page=$(cfcurl -s "${CF_API_URL}${query}")
  next_url=$(echo -n "${page}" | jq -r '.next_url // ""')
  results=$(echo -n "${page}" | jq -r "${selector}")
  while [ -n "${next_url}" ]; do
    page=$(cfcurl -s "${CF_API_URL}${next_url}")
    next_url=$(echo -n "${page}" | jq -r '.next_url // ""')
    results="${results}\n$(echo -n "${page}" | jq -r "${selector}")"
  done

  echo "${results}"
}

# Get known clients from broker
service_label="cloud-gov-identity-provider"

service_guid=$(cfcurl -s "${CF_API_URL}v2/services?q=label:${service_label}" | jq -r '.resources[0].metadata.guid')
service_plan_guids=$(paginate "/v2/service_plans?q=service_guid:${service_guid}" ".resources[] | .metadata.guid")

service_plan_list=$(echo "${service_plan_guids}" | paste -sd "," -)
service_instance_guids=$(paginate "/v2/service_instances?q=service_plan_guid%20IN%20${service_plan_list}" ".resources[] | .metadata.guid")

service_instance_list=$(echo "${service_instance_guids}" | paste -sd "," -)
service_binding_guids=$(paginate "/v2/service_bindings?q=service_instance_guid%20IN%20${service_instance_list}" ".resources[] | .metadata.guid")
service_key_guids=$(paginate "/v2/service_keys?q=service_instance_guid%20IN%20${service_instance_list}" ".resources[] | .metadata.guid")

# Get known clients from manifests
upstream_clients=$(cat cf-deployment/cf-deployment.yml \
  | spruce json \
  | jq -r '.instance_groups[] | select(.name == "uaa") | .jobs[] | select(.name == "uaa") | .properties.uaa.clients | keys[]')

cg_clients=$(cat cf-manifests/bosh/opsfiles/clients.yml \
  | grep -ioE '\/clients\/[0-9a-z_-]+\??$' \
  | sed 's/\?//' | sed 's/\/clients\///')

# Diff existing clients against expected
clients=$(uaac clients | grep -v ":" | sed 's/ //g')

known_clients=$(cat <<EOF
admin
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
echo "uaa_client_audit_lastcheck $(date +'%s')" | curl --data-binary @- "${GATEWAY_HOST}:${GATEWAY_PORT:-9091}/metrics/job/uaa_client_audit/instance/lastcheck"
