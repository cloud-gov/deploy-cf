#!/bin/sh

set -e -x

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

SECRETS=$SCRIPTPATH/cf-secrets-staging.yml
MANIFEST=$SCRIPTPATH/manifest-staging.yml

declare -a files=($@)
length=${#@}
last_file=$length-1

if [ $length -gt 0 ]
then
  SECRETS=''
  for file in "${files[@]}"
  do
    if [[ $file == "${files[last_file]}" ]]
    then
      MANIFEST=$file
    else
      SECRETS="${SECRETS} ${file}"
    fi
  done
fi

spiff merge \
  $SCRIPTPATH/cf-deployment.yml \
  $SCRIPTPATH/cf-resource-pools.yml \
  $SCRIPTPATH/cf-jobs.yml \
  $SCRIPTPATH/cf-properties.yml \
  $SCRIPTPATH/cf-infrastructure-aws-staging.yml \
  $SECRETS \
  > $MANIFEST

sed -i -- 's/10.10/10.9/g' $MANIFEST
