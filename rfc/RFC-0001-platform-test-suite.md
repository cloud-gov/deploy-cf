platform-test-suite
===================

## Context

The following outlines a test suite for cloud.gov's CF platform deployments. This includes conventions and contribution guides to for adding new tests to the test suite. The test suite is run and defined within [cg-deploy-cf's ci pipeline](../ci/) as a part of our deployment process.

## Goals

The test suite will provide:
- Improved confidence in deploying updates to the platform.
- A longitudinal set of artifacts to help us improve our platform's resilience, security, and performance.
- A concise methodology for maintaining and adding tests to the suite.

## Design

A test runner will request a series of endpoints over HTTP and expect a certain HTTP status code and HTTP body response based on the org, space, app, and endpoint.

## Implementation

The test suite will be broken out into different themes, units, categories such as: __space egress rules__, __app lifecycle__, __service integration__, __etc__. Based on the needs of the test suite's use case, tests could be run before, during, or after a deployment triggered by a commit to `cg-deploy-cf` master branch. Tests will be run by [cg-deploy-cf's ci pipeline](../ci/) as pipeline tasks and saved in subdirectories of `./ci` (_*Note: The test suite may migrate beyond `cg-deploy-cf` as it matures_).

### Defining the tests

Tests will be defined in a test matrix file by the space, endpoint, HTTP status code, and an optional HTTP response.

_Example tests matrix_

|Space|Endpoint|HTTP STATUS CODE|RESPONSE BODY|
|-----|--------|----------------|-------------|
|`test-space-1`| `/test-1`|`200`|`"Success"`|
|`test-space-1`| `/test-2`|`500`||
|`test-space-1`| `/test-3`|`200`|`{"Hello": "World"}`|
|...|

Test endpoints will be written into an app that is deployed to every space defined in the test matrix. Adding a new test will consist of:
- Updating the test matrix file with the `space`, `endpoint`, `HTTP status code`, and optional `HTTP response body`.
- Writing an `endpoint` in the test app with the expected behavior based on the corresponding update in the matrix file.

### The test lifecycle

The test lifecycle will be broken down into three sequential parts: deployment, running, and clean up. The test suite steps:
- Deployment
  - Gather org, space and app info for suite
  - Deploy the apps and supporting services into the defined org and spaces
- Running
  - The test runner will read the test matrix file
  - Run HTTP requests for each row in the defined test matrix file
  - Report the recorded behavior
- Clean up
  - Destroy the supporting services, apps, spaces, and orgs used in the test

## Further considerations

The platform is extensive and this is the initial work outlining the test suite. The following list is additional considerations which may or may not be included into the initial implementation.

- Should the runner be responsible for starting these apps?
- Should we include during-deployment tests, or just acceptance tests run after cf deploys?
- Should tests live in cg-deploy-cf? In separate repos as test apps? In a monorepo, but not cg-deploy-cf?
- Should we add additional orgs, spaces, or apps to focus on different aspects of the test suite.
- Should cloud.gov services or additional external services be leveraged in tests?
