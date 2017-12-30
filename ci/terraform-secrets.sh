#!/bin/bash

bosh interpolate \
  cf-manifests/bosh/varsfiles/terraform.yml \
  -l terraform-yaml/state.yml \
  > terraform-secrets/terraform.yml
