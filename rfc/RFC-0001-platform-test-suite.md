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

Test runner will request a series of endpoints over HTTP and expect a certain HTTP status code and HTTP body response based on the org, space, app, and endpoint.

## Initial implementation

Tests will be deployed by [cg-deploy-cf's ci pipeline](../ci/)

Test org and spaces will be defined by [cg-deploy-cf's test-suite terraform](../terraform/) and deployed to each instance of CF with three spaces
- _Org:_ `dev-platform-test`
  - _Space:_ `no-egress`
    - _ASG:_ `internal_only`
  - _Space:_ `closed-egress`
    - _ASG:_ `internal_only`
    - _ASG:_ `services_network`
  - _Space:_ `open-egress`
    - _ASG:_ `internal_only`
    - _ASG:_ `services_network`
    - _ASG:_ `public_networks`
- _Org:_ `staging-platform-test`
  - _Space:_ `no-egress`
    - _ASG:_ `internal_only`
  - _Space:_ `closed-egress`
    - _ASG:_ `internal_only`
    - _ASG:_ `services_network`
  - _Space:_ `open-egress`
    - _ASG:_ `internal_only`
    - _ASG:_ `services_network`
    - _ASG:_ `public_networks`
- _Org:_ `production-platform-test`
  - _Space:_ `no-egress`
    - _ASG:_ `internal_only`
  - _Space:_ `closed-egress`
    - _ASG:_ `internal_only`
    - _ASG:_ `services_network`
  - _Space:_ `open-egress`
    - _ASG:_ `internal_only`
    - _ASG:_ `services_network`
    - _ASG:_ `public_networks`

Tests will be defined in a test matrix file by the space, endpoint, HTTP status code, and an optional HTTP response.

_Example tests matrix_

|Space|Endpoint|HTTP STATUS CODE|RESPONSE BODY|
|-----|--------|----------------|-------------|
|`no-egress`| `/`|`200`|`"Success"`|
|`closed-egress`| `/test-external-api`|`500`||
|`open-egress`| `/test-external-api`|`200`|`{"Hello": "World"}`|
|...|

Test endpoints will be written into a single app that is deployed to every space in the org. Adding a new test will consist of:
- Updating the test matrix file with the `space`, `endpoint`, `HTTP status code`, and optional `HTTP response body`.
- Writing an `endpoint` in the test app with the expected behavior based on the corresponding update in the matrix file.

Tests will run when `cg-deploy-cf` is updated. Running the test suite will:
  - Deploy the app into each space in the test org
  - Run HTTP requests for each row in the defined test matrix file
  - Report expected and unexpected behavior
  - Fail tests if unexpected behavior occurs
  - Destroy the app in each test space

## Further considerations

The platform is extensive and this is the initial work outlining the test suite. The following list is additional considerations which may or may not be included into the initial implementation.

- Should the runner be responsible for starting these apps?
- Should we include during-deployment tests, or just acceptance tests run after cf deploys?
- Should tests live in cg-deploy-cf? In separate repos as test apps? In a monorepo, but not cg-deploy-cf?
- Should we add additional orgs, spaces, or apps to focus on different aspects of the test suite.
- Should cloud.gov services or additional external services be leveraged in tests?
