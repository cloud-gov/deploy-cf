#! /bin/bash

set -e

ENV=$1
ORG="test-egress-${ENV}"
SPACE_NO_EGRESS="no-egress"
SPACE_CLOSED_EGRESS="closed-egress"
SPACE_OPEN_EGRESS="open-egress"
ASG_INTERNAL_NETWORKS="trusted_local_networks_egress"
ASG_PUBLIC_NETWORKS="public_networks_egress"

## Create org

echo "cf create-org $ORG"

## Create spaces

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  echo "cf create-space $space -o $ORG"
done

## Apply security groups

### Bind to closed egress space
echo "cf bind-security-group $ASG_INTERNAL_NETWORKS $ORG --space $SPACE_CLOSED_EGRESS"

### Bind to open egress space
echo "cf bind-security-group $ASG_INTERNAL_NETWORKS $ORG --space $SPACE_OPEN_EGRESS"
echo "cf bind-security-group $ASG_PUBLIC_NETWORKS $ORG --space $SPACE_OPEN_EGRESS"

## Push apps

for space in $SPACE_NO_EGRESS $SPACE_CLOSED_EGRESS $SPACE_OPEN_EGRESS
do
  echo "cf target -o $ORG -s $space"
  echo "cf push $space-app";
done
