locals {
  domain_name         = var.iaas_stack_name == "staging" ? "fr-stage.cloud.gov" : "fr.cloud.gov"
  clone_dir           = "${path.module}/${var.git_clone_dir}"
  zip_output_filepath = "${path.module}/${var.zip_output_filename}"
}

data "cloudfoundry_domain" "fr_domain" {
  name = local.domain_name
}

data "cloudfoundry_service_plan" "external_domain" {
  service_offering_name = "external-domain"
  name                  = "domain-with-cdn-dedicated-waf"
}

data "cloudfoundry_org" "org" {
  name = var.organization_name
}

data "cloudfoundry_space" "hello_worlds" {
  name = var.space_name
  org  = data.cloudfoundry_org.org.id
}

resource "null_resource" "git_clone" {
  triggers = {
    on_every_apply = timestamp()
  }

  provisioner "local-exec" {
    command = "if [ ! -d \"${local.clone_dir}\" ]; then git clone ${var.source_code_repo} ${local.clone_dir}; fi"
  }
}

data "archive_file" "test_cdn_app_src" {
  depends_on = [null_resource.git_clone]

  output_path = local.zip_output_filepath
  source_dir  = "${local.clone_dir}/${var.source_code_path}"
  type        = "zip"
}

resource "cloudfoundry_route" "test_cdn_route" {
  domain = data.cloudfoundry_domain.fr_domain.id
  space  = data.cloudfoundry_space.hello_worlds.id
  host   = "test-cdn"
}

# DNS records:
# https://github.com/cloud-gov/cg-provision/blob/417000c786a101988c3edd965f7c78f66ad334fe/terraform/stacks/dns/staging.tf#L25-L30
# https://github.com/cloud-gov/cg-provision/blob/417000c786a101988c3edd965f7c78f66ad334fe/terraform/stacks/dns/production.tf#L12-L17
resource "cloudfoundry_service_instance" "test_cdn_instance" {
  name         = "test-cdn-service"
  type         = "managed"
  space        = data.cloudfoundry_space.hello_worlds.id
  service_plan = data.cloudfoundry_service_plan.external_domain.id
  parameters = jsonencode({
    "domains"               = "test-cdn.${local.domain_name}",
    "cache_policy"          = "Managed-CachingOptimized",
    "origin_request_policy" = "Managed-AllViewer"
  })
}

resource "cloudfoundry_app" "test-cdn" {
  name             = "test-cdn"
  buildpacks       = ["staticfile_buildpack"]
  org_name         = data.cloudfoundry_org.org.name
  space_name       = data.cloudfoundry_space.hello_worlds.name
  path             = local.zip_output_filepath
  source_code_hash = data.archive_file.test_cdn_app_src.output_sha256
  memory = "512M"
  disk_quota = "1024M"
  enable_ssh = true
  health_check_type = "port"
  instances = 1
  log_rate_limit_per_second = "-1"
  readiness_health_check_type = "process"
  stack = "cflinuxfs4"


  routes = [{
    protocol = "http1"
    route = cloudfoundry_route.test_cdn_route.url
  }]
}
