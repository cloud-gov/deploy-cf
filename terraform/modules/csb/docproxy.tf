resource "cloudfoundry_app" "docproxy" {
  name       = "docproxy"
  org_name   = var.org_name
  space_name = var.space_name

  docker_image = "${var.docproxy_docker_image_name}${var.docproxy_docker_image_version}"
  docker_credentials = {
    "username" = var.ecr_access_key_id
    "password" = var.ecr_secret_access_key
  }

  command   = "/app/docproxy"
  instances = var.docproxy_instances
  memory    = "128M"

  environment = {
    "BROKER_URL" = cloudfoundry_route.csb.url
    "PORT"       = 8080
  }
}

data "cloudfoundry_domain" "cloudgov_platform_domain" {
  name = var.docproxy_domain
}

resource "cloudfoundry_route" "docproxy" {
  domain = data.cloudfoundry_domain.cloudgov_platform_domain.id
  space  = data.cloudfoundry_space.brokers.id
  host   = "services"

  destinations = [{
    app_id = cloudfoundry_app.docproxy.id
  }]
}

data "cloudfoundry_service_plans" "external_domain" {
  service_offering_name = "external-domain"
  name                  = "domain"
  service_broker_name   = "external-domain-broker"
}

resource "cloudfoundry_service_instance" "docproxy_external_domain" {
  name  = "docproxy-domain"
  space = data.cloudfoundry_space.brokers.id
  type  = "managed"

  service_plan = data.cloudfoundry_service_plans.external_domain.service_plans[0].id

  parameters = jsonencode({
    domains = ["services.${var.docproxy_domain}"]
  })
}
