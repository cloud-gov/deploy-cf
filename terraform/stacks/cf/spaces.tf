resource "cloudfoundry_space" "services" {
  name              = "services"
  org               = cloudfoundry_org.cloud-gov.id
  isolation_segment = cloudfoundry_isolation_segment.platform.id
}

resource "cloudfoundry_space" "dashboard" {
  name = "dashboard"
  org  = cloudfoundry_org.cloud-gov.id
}

resource "cloudfoundry_space" "cg-ui" {
  name = "cg-ui"
  org  = cloudfoundry_org.cloud-gov.id
}

resource "cloudfoundry_space" "uaa-extras" {
  name = "uaa-extras"
  org  = cloudfoundry_org.cloud-gov.id
}

resource "cloudfoundry_space" "cspr-collector" {
  name = "cspr-collector"
  org  = cloudfoundry_org.cloud-gov.id
}

resource "cloudfoundry_space" "opensearch-dashboards-proxy" {
  name = "opensearch-dashboards-proxy"
  org  = cloudfoundry_org.cloud-gov.id
}

resource "cloudfoundry_space" "external_domain_broker_tests" {
  name = "external-domain-broker-tests"
  org  = cloudfoundry_org.acceptance_tests.id
}

resource "cloudfoundry_space" "aws_broker_tests" {
  name = "aws-broker-tests"
  org  = cloudfoundry_org.acceptance_tests.id
}

resource "cloudfoundry_space" "s3_broker_tests" {
  name = "s3-broker-tests"
  org  = cloudfoundry_org.acceptance_tests.id
}

resource "cloudfoundry_space" "ses_broker_tests" {
  name = "ses-broker-tests"
  org  = cloudfoundry_org.acceptance_tests.id
}

# Federalist/ Pages

resource "cloudfoundry_space" "email" {
  name = "email"
  org  = data.cloudfoundry_org.gsa-18f-federalist.id
}
