#!/bin/sh

set -e

SECRETS=$1
CF_DEPLOYMENT=$2
BOSH_CACERT=$3
BOSH_TARGET=$4
BOSH_USERNAME=$5
BOSH_PASSWORD=$6
INSTANCE_COUNT_OVERRIDES=$7
ISOLATION_CELLS=$8
TERRAFORM_OUTPUT=$9
DIEGO_MANIFEST=$10

SCRIPT_PATH=$(dirname $0)
SECRETS_PATH=$(dirname $SECRETS)

# Download the CF manifest
echo Downloading CF manifest...
bosh --ca-cert $BOSH_CACERT target $BOSH_TARGET <<EOF 1>/dev/null 2>&1
$BOSH_USERNAME
$BOSH_PASSWORD
EOF
bosh download manifest $CF_DEPLOYMENT $SCRIPT_PATH/${CF_DEPLOYMENT}.yml

# Call the standard manifest generation script
echo Generating diego manifest...
diego-release-repo/scripts/generate-deployment-manifest \
  -c $SCRIPT_PATH/${CF_DEPLOYMENT}.yml \
  -i $SECRETS \
  -p $SECRETS \
  -s $SECRETS \
  -v $SCRIPT_PATH/release-versions.yml \
  -n $SCRIPT_PATH/$INSTANCE_COUNT_OVERRIDES \
  -x > $SCRIPT_PATH/diego-intermediate.yml

# Merge in our local additions
echo Adding local releases and properties...
spiff merge \
  diego-release-repo/manifest-generation/misc-templates/bosh.yml \
  $SECRETS \
  $SCRIPT_PATH/diego-jobs.yml \
  $SCRIPT_PATH/diego-intermediate.yml \
  $SCRIPT_PATH/diego-final.yml \
  > ${SCRIPT_PATH}/diego-intermediate-merged.yml

# Create additional cells with placement_tags by copying the job definition
# from the output of the upstream manifest generation scripts
# Spruce is used here as this can't be done with spiff, but we are stuck
# with spiff for the initial merge until upstream drops it from their scripts
echo Adding isolation cells...
spruce merge --prune terraform_outputs \
  ${SCRIPT_PATH}/diego-intermediate-merged.yml \
  ${SCRIPT_PATH}/${ISOLATION_CELLS} \
  ${TERRAFORM_OUTPUT} \
  > ${DIEGO_MANIFEST}
