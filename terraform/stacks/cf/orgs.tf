resource "cloudfoundry_org" "cloud-gov" {
  name  = "cloud-gov"
  provider = cloudfoundryv3
}

resource "cloudfoundry_org" "acceptance_tests" {
  name = "cloud-gov-acceptance-tests"
  provider = cloudfoundryv3
}

# Federalist/Pages

data "cloudfoundry_org" "gsa-18f-federalist" {
  name  = "gsa-18f-federalist"
  provider = cloudfoundryv3
}
