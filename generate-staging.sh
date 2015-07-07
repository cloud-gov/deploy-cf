#!/bin/sh

spiff merge \
  cf-deployment.yml \
  cf-jobs.yml \
  cf-lamb.yml \
  cf-properties.yml \
  cf-infrastructure-aws-staging.yml \
  cf-secrets-staging.yml \
  > manifest-staging.yml
