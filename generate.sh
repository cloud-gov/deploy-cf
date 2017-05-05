#!/bin/sh

set -e -x

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

SECRETS=$SCRIPTPATH/cf-secrets.yml
MANIFEST=$SCRIPTPATH/manifest.yml

if [ "${#@}" -gt 0 ]
then
  SECRETS=''
  eval MANIFEST=\${$#}
  for file in "$@"
  do
    if [[ $file != "${MANIFEST}" ]]
    then
      SECRETS="${SECRETS} ${file}"
    fi
  done
fi

spiff merge \
  $SCRIPTPATH/cf-deployment.yml \
  $SCRIPTPATH/cf-resource-pools.yml \
  $SCRIPTPATH/cf-jobs.yml \
  $SCRIPTPATH/cf-properties.yml \
  $SCRIPTPATH/cf-infrastructure-aws.yml \
  $SECRETS \
  > $MANIFEST
