#! /bin/bash

# Run deploy-env, run-tests, and clean

set -e


echo "Deploying test environment"
./deploy.sh

echo "Running tests"
./run-tests.sh

echo "Cleaning up test environment"
./clean.sh
