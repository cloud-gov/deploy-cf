#!/bin/bash

set -eux

## Extract current base configuration for the diego-cell instance group from upstream and apply custom ops files 
## NOTE: These ops files can only contain remove/replace for the diego-cell instance group for this to work in the future

echo "Creating isolation segments for: ${ISO_SEG_NAMES}"...

## Create the starting point of a configured diego-cell for cg (minus scaling-*.ymls)
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


## Loop through and create a single iso seg ops file, intermediate files aren't deleted for debugging

for iso_seg_name in $ISO_SEG_NAMES; do

  echo "Creating isolation segment ${iso_seg_name}"...

  ## Create ops file header - Always start with the instance group declaration
  cat > diego-cell-iso-seg${iso_seg_name}-header.yml <<EOF

# Add iso seg ${iso_seg_name} instance group
- type: replace
  path: /instance_groups/name=diego-cell:after
  value:
EOF

  ## Create ops file body - replace name of instance group, swap out provides/consumes values and indent 4 spaces
  sed "s/name: diego-cell/name: diego-cell-iso-seg${iso_seg_name}/" diego-cell_raw.yml > sed1.yml
  sed "s/iptables-tenant/iptables-iso-seg${iso_seg_name}/" sed1.yml > sed2.yml
  sed "s/cni_config_tenant/cni_config_iso-seg${iso_seg_name}/" sed2.yml > sed3.yml
  sed "s/vpa-tenant/vpa-iso-seg${iso_seg_name}/" sed3.yml > sed4.yml
  sed 's/^/    /' sed4.yml > diego-cell_indented-iso-seg${iso_seg_name}.yml

  ## Create ops file footer - All the "replace" that can only be run once the instance group exists (order matters)
  cat > diego-cell-iso-seg${iso_seg_name}-footer.yml <<EOF

# Add iso seg ${iso_seg_name} placement tag
- type: replace
  path: /instance_groups/name=diego-cell-iso-seg${iso_seg_name}/jobs/name=rep/properties/diego/rep/placement_tags?/-
  value: diego-cell-iso-seg${iso_seg_name}

# Add iso seg ${iso_seg_name} to DNS aliases
- type: replace
  path: /addons/name=bosh-dns-aliases/jobs/name=bosh-dns-aliases/properties/aliases/domain=_.cell.service.cf.internal/targets/-
  value:
    query: '_'
    instance_group: diego-cell-iso-seg${iso_seg_name}
    deployment: ((deployment_name))
    network: ((network_name))
    domain: bosh

# Set default instance type since the one upstream has doesn't exists. Override this in scaling-*.yml
- type: replace
  path: /instance_groups/name=diego-cell-iso-seg${iso_seg_name}/vm_type
  value: t3.xlarge

# Start with 2 instances.  Override this in scaling-*.yml
- type: replace
  path: /instance_groups/name=diego-cell-iso-seg${iso_seg_name}/instances
  value: 2
EOF

  ## Append the header, main, and footer for this iso-seg
  cat diego-cell-iso-seg${iso_seg_name}-header.yml diego-cell_indented-iso-seg${iso_seg_name}.yml diego-cell-iso-seg${iso_seg_name}-footer.yml > diego-cell-iso-seg${iso_seg_name}.yml

  ## Merge this iso-seg into one file which will have all of them at the end of the loop
  cat diego-cell-iso-seg${iso_seg_name}.yml >> diego-cell-iso-seg.yml
done

## Either return the iso-seg file or a comment only file so "bosh deploy" will work in the main pipeline
if [ -z "$ISO_SEG_NAMES" ]; then
  cp  diego-cell-iso-seg.yml diego-cell-iso-seg/diego-cell-iso-seg.yml
else
  cat > diego-cell-iso-seg/diego-cell-iso-seg.yml << EOF
# Intentionally left blank
EOF
fi

echo "Final iso seg ops file written to diego-cell-iso-seg/diego-cell-iso-seg.yml"

## return: diego-cell-iso-seg/diego-cell-iso-seg.yml