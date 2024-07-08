resource "cloudfoundry_org" "cloud-gov" {
  name  = "cloud-gov"
  quota = cloudfoundry_org_quota.default-tts.id
}

resource "cloudfoundry_org" "acceptance_tests" {
  name  = "cloud-gov-acceptance-tests"
  quota = cloudfoundry_org_quota.default-tts.id
}

# Federalist/Pages

data "cloudfoundry_org" "gsa-18f-federalist" {
  name  = "gsa-18f-federalist"
}
