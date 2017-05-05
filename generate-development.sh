#!/bin/sh

set -e -x

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

SECRETS=$SCRIPTPATH/cf-secrets-development.yml
MANIFEST=$SCRIPTPATH/manifest-development.yml

declare -a files=($@)
length=${#@}

if [ $length -gt 0 ]
then
  SECRETS="${files[@]:0:length-1}"
  MANIFEST="${files[@]:length-1}"
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
