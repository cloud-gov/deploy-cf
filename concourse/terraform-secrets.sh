#!/bin/bash

bosh interpolate \
  cg-deploy-cf/bosh/varsfiles/terraform.yml \
  -l terraform-yaml/*.yml \
  > terraform-secrets/terraform.yml
