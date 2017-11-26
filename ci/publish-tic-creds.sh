#!/bin/bash

set -eux

cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")
cf target -o "${CF_ORG}" -s "${CF_SPACE}"

JSON=$(cat <<EOF
{
  "tic_secret": "${TIC_SECRET}"
}
EOF
)

cf cups "${CF_UPS_NAME}" -p "${JSON}" || cf uups "${CF_UPS_NAME}" -p "${JSON}"
