#!/bin/sh

spiff merge \
  cf-deployment.yml \
  cf-resource-pools.yml \
  cf-jobs.yml \
  cf-lamb.yml \
  cf-properties.yml \
  cf-infrastructure-aws-staging.yml \
  cf-secrets-staging.yml \
  > manifest-staging.yml

sed -i -- 's/10.10/10.9/g' manifest-staging.yml
