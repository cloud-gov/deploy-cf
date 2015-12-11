#!/bin/sh

set -e -x

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

SECRETS=$SCRIPTPATH/cf-secrets-staging.yml
MANIFEST=$SCRIPTPATH/manifest-staging.yml
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
  $SCRIPTPATH/cf-lamb.yml \
  $SCRIPTPATH/cf-properties.yml \
  $SCRIPTPATH/cf-infrastructure-aws-staging.yml \
  $SECRETS \
  > $MANIFEST

sed -i -- 's/10.10/10.9/g' $MANIFEST
# Reverts this IP back for the cg-metrics
sed -i -- 's/10.9.101.63/10.10.101.63/g' $MANIFEST
# Reverts this IP back for dns
sed -i -- '/dns:/{n;s/10.9.1.7/10.10.1.7/}' $MANIFEST
