#!/bin/sh

set -eux

CF_TRACE=true cf api "${CF_API_URL}"
(set +x; CF_TRACE=true cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

# Create isolation segment for platform applications
CF_TRACE=true cf target -o "${PLATFORM_ORGANIZATION}"
cf create-isolation-segment "${PLATFORM_ISOLATION_SEGMENT}"
cf enable-org-isolation "${PLATFORM_ORGANIZATION}" "${PLATFORM_ISOLATION_SEGMENT}"
cf set-space-isolation-segment "${PLATFORM_SPACE}" "${PLATFORM_ISOLATION_SEGMENT}"

# Create isolation segment for volume-enabled applications that want to use volume services
# VOLUME_TARGETS should be something like "org:space1,space2 org1:space3"
cf create-isolation-segment "${VOLUME_ISOLATION_SEGMENT}"
for i in ${VOLUME_TARGETS} ; do
  org="$(echo $i | awk -F: '{print $1}')"
  spaces="$(echo $i | awk -F: '{print $2}' | sed 's/,/ /g')"
  cf target -o "${org}"
  cf enable-org-isolation "${org}" "${VOLUME_ISOLATION_SEGMENT}"
  for space in ${spaces} ; do
    cf set-space-isolation-segment "${space}" "${VOLUME_ISOLATION_SEGMENT}"
  done
done
