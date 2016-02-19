## 18F Cloud Foundry Bosh Deployment Manifests and Concourse pipeline

This repo contains the source for the Bosh deployment manifest and deployment pipeline for the 18F Cloud Foundry deployment.

### How to generate the final manifest:

1. Install `spiff`
1. Copy the secrets example to secrets file:
`cp cf-secrets-example.yml cf-secrets.yml`
1. Change all the variables in CAPS from `cf-secrets.yml` to proper values
1. Run `./generate.sh`

### How to deploy the manifest:

Wherever you have your bosh installation run:

1. `CREATE EXTENSION "uuid-ossp"` on the Postgres RDS instance for ccdb
1. `bosh deployment manifest.yml`
1. `bosh deploy`
