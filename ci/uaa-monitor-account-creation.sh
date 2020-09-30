#!/bin/bash

set -eu


### Set variables
UAA_URL=$(echo "${UAA_URL}" | sed 's/\/$//')

ACCESS_TOKEN=$(curl \
  -s -u "${UAA_CLIENT_ID}:${UAA_CLIENT_SECRET}" \
  "${UAA_URL}/oauth/token" -d "grant_type=client_credentials" \
  | jq -r ".access_token")


### Utils
get_past_days_epoch() {
  local days=${1:-1}
  local result=$(date -d "-$days days" "+%s")

  echo $result
}

uaacurl() {
  curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Accept: application/json" "${UAA_URL}$@"
}

uaa_get_page_descending() {
  local path=$1
  local start_index=${2:-1}
  page=$(uaacurl -Gs "${UAA_URL}${path}?sortOrder=descending&startIndex=${start_index}")

  echo $page
}

count_users_created_past_week() {
  local days_back=${1:-7}
  local selector=".resources"

  last_week=$(get_past_days_epoch $days_back)
  page=$(uaa_get_page_descending "/Users")
  results=$(echo -n "${page}" | jq "${selector}")
  user_count=$(echo $results | \
    jq "map(.meta.created|split(\".\")|.[0]|strptime(\"%Y-%m-%dT%H:%M:%S\")|mktime|select(.>$last_week))|length")

  echo ${user_count}
}

metrics=$(mktemp)
value=$(count_users_created_past_week)
cat >> "${metrics}" <<EOF
uaa_monitor_account_creation ${value}
EOF

uaa_url=$(echo "${UAA_URL}" | sed 's/https:\/\///')
curl -X DELETE "${GATEWAY_HOST}:${GATEWAY_PORT:-9091}/metrics/job/uaa_monitor_account_creation/uaa_url/${uaa_url}"
curl --data-binary @${metrics} "${GATEWAY_HOST}:${GATEWAY_PORT:-9091}/metrics/job/uaa_monitor_account_creation/uaa_url/${uaa_url}"
