resource "cloudfoundry_org_quota" "default-tts" {
  name                     = "default-tts"
  allow_paid_service_plans = true
  total_memory             = 81920
  total_routes             = 1000
  total_services           = 200
  orgs                     = [cloudfoundry_org.cloud-gov.id, cloudfoundry_org.acceptance_tests.id, data.cloudfoundry_org.cloud-gov-operators.id]
}

# Federalist/ Pages

resource "cloudfoundry_space_quota" "tiny" {
  name                     = "tiny-tf-managed"
  allow_paid_service_plans = true
  total_app_tasks          = 5
  total_memory             = 1024
  org                      = data.cloudfoundry_org.gsa-18f-federalist.id
  spaces                   = [cloudfoundry_space.email.id]
}

# Devtools

resource "cloudfoundry_org_quota" "devtools" {
  name                     = "devtools"
  allow_paid_service_plans = true
  total_memory             = 40960
  total_routes             = 100
  total_services           = 100
  org                      = [cloudfoundry_org.cloud-gov-devtools.id]
}

resource "cloudfoundry_org_quota" "devtools-secondary" {
  count                    = var.devtools_secondary_org ? 1 : 0
  name                     = "devtools-secondary"
  allow_paid_service_plans = true
  total_memory             = 10240
  total_routes             = 100
  total_services           = 100
  org                      = [cloudfoundry_org.cloud-gov-devtools-secondary[0].id]
}
