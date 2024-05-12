#!/bin/bash

bosh interpolate \
  cf-manifests/bosh/varsfiles/terraform.yml \
  -l terraform-yaml/*.yml \
  > terraform-secrets/terraform.yml
