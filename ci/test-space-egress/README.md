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
  - _Space:_ `closed-egress`
    - _ASG:_ `dns`
  - _Space:_ `restricted-egress`
    - _ASG:_ `dns`
    - _ASG:_ `trusted_local_networks`
  - _Space:_ `public-egress`
    - _ASG:_ `dns`
    - _ASG:_ `trusted_local_networks`
    - _ASG:_ `public_networks`

Tests will be defined in a test matrix file by the space, endpoint, HTTP status code, and an optional HTTP response.

### Test Matrix

|Space|Endpoint|HTTP STATUS CODE|RESPONSE BODY|
|-----|--------|----------------|-------------|
|`closed-egress`| `/`|`200`|`"Success"`|
|`closed-egress`| `/test-internal-network`|`500`||
|`closed-egress`| `/test-external-network`|`500`||
|`restricted-egress`| `/`|`200`|`"Success"`|
|`restricted-egress`| `/test-internal-network`|`200`|`"Success"`|
|`restricted-egress`| `/test-external-network`|`500`||
|`public-egress`| `/`|`200`|`"Success"`|
|`public-egress`| `/test-internal-network`|`200`|`"Success"`|
|`public-egress`| `/test-external-network`|`200`|`"Success"`|


### Deployment

### Runner
