locals {
  domain_name = var.iaas_stack_name == "staging" ? "fr-stage.cloud.gov" : "fr.cloud.gov"
}

data "cloudfoundry_domain" "fr_domain" {
  name = local.domain_name
}

data "cloudfoundry_service" "external_domain" {
  name = "external-domain"
}

data "cloudfoundry_space" "hello_worlds" {
  name = var.space_name
  org  = var.organization_id
}

resource "zipper_file" "test_cdn_src" {
  source      = "https://github.com/cloud-gov/cf-hello-worlds/tree/main/static"
  output_path = "test-static-app.zip"
}

resource "cloudfoundry_route" "test_cdn_route" {
  domain   = data.cloudfoundry_domain.fr_domain.id
  space    = data.cloudfoundry_space.hello_worlds.id
  hostname = "test-cdn"
}

# DNS records:
# https://github.com/cloud-gov/cg-provision/blob/417000c786a101988c3edd965f7c78f66ad334fe/terraform/stacks/dns/staging.tf#L25-L30
# https://github.com/cloud-gov/cg-provision/blob/417000c786a101988c3edd965f7c78f66ad334fe/terraform/stacks/dns/production.tf#L12-L17
resource "cloudfoundry_service_instance" "test_cdn_instance" {
  name         = "test-cdn-service"
  space        = data.cloudfoundry_space.hello_worlds.id
  service_plan = data.cloudfoundry_service.external_domain.service_plans["domain-with-cdn"]
  json_params  = "{\"domains\": \"test-cdn.${local.domain_name}\"}"
}

resource "cloudfoundry_app" "test-cdn" {
  name             = "test-cdn"
  buildpack        = "staticfile_buildpack"
  space            = data.cloudfoundry_space.hello_worlds.id
  path             = zipper_file.test_cdn_src.output_path
  source_code_hash = zipper_file.test_cdn_src.output_sha

  routes {
    route = cloudfoundry_route.test_cdn_route.id
  }

  service_binding {
    service_instance = cloudfoundry_service_instance.test_cdn_instance.id
  }
}
