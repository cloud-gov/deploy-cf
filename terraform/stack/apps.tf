module "test_cdn" {
  count           = var.iaas_stack_name == "development" ? 0 : 1
  source          = "../modules/test_cdn"
  iaas_stack_name = var.iaas_stack_name
  organization_id = cloudfoundry_org.cloud-gov.id

  providers = {
    cloudfoundry = cloudfoundry
  }
}

module "csb" {
  source = "../modules/csb"

  count = var.iaas_stack_name == "development" ? 1 : 0

  iaas_stack_name = var.iaas_stack_name

  rds_host     = data.terraform_remote_state.iaas.outputs.csb.rds.host
  rds_port     = data.terraform_remote_state.iaas.outputs.csb.rds.port
  rds_url      = data.terraform_remote_state.iaas.outputs.csb.rds.url
  rds_name     = data.terraform_remote_state.iaas.outputs.csb.rds.name
  rds_username = data.terraform_remote_state.iaas.outputs.csb.rds.username
  rds_password = data.terraform_remote_state.iaas.outputs.csb.rds.password

  ecr_access_key_id                = data.terraform_remote_state.iaas.outputs.csb.ecr_user.access_key_id_curr
  ecr_secret_access_key            = data.terraform_remote_state.iaas.outputs.csb.ecr_user.secret_access_key_curr
  instances                        = 1
  cg_smtp_aws_ses_zone             = var.csb_cg_smtp_aws_ses_zone
  aws_access_key_id_govcloud       = data.terraform_remote_state.iaas.outputs.csb.broker_user.access_key_id_curr
  aws_secret_access_key_govcloud   = data.terraform_remote_state.iaas.outputs.csb.broker_user.secret_access_key_curr
  aws_region_govcloud              = var.csb_aws_region_govcloud
  aws_access_key_id_commercial     = data.terraform_remote_state.external.outputs.csb.broker_user.access_key_id_curr
  aws_secret_access_key_commercial = data.terraform_remote_state.external.outputs.csb.broker_user.secret_access_key_curr
  aws_region_commercial            = var.csb_aws_region_commercial

  org_name = var.csb_org_name
  space_name = var.csb_space_name
  docker_image_name = var.csb_docker_image_name
  broker_route_domain = var.csb_broker_route_domain
}
