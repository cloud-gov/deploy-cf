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
# Reverts this IP back for the cg-metrics
sed -i -- 's/10.9.101.63/10.10.101.63/g' manifest-staging.yml
sed -i -- 's/10.9.1.7\n/10.10.1.7\n/g' manifest-staging.yml
