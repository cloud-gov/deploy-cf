#!/bin/bash

set -eux

## Extract current base configuration for the diego-cell instance group from upstream and apply custom ops files 
## NOTE: These ops files can only contain remove/replace for the diego-cell instance group for this to work in the future

## Create the starting point of a configured diego-cell for cg (minus scaling.ymls)
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

## Final file
touch diego-cell-iso-seg.yml

## Loop through and create iso seg ops file, intermediate files aren't deleted for debugging
for iso_seg_number in {1..5}
do

  ## Create ops file header
  cat > diego-cell-iso-seg${iso_seg_number}-header.yml <<EOF

# Add iso seg ${iso_seg_number} instance group
- type: replace
  path: /instance_groups/name=diego-cell:after
  value:
EOF

  ## Replace name of instance group, swap out provides/consumes values and indent 4 spaces
  sed "s/name: diego-cell/name: diego-cell-iso-seg${iso_seg_number}/" diego-cell_raw.yml > sed1.yml
  sed "s/iptables-tenant/iptables-iso-seg${iso_seg_number}/" sed1.yml > sed2.yml
  sed "s/cni_config_tenant/cni_config_iso-seg${iso_seg_number}/" sed2.yml > sed3.yml
  sed "s/vpa-tenant/vpa-iso-seg${iso_seg_number}/" sed3.yml > sed4.yml
  sed 's/^/    /' sed4.yml > diego-cell_indented-iso-seg${iso_seg_number}.yml

  cat > diego-cell-iso-seg${iso_seg_number}-footer.yml <<EOF

# Add iso seg ${iso_seg_number} placement tag
- type: replace
  path: /instance_groups/name=diego-cell-iso-seg${iso_seg_number}/jobs/name=rep/properties/diego/rep/placement_tags?/-
  value: diego-cell-iso-seg${iso_seg_number}

# Add iso seg ${iso_seg_number} to DNS aliases
- type: replace
  path: /addons/name=bosh-dns-aliases/jobs/name=bosh-dns-aliases/properties/aliases/domain=_.cell.service.cf.internal/targets/-
  value:
    query: '_'
    instance_group: diego-cell-iso-seg${iso_seg_number}
    deployment: ((deployment_name))
    network: ((network_name))
    domain: bosh
EOF

  ## Append the header, main, and footer
  cat diego-cell-iso-seg${iso_seg_number}-header.yml diego-cell_indented-iso-seg${iso_seg_number}.yml diego-cell-iso-seg${iso_seg_number}-footer.yml > diego-cell-iso-seg${iso_seg_number}.yml

  ## Merge into one file
  cat diego-cell-iso-seg${iso_seg_number}.yml >> diego-cell-iso-seg.yml
done

cp  diego-cell-iso-seg.yml diego-cell-iso-seg/diego-cell-iso-seg.yml
## return: diego-cell-iso-seg/diego-cell-iso-seg.yml