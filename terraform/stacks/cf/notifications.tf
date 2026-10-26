locals {
  platform_notifications_service_name = "platform-notifications-domain"
}

data "cloudfoundry_service_plan" "ses_domain_plan" {
  name                  = "domain"
  service_offering_name = "aws-ses"
}

resource "cloudfoundry_service_instance" "platform_notifications_ses_domain" {
  name         = local.platform_notifications_service_name
  type         = "managed"
  space        = cloudfoundry_space.notifications.id
  service_plan = data.cloudfoundry_service_plan.ses_domain_plan.id
  parameters   = <<EOT
{
  "domain": "notifications.${var.domain_name}",
  "admin_email": "${var.platform_admin_email}"
}
EOT
}

resource "cloudfoundry_service_credential_binding" "platform_notifications_ses_domain_key" {
  type             = "key"
  name             = "${local.platform_notifications_service_name}-key"
  service_instance = cloudfoundry_service_instance.platform_notifications_domain.id
}
