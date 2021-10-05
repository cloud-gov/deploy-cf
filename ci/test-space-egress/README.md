test-egress
===========

A test suite to verify the app security-group rules are allowing certain egress rules based on the app's space.
The

## Background

Tests will be deployed by [cg-deploy-cf's ci pipeline](../ci/pipeline.yml) and they are defined in [cg-deploy-cf's ci test-egress](./README.md).


## Setup

### Space App Security Groups

Test org and spaces will be defined by [cg-deploy-cf's test-suite terraform](../terraform/) and deployed to each instance of CF with three spaces
- _Org:_ `platform-egress-test`
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

### Test Matrix

|Space|Endpoint|HTTP STATUS CODE|RESPONSE BODY|
|-----|--------|----------------|-------------|
|`no-egress`| `/`|`200`|`"Success"`|
|`no-egress`| `/test-internal-network`|`500`||
|`no-egress`| `/test-external-network`|`500`||
|`closed-egress`| `/`|`200`|`"Success"`|
|`closed-egress`| `/test-internal-network`|`200`|`"Success"`|
|`closed-egress`| `/test-external-network`|`500`||
|`open-egress`| `/`|`200`|`"Success"`|
|`open-egress`| `/test-internal-network`|`200`|`"Success"`|
|`open-egress`| `/test-external-network`|`200`|`"Success"`|


### Deployment

### Runner
