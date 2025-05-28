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
  name = "diego-cell-iso-seg-devtools"
}

#resource "cloudfoundry_isolation_segment_entitlement" "devtools" {
#  segment = cloudfoundry_isolation_segment.devtools.id
#  orgs = [
#    cloudfoundry_org.cloud-gov-devtools.id
#  ]
#  default = true
#}
