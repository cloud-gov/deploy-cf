#!/bin/bash

bosh interpolate \
  cf-manifests/bosh/varsfiles/terraform.yml \
  -l $TERRAFORM_STATE_FILE \
  > terraform-secrets/terraform.yml
