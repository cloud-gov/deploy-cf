## 18F Cloud Foundry Bosh Deployment Manifests and Concourse pipeline

This repo contains the source for the Bosh deployment manifest and deployment pipeline for the 18F Cloud Foundry deployment.

### How to generate the final manifest:

1. Install `spiff`
1. Copy the secrets examples to secrets files:
```
cp cf-secrets-example.main.yml cf-secrets.main.yml
cp cf-secrets-example.external.yml cf-secrets.external.yml
```
1. Change all the variables in CAPS from `cf-secrets.*.yml` to proper values
    1. Easily rotated secrets exist in the `main.yml` file, while external
       dependencies which can be either rotated in coordination with other
       resources (e.g. uaa.clients) or cannot be rotated at all (e.g. cc.db_encryption_key)
       exist in the `external.yml` file.
1. Run `./generate.sh`

### How to deploy the manifest:

Wherever you have your bosh installation run:

1. `CREATE EXTENSION "uuid-ossp"` on the Postgres RDS instance for ccdb
1. `bosh deployment manifest.yml`
1. `bosh deploy`

### How to generate all certificates:

Run the certificate generation script. For more information use the `--help`
flag.

1. `./generate-all-certificates.sh`
