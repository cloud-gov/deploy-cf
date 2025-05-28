resource "cloudfoundry_isolation_segment" "platform" {
  name = "platform"
}

resource "cloudfoundry_isolation_segment_entitlement" "platform" {
  segment = cloudfoundry_isolation_segment.platform.id
  orgs = [
    cloudfoundry_org.cloud-gov.id
  ]
  default = false
}

resource "cloudfoundry_isolation_segment" "devtools" {
  count = var.iaas_stack_name == "development" ? 1 : 0
  name  = "devtools"
}

resource "cloudfoundry_isolation_segment_entitlement" "devtools" {
  count   = var.iaas_stack_name == "development" ? 1 : 0
  segment = cloudfoundry_isolation_segment.devtools.id
  orgs = [
    cloudfoundry_org.cloud-gov-devtools.id
  ]
  default = false
}
