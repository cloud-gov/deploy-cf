module "test_cdn" {
  count           = var.iaas_stack_name == "development" ? 0 : 1
  source          = "../../modules/test_cdn"
  iaas_stack_name = var.iaas_stack_name
  organization_name = cloudfoundry_org.cloud-gov.name
}
