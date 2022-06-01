test-headers
===========

An app and test suite to validate secureproxy is correctly setting default headers
and honoring upstream headers

## Background

Tests will be deployed by [cg-deploy-cf's ci pipeline](../ci/pipeline.yml) and they are defined in [cg-deploy-cf's ci test-headers](./README.md).


## Setup

A test org and space are created in the `deploy-test-env` script

Tests are defined in a test matrix file by the endpoint, HTTP status code, and an optional HTTP response.
