#!/bin/bash

set -eux

## Extract current base configuration for the diego-cell instance group from upstream and apply custom ops files 
## NOTE: These ops files can only contain remove/replace for the diego-cell instance group for this to work in the future
bosh int \
  cf-deployment/cf-deployment.yml \
  -o cf-manifests/bosh/opsfiles/log-levels-diego-cell.yml \
  -o cf-manifests/bosh/opsfiles/diego-cell-consumes-provides.yml \
  -o cf-manifests/bosh/opsfiles/diego-cell-disk.yml \
  -o cf-manifests/bosh/opsfiles/disable-secure-service-credentials-diego-cell.yml \
  -o cf-manifests/bosh/opsfiles/diego-rds-certs-diego-cell.yml \
  -o cf-manifests/bosh/opsfiles/meta-data-v2-diego-cell.yml \
  -o cf-manifests/bosh/opsfiles/diego-cpu-entitlement-diego-cell.yml \
  --path /instance_groups/name=diego-cell > diego-cell_raw.yml

## Create ops file header
cat > diego-platform-cell.yml <<EOF
- type: replace
  path: /instance_groups/name=diego-cell:before
  value:
EOF

## Replace name of instance group, swap out provides/consumes values and indent 4 spaces
sed 's/name: diego-cell/name: diego-platform-cell/' diego-cell_raw.yml > sed1.yml
sed 's/iptables-tenant/iptables-platform/' sed1.yml > sed2.yml
sed 's/cni_config_tenant/cni_config_platform/' sed2.yml > sed3.yml
sed 's/vpa-tenant/vpa-platform/' sed3.yml > sed4.yml
sed 's/^/    /' sed4.yml > diego-platform-cell_indented.yml

## Append the platform-diego-cell yaml to the ops file header
cat diego-platform-cell_indented.yml >>  diego-platform-cell.yml
cp  diego-platform-cell.yml diego-platform-cell/diego-platform-cell.yml

## return: diego-platform-cell/diego-platform-cell.yml