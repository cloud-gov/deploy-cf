#!/bin/sh

set -eux

cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

cf target -o "${PLATFORM_ORGANIZATION}"

cf create-isolation-segment "${PLATFORM_ISOLATION_SEGMENT}"
cf enable-org-isolation "${PLATFORM_ORGANIZATION}" "${PLATFORM_ISOLATION_SEGMENT}"
cf set-space-isolation-segment "${PLATFORM_SPACE}" "${PLATFORM_ISOLATION_SEGMENT}"
