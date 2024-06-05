module "vpc" {
  source = "github.com/cloud-gov/cg-provision//terraform/modules//bosh_vpc_v2?ref=f140"

  stack_description                 = var.stack_description
  vpc_cidr                          = var.vpc_cidr
  availability_zones                = var.availability_zones
  aws_default_region                = var.aws_default_region
  private_cidrs                     = var.private_cidrs
  public_cidrs                      = var.public_cidrs
  restricted_ingress_web_cidrs      = var.restricted_ingress_web_cidrs
  restricted_ingress_web_ipv6_cidrs = var.restricted_ingress_web_ipv6_cidrs
  nat_gateway_instance_type         = var.nat_gateway_instance_type
  monitoring_security_group_cidrs   = []
  concourse_security_group_cidrs    = []
  bosh_default_ssh_public_key       = var.bosh_default_ssh_public_key
  s3_gateway_policy_accounts        = var.s3_gateway_policy_accounts
}