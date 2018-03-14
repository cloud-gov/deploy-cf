#!/bin/bash

set -eux

cf api "${CF_API_URL}"
(set +x; cf auth "${CF_USERNAME}" "${CF_PASSWORD}")

cf target -o "${CF_ORGANIZATION}" -s "${CF_SPACE}"
pushd cf-manifests/ci/groundhog
  cf push -f manifest.yml groundhog
popd

url=$(cf app groundhog | grep -e "urls: " -e "routes: " | awk '{print $2}')
curl "https://${url}/below-binary"

found_log=0
start=$(date +%s)
until [ $(date +%s) -ge $(( ${start} + 60 )) ]; do
  if cf logs groundhog --recent \
      | grep FALCO \
      | grep "Directory below known binary directory created"; then
    found_log=1
    break
  fi
done
if [ "${found_log}" -eq 0 ]; then
  echo "Falco log not found"
  exit 1
fi
