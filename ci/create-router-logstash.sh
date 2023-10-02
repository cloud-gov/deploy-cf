#!/bin/bash

set -eux

## Extract current base configuration for the router instance group from upstream
bosh int cf-deployment/cf-deployment.yml --path /instance_groups/name=router > router_raw.yml

## Create ops file header
cat > router_logstash.yml <<EOF
- type: replace
  path: /instance_groups/name=router:after
  value:
EOF

## Replace name of instance group and indent 4 spaces
sed 's/name: router/name: router-logstash/' router_raw.yml > router_name.yml
sed 's/^/    /' router_name.yml > router_indented.yml


## Append the router yaml to the ops file header
cat router_indented.yml >> router_logstash.yml
cp router_logstash.yml router-logstash/router_logstash.yml

## return: router-logstash/router_logstash.yml
