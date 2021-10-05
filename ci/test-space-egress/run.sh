#! /bin/bash

# Run deploy-env, run-tests, and clean

set -e

# Clean up deployment if an error occurs
onerr() {
  ./clean.sh
  exit 1
}

trap 'onerr' ERR

# Deploy the org, spaces, and apps
echo "Deploying test environment"
./deploy.sh

# Run the tests against the endpoint
echo "Running tests"
./run-tests.sh

# Cleanup and remove the apps, spaces, and org
echo "Cleaning up test environment"
./clean.sh
