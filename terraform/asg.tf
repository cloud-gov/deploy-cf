variable "remote_state_bucket" {
}

variable "tooling_stack_name" {
}

variable "iaas_stack_name" {
}

variable "domain_name" {
}

terraform {
  backend "s3" {
  }
}

provider "cloudfoundry" {
}

data "terraform_remote_state" "iaas" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = "${var.iaas_stack_name}/terraform.tfstate"
  }
}

data "terraform_remote_state" "tooling" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = "${var.tooling_stack_name}/terraform.tfstate"
  }
}

resource "cloudfoundry_asg" "public_networks" {
  name = "public_networks"

  rule {
    protocol    = "all"
    destination = "0.0.0.0-9.255.255.255"
  }

  rule {
    protocol    = "all"
    destination = "11.0.0.0-169.253.255.255"
  }

  rule {
    protocol    = "all"
    destination = "169.255.0.0-172.15.255.255"
  }

  rule {
    protocol    = "all"
    destination = "172.32.0.0-192.167.255.255"
  }

  rule {
    protocol    = "all"
    destination = "192.169.0.0-255.255.255.255"
  }
}

# New public_networks asg to apply to spaces individually, not globally.

resource "cloudfoundry_asg" "public_networks_egress" {
  name = "public_networks_egress"

  rule {
    protocol    = "all"
    destination = "0.0.0.0-9.255.255.255"
  }

  rule {
    protocol    = "all"
    destination = "11.0.0.0-169.253.255.255"
  }

  rule {
    protocol    = "all"
    destination = "169.255.0.0-172.15.255.255"
  }

  rule {
    protocol    = "all"
    destination = "172.32.0.0-192.167.255.255"
  }

  rule {
    protocol    = "all"
    destination = "192.169.0.0-255.255.255.255"
  }
}

resource "cloudfoundry_asg" "dns" {
  name = "dns"

  rule {
    protocol    = "tcp"
    ports       = "53"
    destination = "0.0.0.0/0"
  }

  rule {
    protocol    = "udp"
    ports       = "53"
    destination = "0.0.0.0/0"
  }
}

# New dns asg to apply to spaces individually, not globally.

resource "cloudfoundry_asg" "dns_egress" {
  name = "dns_egress"

  rule {
    protocol    = "tcp"
    ports       = "53"
    destination = "0.0.0.0/0"
  }

  rule {
    protocol    = "udp"
    ports       = "53"
    destination = "0.0.0.0/0"
  }
}

resource "cloudfoundry_asg" "trusted_local_networks" {
  name = "trusted_local_networks"

  # RDS access for postgres, mysql, mssql, oracle
  rule {
    protocol    = "tcp"
    description = "Allow access to RDS"
    destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az1
    ports       = "5432,3306,1433,1521"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to RDS"
    destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az2
    ports       = "5432,3306,1433,1521"
  }

  # Elasticache access
  rule {
    protocol    = "tcp"
    description = "Allow access to Elasticache"
    destination = data.terraform_remote_state.iaas.outputs.elasticache_subnet_cidr_az1
    ports       = "6379"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to Elasticache"
    destination = data.terraform_remote_state.iaas.outputs.elasticache_subnet_cidr_az2
    ports       = "6379"
  }

  # Elastisearch access
  rule {
    protocol    = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az1
    ports       = "443"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az2
    ports       = "443"
  }

}

# New trusted networks asg to apply to spaces individually, not globally.

resource "cloudfoundry_asg" "trusted_local_networks_egress" {
  name = "trusted_local_networks_egress"

  # RDS access for postgres, mysql, mssql, oracle
  rule {
    protocol    = "tcp"
    description = "Allow access to RDS"
    destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az1
    ports       = "5432,3306,1433,1521"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to RDS"
    destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az2
    ports       = "5432,3306,1433,1521"
  }

  # Elasticache access
  rule {
    protocol    = "tcp"
    description = "Allow access to Elasticache"
    destination = data.terraform_remote_state.iaas.outputs.elasticache_subnet_cidr_az1
    ports       = "6379"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to Elasticache"
    destination = data.terraform_remote_state.iaas.outputs.elasticache_subnet_cidr_az2
    ports       = "6379"
  }

  # Elastisearch access
  rule {
    protocol    = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az1
    ports       = "443"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az2
    ports       = "443"
  }

}

resource "cloudfoundry_asg" "brokers" {
  name = "brokers"
  rule {
    protocol    = "tcp"
    destination = "169.254.169.254"
    ports       = "80"
    description = "AWS Metadata Service"
  }

}

resource "cloudfoundry_asg" "smtp" {
  name = "smtp"
  rule {
    destination = data.terraform_remote_state.tooling.outputs.production_smtp_private_ip
    description = "SMTP relay"
    protocol    = "tcp"
    ports       = "25"
  }
}

# Default global running ASG
resource "cloudfoundry_default_asg" "running" {
    name = "running"
    asgs = [ cloudfoundry_asg.dns.id ]
}

# Default global staging ASG
resource "cloudfoundry_default_asg" "staging" {
    name = "staging"
    asgs = [
      cloudfoundry_asg.dns.id,
      cloudfoundry_asg.public_networks.id,
      cloudfoundry_asg.trusted_local_networks.id,
    ]
}

resource "cloudfoundry_org_quota" "default-tts" {
  name                     = "default-tts"
  allow_paid_service_plans = true
  total_memory             = 81920
  total_routes             = 1000
  total_services           = 200
  total_route_ports        = -1
}

resource "cloudfoundry_org" "cloud-gov" {
  name  = "cloud-gov"
  quota = cloudfoundry_org_quota.default-tts.id
}

resource "cloudfoundry_isolation_segment" "platform" {
  name = "platform"
}

resource "cloudfoundry_isolation_segment_entitlement" "platform" {
  segment = cloudfoundry_isolation_segment.platform.id
  orgs = [
    cloudfoundry_org.cloud-gov.id
  ]
}

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

# Federalist/Pages

data "cloudfoundry_org" "gsa-18f-federalist" {
  name  = "gsa-18f-federalist"
}

resource "cloudfoundry_space" "email" {
  name = "email"
  org  = data.cloudfoundry_org.gsa-18f-federalist.id
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

data "cloudfoundry_router_group" "tcp_router_group" {
  name = "default-tcp" 
  depends_on = [
    # this dependency is kind of soft - really, we care about whether tcp routing is enabled
    # and we're using this as a hint. We should remove this dependency reference once tcp
    # routes are promoted to production
    cloudfoundry_isolation_segment.tcp
  ]
}

resource "cloudfoundry_isolation_segment" "tcp" {
  count = length(data.terraform_remote_state.iaas.outputs.tcp_lb_dns_names) > 0 ? 1 : 0
  name = "tcp"
}

resource "cloudfoundry_isolation_segment_entitlement" "tcp" {
  segment = cloudfoundry_isolation_segment.tcp[0].id
  orgs = [
    cloudfoundry_org.cloud-gov.id
  ]
}

resource "cloudfoundry_domain" "tcp" {
  for_each = toset(data.terraform_remote_state.iaas.outputs.tcp_lb_dns_names)
  sub_domain = "tcp-${index(data.terraform_remote_state.iaas.outputs.tcp_lb_dns_names, each.key)}"
  domain = var.domain_name
  internal = false
  router_group = data.cloudfoundry_router_group.tcp_router_group.id
}