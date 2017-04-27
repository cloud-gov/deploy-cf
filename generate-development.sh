#!/bin/sh

set -e -x

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

SECRETS=$SCRIPTPATH/cf-secrets-development.yml
MANIFEST=$SCRIPTPATH/manifest-development.yml
if [ ! -z "$1" ]; then
  SECRETS=$1
fi
if [ ! -z "$2" ]; then
  MANIFEST=$2
fi

spiff merge \
  $SCRIPTPATH/cf-deployment.yml \
  $SCRIPTPATH/cf-resource-pools.yml \
  $SCRIPTPATH/cf-jobs.yml \
  $SCRIPTPATH/cf-properties.yml \
  $SCRIPTPATH/cf-infrastructure-aws-development.yml \
  $SECRETS \
  > $MANIFEST

sed -i -- 's/10\.10\./10\.8\./g' $MANIFEST
