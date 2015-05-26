#!/bin/sh

spiff merge \
  cf-deployment.yml \
  cf-jobs.yml \
  cf-lamb.yml \
  cf-properties.yml \
  cf-infrastructure-aws.yml \
  cf-secrets.yml \
  > manifest.yml