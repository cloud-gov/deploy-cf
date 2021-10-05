#! /bin/bash

set -e

ORG=$CF_ORG
DOMAIN=$CF_APP_DOMAIN
TEST_MATRIX="./test-matrix"

## Read test matrix file and run each test per line

while IFS= read -r line; do

  ## Create array of arguments
  arg_array=($(echo $line | tr "," "\n"))

  ## Parse arguments
  space="${arg_array[0]}"
  url_path="${arg_array[1]}"
  expected_status_code="${arg_array[2]}"
  expected_response_body="${arg_array[3]}"
  baseurl="https://app-test-$space.$DOMAIN"
  endpoint="$baseurl$url_path"

  ## Curl the endpoint for status code and response body
  actual_status_code=$(curl -o /dev/null -s -w "%{http_code}\n" $endpoint)
  actual_response_body=$(curl -s $endpoint)

  ## Run status code check
  if [ "$actual_status_code" != "$expected_status_code" ]; then
    echo "Failed: Status code check for ${space} at $endpoint"
    echo "Expected: $expected_status_code"
    echo "Actual: ${actual_status_code}"
    exit 1
  fi

  ## Run response body check
  if [ "\"\"" != "$expected_response_body" ]; then
    if [ "$actual_response_body" != "$expected_response_body" ]; then
      echo "Failed: Response body check for ${space} at $endpoint"
      echo "Expected: $expected_response_body"
      echo "Actual: ${actual_response_body}"
      exit 1
    fi
  fi
done < $TEST_MATRIX
