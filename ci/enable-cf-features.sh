# #!/bin/sh
# 
# set -eux
# 
# cf api "${CF_API_URL}"
# (set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")
# 
# # Create isolation segment for platform applications
# cf target -o "${PLATFORM_ORGANIZATION}"
# cf create-isolation-segment "${PLATFORM_ISOLATION_SEGMENT}"
# cf enable-org-isolation "${PLATFORM_ORGANIZATION}" "${PLATFORM_ISOLATION_SEGMENT}"
# cf set-space-isolation-segment "${PLATFORM_SPACE}" "${PLATFORM_ISOLATION_SEGMENT}"
# 
# # Create isolation segment for volume-enabled applications that want to use volume services
# # VOLUME_TARGETS should be something like "org:space1,space2 org1:space3"
# cf create-isolation-segment "${VOLUME_ISOLATION_SEGMENT}"
# for i in ${VOLUME_TARGETS} ; do
#   org="$(echo $i | awk -F: '{print $1}')"
#   spaces="$(echo $i | awk -F: '{print $2}' | sed 's/,/ /g')"
#   cf target -o "${org}"
#   cf enable-org-isolation "${org}" "${VOLUME_ISOLATION_SEGMENT}"
#   for space in ${spaces} ; do
#     cf set-space-isolation-segment "${space}" "${VOLUME_ISOLATION_SEGMENT}"
#   done
# done

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
  setup_bosh_env_vars

  if [ -z "${SYSTEM_DOMAIN}" ]; then
    echo "SYSTEM_DOMAIN is a required parameter"
    exit 1
  fi

  cf api "${CF_API_URL}"
  (set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

  set_enabled_feature_flags
  set_disabled_feature_flags

  cf feature-flags
}

main
