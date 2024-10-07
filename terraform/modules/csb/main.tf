data "cloudfoundry_space" "services" {
  name     = var.space_name
  org_name = var.org_name
}

resource "random_password" "csb_app_password" {
  length      = 32
  special     = false
  min_special = 0
  min_upper   = 5
  min_numeric = 5
  min_lower   = 5
}

resource "cloudfoundry_app" "csb" {
  name  = "csb"
  space = data.cloudfoundry_space.services.id

  docker_image = "${var.docker_image_name}${var.docker_image_version}"
  docker_credentials = {
    "username" = var.ecr_access_key_id
    "password" = var.ecr_secret_access_key
  }

  command    = "/app/csb serve"
  instances  = var.instances
  memory     = 1 * 1024 # 1GB
  disk_quota = 7 * 1024 # 7GB

  environment = {
    # General broker configuration
    DB_HOST                    = var.rds_host
    DB_USERNAME                = var.rds_name
    DB_PASSWORD                = var.rds_password
    SECURITY_USER_NAME         = "broker"
    SECURITY_USER_PASSWORD     = random_password.csb_app_password.result
    TERRAFORM_UPGRADES_ENABLED = true
    BROKERPAK_UPDATES_ENABLED  = true

    # Access keys for managing resources provisioned by brokerpaks
    AWS_ACCESS_KEY_ID_GOVCLOUD       = var.aws_access_key_id_govcloud
    AWS_SECRET_ACCESS_KEY_GOVCLOUD   = var.aws_secret_access_key_govcloud
    AWS_REGION_GOVCLOUD              = var.aws_region_govcloud
    AWS_ACCESS_KEY_ID_COMMERCIAL     = var.aws_access_key_id_commercial
    AWS_SECRET_ACCESS_KEY_COMMERCIAL = var.aws_secret_access_key_commercial
    AWS_REGION_COMMERCIAL            = var.aws_region_commercial

    # Other values that are used by convention by all brokerpaks
    CLOUD_GOV_ENVIRONMENT = var.iaas_stack_name

    # Brokerpak-specific variables
    CG_SMTP_AWS_ZONE = var.cg_smtp_aws_ses_zone
  }

  routes {
    route = cloudfoundry_route.csb.id
  }
}

data "cloudfoundry_domain" "platform_components" {
  name = var.broker_route_domain
}

resource "cloudfoundry_route" "csb" {
  domain   = data.cloudfoundry_domain.platform_components.id
  hostname = "services"
  space    = data.cloudfoundry_space.services.id
}

resource "cloudfoundry_service_broker" "csb" {
  name     = "csb"
  password = random_password.csb_app_password.result
  url      = "https://${cloudfoundry_route.csb.hostname}.${data.cloudfoundry_domain.platform_components.domain}"
  username = "broker"

  depends_on = [cloudfoundry_app.csb]
}
