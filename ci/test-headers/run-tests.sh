#! /bin/bash

set -e

ORG=$CF_ORG
DOMAIN=$CF_APP_DOMAIN
TEST_MATRIX="./test-matrix"

# Colors
red='\033[0;31m';
green='\033[0;32m';
cyan='\033[0;36m';
no_color='\033[0m';

# Go into test directory
pushd cf-manifests/ci/test-headers

## Read test matrix file and run each test per line

echo -e "\n\n${cyan}Running Header Test Suite${no_color}\n\n"

while IFS= read -r line; do

  ## Create array of arguments
  arg_array=($(echo $line | tr "," "\n"))

  ## Parse arguments
  url_path="${arg_array[0]}"
  expected_status_code="${arg_array[1]}"
  expected_response_body="${arg_array[2]}"
  baseurl="https://header-test.$DOMAIN"
  endpoint="$baseurl$url_path"

  ## Curl the endpoint for status code and response body
  actual_status_code=$(curl -o /dev/null -s -w "%{http_code}\n" $endpoint)
  actual_response_body=$(curl -s $endpoint)

  ## Run status code check
  if [ "$actual_status_code" != "$expected_status_code" ]; then
    echo ""
    echo -e "${red}Failed: Status code check for ${space} at $endpoint${no_color}"
    echo -e "${cyan}Expected: $expected_status_code${no_color}"
    echo -e "${red}Actual: ${actual_status_code}${no_color}"
    echo ""
    exit 1
  else
    echo -e "${green}Success: Status code check for ${space} at $endpoint${no_color}"
  fi

  ## Run response body check
  if [ "\"\"" != "$expected_response_body" ]; then
    if [ "$actual_response_body" != "$expected_response_body" ]; then
      echo ""
      echo -e "${red}Failed: Response body check for ${space} at $endpoint${no_color}"
      echo -e "${cyan}Expected: $expected_response_body${no_color}"
      echo -e "${red}Actual: ${actual_response_body}${no_color}"
      echo ""
      exit 1

    else
      echo -e "${green}Success: Response body check for ${space} at $endpoint${no_color}"
    fi
  fi
done < $TEST_MATRIX
