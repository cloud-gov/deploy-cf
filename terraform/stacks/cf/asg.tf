resource "cloudfoundry_security_group" "public_networks" {
  name                     = "public_networks"
  globally_enabled_running = false
  globally_enabled_staging = false
  rules = [
    {
      protocol    = "all"
      destination = "0.0.0.0-9.255.255.255"
      log         = false
    },
    {
      protocol    = "all"
      destination = "11.0.0.0-169.253.255.255"
      log         = false
    },
    {
      protocol    = "all"
      destination = "169.255.0.0-172.15.255.255"
      log         = false
    },
    {
      protocol    = "all"
      destination = "172.32.0.0-192.167.255.255"
      log         = false
    },
    {
      protocol    = "all"
      destination = "192.169.0.0-255.255.255.255"
      log         = false
    },
  ]
  staging_spaces = [cloudfoundry_space.services.id, cloudfoundry_space.dashboard.id, cloudfoundry_space.cg-ui.id, cloudfoundry_space.uaa-extras.id, cloudfoundry_space.cspr-collector.id, cloudfoundry_space.external_domain_broker_tests.id, cloudfoundry_space.email.id]
  running_spaces = [cloudfoundry_space.services.id, cloudfoundry_space.dashboard.id, cloudfoundry_space.cg-ui.id, cloudfoundry_space.uaa-extras.id, cloudfoundry_space.cspr-collector.id, cloudfoundry_space.external_domain_broker_tests.id, cloudfoundry_space.email.id]
}


# New public_networks asg to apply to spaces individually, not globally.
resource "cloudfoundry_security_group" "public_networks_egress" {
  name = "public_networks_egress"

  globally_enabled_running = false
  globally_enabled_staging = true

  rules = [

    {
      protocol    = "all"
      destination = "0.0.0.0-9.255.255.255"
      log         = false
    },
    {
      protocol    = "all"
      destination = "11.0.0.0-169.253.255.255"
      log         = false
    },
    {
      protocol    = "all"
      destination = "169.255.0.0-172.15.255.255"
      log         = false
    },
    {
      protocol    = "all"
      destination = "172.32.0.0-192.167.255.255"
      log         = false
    },
    {
      protocol    = "all"
      destination = "192.169.0.0-255.255.255.255"
      log         = false
    },
    {
      description = "Rule for private endpoint to s3 in region"
      protocol    = "tcp"
      destination = data.terraform_remote_state.iaas.outputs.vpc_endpoint_customer_s3_if1_ip
      ports       = "443"
      log         = false
    },
    {
      description = "Rule for private endpoint to s3 in region"
      protocol    = "tcp"
      destination = data.terraform_remote_state.iaas.outputs.vpc_endpoint_customer_s3_if2_ip
      ports       = "443"
      log         = false
    },
  ]
}

resource "cloudfoundry_security_group" "dns" {
  name                     = "dns"
  globally_enabled_running = true
  globally_enabled_staging = true

  rules = [
    {
      protocol    = "tcp"
      ports       = "53"
      destination = "0.0.0.0/0"
      log         = false
    },
    {
      protocol    = "udp"
      ports       = "53"
      destination = "0.0.0.0/0"
      log         = false
    },
  ]
  staging_spaces = [cloudfoundry_space.services.id, cloudfoundry_space.dashboard.id, cloudfoundry_space.cg-ui.id, cloudfoundry_space.uaa-extras.id, cloudfoundry_space.cspr-collector.id, cloudfoundry_space.opensearch-dashboards-proxy.id, cloudfoundry_space.external_domain_broker_tests.id, cloudfoundry_space.email.id]
  running_spaces = [cloudfoundry_space.services.id, cloudfoundry_space.dashboard.id, cloudfoundry_space.cg-ui.id, cloudfoundry_space.uaa-extras.id, cloudfoundry_space.cspr-collector.id, cloudfoundry_space.opensearch-dashboards-proxy.id, cloudfoundry_space.external_domain_broker_tests.id, cloudfoundry_space.email.id]
}

# New dns asg to apply to spaces individually, not globally.
resource "cloudfoundry_security_group" "dns_egress" {
  name = "dns_egress"

  globally_enabled_running = false
  globally_enabled_staging = false

  rules = [
    {
      protocol    = "tcp"
      ports       = "53"
      destination = "0.0.0.0/0"
      log         = false
    },
    {
      protocol    = "udp"
      ports       = "53"
      destination = "0.0.0.0/0"
      log         = false
    },
  ]
}

locals {
  trusted_local_networks_rules_1 = [
    {
      protocol    = "tcp"
      description = "Allow access to RDS"
      destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az1
      ports       = "5432,3306,1433,1521"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to RDS"
      destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az2
      ports       = "5432,3306,1433,1521"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to RDS"
      destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az3
      ports       = "5432,3306,1433,1521"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to RDS"
      destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az4
      ports       = "5432,3306,1433,1521"
      log         = false
    },
    # Elasticache access
    {
      protocol    = "tcp"
      description = "Allow access to Elasticache"
      destination = data.terraform_remote_state.iaas.outputs.elasticache_subnet_cidr_az1
      ports       = "6379"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to Elasticache"
      destination = data.terraform_remote_state.iaas.outputs.elasticache_subnet_cidr_az2
      ports       = "6379"
      log         = false
    },
    # Elastisearch access
    {
      protocol    = "tcp"
      description = "Allow access to AWS Elasticsearch"
      destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az1
      ports       = "443"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to AWS Elasticsearch"
      destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az2
      ports       = "443"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to AWS Elasticsearch"
      destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az3
      ports       = "443"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to AWS Elasticsearch"
      destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az4
      ports       = "443"
      log         = false
    },
  ]

  trusted_local_networks_rules_2 = [
    for cidr in data.terraform_remote_state.iaas.outputs.s3_gateway_endpoint_cidrs :
    {
      protocol    = "tcp"
      description = "Allow access to AWS S3 Gateway"
      destination = cidr
      ports       = "443"
      log         = false
    }
  ]

  trusted_local_networks_rules = concat(local.trusted_local_networks_rules_1, local.trusted_local_networks_rules_2)
}

resource "cloudfoundry_security_group" "trusted_local_networks" {
  name = "trusted_local_networks"

  # RDS access for postgres, mysql, mssql, oracle
  rules = local.trusted_local_networks_rules

  staging_spaces = [cloudfoundry_space.services.id, cloudfoundry_space.dashboard.id, cloudfoundry_space.cg-ui.id, cloudfoundry_space.uaa-extras.id, cloudfoundry_space.cspr-collector.id, cloudfoundry_space.email.id]
  running_spaces = [cloudfoundry_space.services.id, cloudfoundry_space.dashboard.id, cloudfoundry_space.cg-ui.id, cloudfoundry_space.uaa-extras.id, cloudfoundry_space.cspr-collector.id, cloudfoundry_space.opensearch-dashboards-proxy.id, cloudfoundry_space.email.id]
}

locals {
  trusted_local_networks_egress_rules_1 = [
    {
      protocol    = "tcp"
      description = "Allow access to RDS"
      destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az1
      ports       = "5432,3306,1433,1521"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to RDS"
      destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az2
      ports       = "5432,3306,1433,1521"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to RDS"
      destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az3
      ports       = "5432,3306,1433,1521"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to RDS"
      destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az4
      ports       = "5432,3306,1433,1521"
      log         = false
    },
    # Elasticache access
    {
      protocol    = "tcp"
      description = "Allow access to Elasticache"
      destination = data.terraform_remote_state.iaas.outputs.elasticache_subnet_cidr_az1
      ports       = "6379"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to Elasticache"
      destination = data.terraform_remote_state.iaas.outputs.elasticache_subnet_cidr_az2
      ports       = "6379"
      log         = false
    },
    # Elastisearch access
    {
      protocol    = "tcp"
      description = "Allow access to AWS Elasticsearch"
      destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az1
      ports       = "443"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to AWS Elasticsearch"
      destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az2
      ports       = "443"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to AWS Elasticsearch"
      destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az3
      ports       = "443"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to AWS Elasticsearch"
      destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az4
      ports       = "443"
      log         = false
    },
  ]

  trusted_local_networks_egress_rules_2 = [
    for cidr in data.terraform_remote_state.iaas.outputs.s3_gateway_endpoint_cidrs :
    {
      protocol    = "tcp"
      description = "Allow access to AWS S3 Gateway"
      destination = cidr
      ports       = "443"
      log         = false
    }
  ]

  trusted_local_networks_egress_rules = concat(local.trusted_local_networks_egress_rules_1, local.trusted_local_networks_egress_rules_2)
}

# New trusted networks asg to apply to spaces individually, not globally.
resource "cloudfoundry_security_group" "trusted_local_networks_egress" {
  name = "trusted_local_networks_egress"

  globally_enabled_running = false
  globally_enabled_staging = true

  # RDS access for postgres, mysql, mssql, oracle
  rules = local.trusted_local_networks_egress_rules
}

resource "cloudfoundry_security_group" "brokers" {
  name = "brokers"
  rules = [{
    protocol    = "tcp"
    destination = "169.254.169.254"
    ports       = "80"
    description = "AWS Metadata Service"
    log         = false
  }]
  running_spaces = [cloudfoundry_space.services.id]
}

resource "cloudfoundry_security_group" "smtp" {
  name = "smtp"
  rules = [{
    destination = data.terraform_remote_state.tooling.outputs.production_smtp_private_ip
    description = "SMTP relay"
    protocol    = "tcp"
    ports       = "25"
  }]
  running_spaces = [cloudfoundry_space.services.id, cloudfoundry_space.dashboard.id, cloudfoundry_space.cg-ui.id, cloudfoundry_space.uaa-extras.id, cloudfoundry_space.cspr-collector.id, cloudfoundry_space.email.id]
}

resource "cloudfoundry_security_group" "internal_services_egress" {
  name = "internal_services_egress"

  rules = [
    {
      protocol    = "tcp"
      description = "Allow access to internal services on port 443 - AZ 1"
      destination = data.terraform_remote_state.iaas.outputs.services_subnet_cidr_az1
      ports       = "443"
      log         = false
    },
    {
      protocol    = "tcp"
      description = "Allow access to internal services on port 443 - AZ 2"
      destination = data.terraform_remote_state.iaas.outputs.services_subnet_cidr_az2
      ports       = "443"
      log         = false
    },
  ]
}
