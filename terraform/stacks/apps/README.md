# Apps stack

This stack is for deploying applications into Cloud Foundry. These applications are part of the platform offering, like service brokers.

## Design

There are three state files in play:

- The state file for the stack itself, which is not referenced explicitly in the `.tf` files
- The state file for the GovCloud stack deployed by `terraform-provision`, referred to as `iaas`
- The state file for the Commercial stack deployed by `terraform-provision`, referred to as `external`
