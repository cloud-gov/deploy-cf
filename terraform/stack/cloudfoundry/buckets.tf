module "cc-resoures" {
  source        = "github.com/cloud-gov/cg-provision//terraform/modules/s3_bucket/encrypted_bucket_v2?ref=f140"
  bucket        = "${var.environment}-cf-cc-resources"
  aws_partition = data.aws_partition.current.id
}

module "buildpacks" {
  source        = "github.com/cloud-gov/cg-provision//terraform/modules/s3_bucket/encrypted_bucket_v2?ref=f140"
  bucket        = "${var.environment}-cf-buildpacks"
  aws_partition = data.aws_partition.current.id
}

module "cc-packages" {
  source        = "github.com/cloud-gov/cg-provision//terraform/modules/s3_bucket/encrypted_bucket_v2?ref=f140"
  bucket        = "${var.environment}-cf-cc-packages"
  aws_partition = data.aws_partition.current.id
}

module "droplets" {
  source        = "github.com/cloud-gov/cg-provision//terraform/modules/s3_bucket/encrypted_bucket_v2?ref=f140"
  bucket        = "${var.environment}-cf-droplets"
  aws_partition = data.aws_partition.current.id
}


