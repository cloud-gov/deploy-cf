resource "cloudfoundry_org" "cloud-gov" {
  name = "cloud-gov"
}

resource "cloudfoundry_org" "acceptance_tests" {
  name = "cloud-gov-acceptance-tests"
}

data "cloudfoundry_org" "cloud-gov-operators" {
  name = "cloud-gov-operators"
}

# Federalist/Pages

data "cloudfoundry_org" "gsa-18f-federalist" {
  name = "gsa-18f-federalist"
}

# Devtools

resource "cloudfoundry_org" "cloud-gov-devtools" {
  name = var.devtools_org_name
}

resource "cloudfoundry_org" "cloud-gov-devtools-secondary" {
  count = var.devtools_secondary_org ? 1 : 0
  name  = var.devtools_org_name_secondary
}


# Notify

resource "cloudfoundry_org" "cloud-gov-notify" {
  name = var.notify_org_name
}

resource "cloudfoundry_org" "cloud-gov-notify-secondary" {
  count = var.notify_secondary_org ? 1 : 0
  name  = var.notify_org_name_secondary
}
