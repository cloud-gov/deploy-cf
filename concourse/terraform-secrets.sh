#!/bin/bash

ls -R

bosh interpolate \
  cf-manifests/bosh/varsfiles/terraform.yml \
  -l terraform-yaml/$TERRAFORM_STATE_FILE \
  > terraform-secrets/terraform.yml
