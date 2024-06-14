module "cf_blobstore_policy" {
  source            = "github.com/cloud-gov/cg-provision//terraform/modules/iam_role_policy/cf_blobstore"
  policy_name       = "${var.stack_description}-cf-blobstore"
  aws_partition     = data.aws_partition.current.partition
  buildpacks_bucket = module.buildpacks.bucket_name
  packages_bucket   = module.cc-packages.bucket_name
  resources_bucket  = module.cc-resoures.bucket_name
  droplets_bucket   = module.droplets.bucket_name
}

module "platform_role" {
  source    = "github.com/cloud-gov/cg-provision//terraform/modules/iam_role"
  role_name = "${var.stack_description}-platform"
}