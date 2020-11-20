#!/bin/bash -exu

function set_enabled_feature_flags() {
  if [ ! -z "${ENABLED_FEATURE_FLAGS}" ]; then
    for flag in $ENABLED_FEATURE_FLAGS; do
      set_feature_flag "$flag" true
    done
  fi
}

function set_disabled_feature_flags() {
  if [ ! -z "${DISABLED_FEATURE_FLAGS}" ]; then
    for flag in $DISABLED_FEATURE_FLAGS; do
      set_feature_flag "$flag" false
    done
  fi
}

function set_feature_flag() {
  if [ $2 == true ]; then
    cf enable-feature-flag "$1"
  else
    cf disable-feature-flag "$1"
  fi
}

function main() {
  cf api "${CF_API_URL}"
  curl -L --output /dev/null --silent --show-error --write-out 'lookup:        %{time_namelookup}\nconnect:       %{time_connect}\nappconnect:    %{time_appconnect}\npretransfer:   %{time_pretransfer}\nredirect:      %{time_redirect}\nstarttransfer: %{time_starttransfer}\ntotal:         %{time_total}\n' 'https://login.dev.us-gov-west-1.aws-us-gov.cloud.gov/oauth/token'
  (set -x; CF_TRACE=true cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

  set_enabled_feature_flags
  set_disabled_feature_flags
  cf feature-flags
}

main
