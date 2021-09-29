#! /bin/bash

set -e

ENV=$1
PREFIX="test-egress-${ENV}"
ORG="${PREFIX}-org"
SPACE_NO_EGRESS="${PREFIX}-no-egress"
SPACE_CLOSED_EGRESS="${PREFIX}-closed-egress"
SPACE_OPEN_EGRESS="${PREFIX}-open-egress"
ASG_INTERNAL_NETWORKS="trusted_local_networks_egress"
ASG_PUBLIC_NETWORKS="public_networks_egress"

## Delete apps

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  echo "cf target -o $ORG -s $space"
  echo "cf delete -f $space-app";
done

## Delete spaces

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  echo "cf delete-space $space -o $ORG -f"
done

## Delete org

echo "cf delete-org $ORG -f"
