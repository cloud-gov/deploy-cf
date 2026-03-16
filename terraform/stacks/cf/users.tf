data "cloudfoundry_service_plan" "space_deployer_plan" {
  name                  = "space-deployer"
  service_offering_name = "cloud-gov-service-account"
}

# UAA credentials broker

resource "cloudfoundry_service_instance" "uaa_credentials_broker_test_user" {
  name         = "uaa-credentials-broker-test"
  type         = "managed"
  space        = cloudfoundry_space.uaa_credentials_broker_tests.id
  service_plan = data.cloudfoundry_service_plan.space_deployer_plan.id
}

resource "cloudfoundry_service_credential_binding" "uaa_credentials_broker_test_key" {
  type             = "key"
  name             = "uaa-credentials-broker-test-key"
  service_instance = cloudfoundry_service_instance.uaa_credentials_broker_test_user.id
}

# CSB - SES broker

resource "cloudfoundry_service_instance" "ses_broker_test_user" {
  name         = "ses-broker-test"
  type         = "managed"
  space        = cloudfoundry_space.ses_broker_tests.id
  service_plan = data.cloudfoundry_service_plan.space_deployer_plan.id
}

resource "cloudfoundry_service_credential_binding" "ses_broker_test_key" {
  type             = "key"
  name             = "ses-broker-test-key"
  service_instance = cloudfoundry_service_instance.ses_broker_test_user.id
}
