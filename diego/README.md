## 18F Diego Deployment Manifests and Concourse pipeline

This repo contains the source for the BOSH deployment manifest and the Concourse pipeline for Diego at 18F.  The canonical documentation is in the [diego-release](https://github.com/cloudfoundry/diego-release) repo and in the [docs](https://github.com/cloudfoundry/diego-release/tree/develop/docs) directory.

### Diego manifest generation and deployment

1. Clone the `diego-release` repo:

    `git clone https://github.com/cloudfoundry/diego-release.git`

1. Clone this repo:

    `git clone https://github.com/18F/cg-deploy-diego.git`

1. Generate diego certs:

    ```
    cd diego-release
    scripts/generate-diego-certs
    ```

1. Copy the secrets example:

    ```
    cd ../cg-deploy-diego
    cp secrets.example.yml diego-secrets.yml
    ```

1. Change all the variables in CAPS in `diego-secrets.yml` to proper values and add certificates and keys found in `../diego-release/diego-certs/`.
1. Encrypt and place `diego-secrets.yml` in your secrets bucket.
1. Copy the pipeline credentials example:

     `cp credentials.example.yml credentials.yml`

1. Change all the variables in `credentials.yml` to proper values.
1. Create or update a Concourse pipeline for the deployment:

    `fly -t YOUR_TARGET set-pipeline -p deploy-diego -c pipeline.yml -l credentials.yml`

1. Unpause the pipeline:

    `fly -t YOUR_TARGET unpause-pipeline -p deploy-diego`

1. Trigger a job and watch the output:

    `fly -t YOUR_TARGET trigger-job -j deploy-diego/deploy-diego-staging -w`

### Integration with Cloud Foundry (CF)

1. Review the high-level [overview](https://github.com/cloudfoundry/diego-release/blob/master/docs/deploy-alongside-existing-cf.md).
1. To enable SSH support, see [this stub](https://github.com/cloudfoundry/diego-release/blob/master/stubs-for-cf-release/enable_diego_ssh_in_cf.yml).
1. To set diego as the default backend, set the Cloud Foundry property `cc.default_to_diego_backend` to `true`.
1. Redeploy CF to pick up the changes.


### Tests

Diego acceptance tests are integrated with the Cloud Foundry Acceptance Tests (CATs).

1. Configure the acceptance tests properties in the CF manifest.  See the [bosh-lite stub](https://github.com/cloudfoundry/cf-release/blob/master/templates/cf-infrastructure-bosh-lite.yml#L652-L660) for an example and the [CATs repo](https://github.com/cloudfoundry/cf-acceptance-tests) for more info.
1. The preferred way to run the tests is with `bosh run errand acceptance_tests` while targeting your CF deployment, or trigger them in the CF Concourse pipeline (not the pipeline here).

