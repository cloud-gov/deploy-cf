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
