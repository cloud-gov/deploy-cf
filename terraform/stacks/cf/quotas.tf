resource "cloudfoundry_org_quota" "default-tts" {
  name                     = "default-tts"
  allow_paid_service_plans = true
  total_memory             = 81920
  total_routes             = 1000
  total_services           = 200
  total_route_ports        = -1
}

# Federalist/ Pages

resource "cloudfoundry_space_quota" "tiny" {
    name = "tiny-tf-managed"
    allow_paid_service_plans = true
    total_memory = 1024
    total_routes             = -1
    total_services           = -1
    total_route_ports        = -1
    org = data.cloudfoundry_org.gsa-18f-federalist.id
}
