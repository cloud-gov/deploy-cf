resource "cloudfoundry_space" "services" {
  name = "services"
  org  = cloudfoundry_org.cloud-gov.id
  asgs = [
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.dns.id,
    cloudfoundry_asg.brokers.id,
    cloudfoundry_asg.smtp.id,
  ]
  staging_asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
  ]
  isolation_segment = cloudfoundry_isolation_segment.platform.id
}

resource "cloudfoundry_space" "dashboard" {
  name = "dashboard"
  org  = cloudfoundry_org.cloud-gov.id
  asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
    cloudfoundry_asg.smtp.id,
  ]
  staging_asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
  ]
}

resource "cloudfoundry_space" "cg-ui" {
  name = "cg-ui"
  org  = cloudfoundry_org.cloud-gov.id
  asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
    cloudfoundry_asg.smtp.id,
  ]
  staging_asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
  ]
}

resource "cloudfoundry_space" "uaa-extras" {
  name = "uaa-extras"
  org  = cloudfoundry_org.cloud-gov.id
  asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
    cloudfoundry_asg.smtp.id,
  ]
  staging_asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
  ]
}

resource "cloudfoundry_space" "cspr-collector" {
  name = "cspr-collector"
  org  = cloudfoundry_org.cloud-gov.id
  asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
    cloudfoundry_asg.smtp.id,
  ]
  staging_asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
  ]
}

resource "cloudfoundry_space" "opensearch-dashboards-proxy" {
  name = "opensearch-dashboards-proxy"
  org  = cloudfoundry_org.cloud-gov.id
  asgs = [
    cloudfoundry_asg.public_networks_egress.id,
    cloudfoundry_asg.dns.id,
    cloudfoundry_asg.trusted_local_networks.id
  ]
  staging_asgs = [
    cloudfoundry_asg.dns.id,
    cloudfoundry_asg.public_networks_egress.id
  ]
}

resource "cloudfoundry_space" "external_domain_broker_tests" {
  name = "external-domain-broker-tests"
  org  = cloudfoundry_org.acceptance_tests.id
  asgs = [
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
  ]
  staging_asgs = [
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
  ]
}

# Federalist/ Pages

resource "cloudfoundry_space" "email" {
  name = "email"
  org  = data.cloudfoundry_org.gsa-18f-federalist.id
  quota = cloudfoundry_space_quota.tiny.id
  asgs = [
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
    cloudfoundry_asg.smtp.id,
  ]
  staging_asgs = [
    cloudfoundry_asg.trusted_local_networks.id,
    cloudfoundry_asg.public_networks.id,
    cloudfoundry_asg.dns.id,
  ]
}
