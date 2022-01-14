variable "remote_state_bucket" {
}

variable "tooling_stack_name" {
}

variable "iaas_stack_name" {
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

# New Relic

resource "cloudfoundry_asg" "new_relic_egress" {
  name = "new_relic_egress"

  rule {
    protocol    = "tcp"
    port        = "443"
    destination = "162.247.240.0/22"
  }
}

# SmartyStreets

resource "cloudfoundry_asg" "smarty_streets_egress" {
  name = "smarty_streets_egress"

  rule {
    protocol    = "all"
    destination = "35.221.61.4/32"
  }
  rule {
    protocol    = "all"
    destination = "35.193.116.62/32"
  }
  rule {
    protocol    = "all"
    destination = "52.183.65.131/32"
  }
}

# Google reCAPTCHA IPranges.

resource "cloudfoundry_asg" "recaptcha_egress" {
  name = "recaptcha_egress"

  rule {
    protocol    = "all"
    destination = "8.8.4.0/24"
  }
  rule {
    protocol    = "all"
    destination = "8.8.8.0/24"
  }
  rule {
    protocol    = "all"
    destination = "8.34.208.0/20"
  }
  rule {
    protocol    = "all"
    destination = "8.35.192.0/20"
  }
  rule {
    protocol    = "all"
    destination = "23.236.48.0/20"
  }
  rule {
    protocol    = "all"
    destination = "23.251.128.0/19"
  }
  rule {
    protocol    = "all"
    destination = "34.64.0.0/10"
  }
  rule {
    protocol    = "all"
    destination = "34.128.0.0/10"
  }
  rule {
    protocol    = "all"
    destination = "35.184.0.0/13"
  }
  rule {
    protocol    = "all"
    destination = "35.192.0.0/14"
  }
  rule {
    protocol    = "all"
    destination = "35.196.0.0/15"
  }
  rule {
    protocol    = "all"
    destination = "35.198.0.0/16"
  }
  rule {
    protocol    = "all"
    destination = "35.199.0.0/17"
  }
  rule {
    protocol    = "all"
    destination = "35.199.128.0/18"
  }
  rule {
    protocol    = "all"
    destination = "35.200.0.0/13"
  }
  rule {
    protocol    = "all"
    destination = "35.208.0.0/12"
  }
  rule {
    protocol    = "all"
    destination = "35.224.0.0/12"
  }
  rule {
    protocol    = "all"
    destination = "35.240.0.0/13"
  }
  rule {
    protocol    = "all"
    destination = "64.15.112.0/20"
  }
  rule {
    protocol    = "all"
    destination = "64.233.160.0/19"
  }
  rule {
    protocol    = "all"
    destination = "66.102.0.0/20"
  }
  rule {
    protocol    = "all"
    destination = "66.249.64.0/19"
  }
  rule {
    protocol    = "all"
    destination = "70.32.128.0/19"
  }
  rule {
    protocol    = "all"
    destination = "72.14.192.0/18"
  }
  rule {
    protocol    = "all"
    destination = "74.114.24.0/21"
  }
  rule {
    protocol    = "all"
    destination = "74.125.0.0/16"
  }
  rule {
    protocol    = "all"
    destination = "104.154.0.0/15"
  }
  rule {
    protocol    = "all"
    destination = "104.196.0.0/14"
  }
  rule {
    protocol    = "all"
    destination = "104.237.160.0/19"
  }
  rule {
    protocol    = "all"
    destination = "107.167.160.0/19"
  }
  rule {
    protocol    = "all"
    destination = "107.178.192.0/18"
  }
  rule {
    protocol    = "all"
    destination = "108.59.80.0/20"
  }
  rule {
    protocol    = "all"
    destination = "108.170.192.0/18"
  }
  rule {
    protocol    = "all"
    destination = "108.177.0.0/17"
  }
  rule {
    protocol    = "all"
    destination = "130.211.0.0/16"
  }
  rule {
    protocol    = "all"
    destination = "136.112.0.0/12"
  }
  rule {
    protocol    = "all"
    destination = "142.250.0.0/15"
  }
  rule {
    protocol    = "all"
    destination = "146.148.0.0/17"
  }
  rule {
    protocol    = "all"
    destination = "162.216.148.0/22"
  }
  rule {
    protocol    = "all"
    destination = "162.222.176.0/21"
  }
  rule {
    protocol    = "all"
    destination = "172.110.32.0/21"
  }
  rule {
    protocol    = "all"
    destination = "172.217.0.0/16"
  }
  rule {
    protocol    = "all"
    destination = "172.253.0.0/16"
  }
  rule {
    protocol    = "all"
    destination = "173.194.0.0/16"
  }
  rule {
    protocol    = "all"
    destination = "173.255.112.0/20"
  }
  rule {
    protocol    = "all"
    destination = "192.158.28.0/22"
  }
  rule {
    protocol    = "all"
    destination = "192.178.0.0/15"
  }
  rule {
    protocol    = "all"
    destination = "193.186.4.0/24"
  }
  rule {
    protocol    = "all"
    destination = "199.36.154.0/23"
  }
  rule {
    protocol    = "all"
    destination = "199.36.156.0/24"
  }
  rule {
    protocol    = "all"
    destination = "199.192.112.0/22"
  }
  rule {
    protocol    = "all"
    destination = "199.223.232.0/21"
  }
  rule {
    protocol    = "all"
    destination = "207.223.160.0/20"
  }
  rule {
    protocol    = "all"
    destination = "208.65.152.0/22"
  }
  rule {
    protocol    = "all"
    destination = "208.68.108.0/22"
  }
  rule {
    protocol    = "all"
    destination = "208.81.188.0/22"
  }
  rule {
    protocol    = "all"
    destination = "208.117.224.0/19"
  }
  rule {
    protocol    = "all"
    destination = "209.85.128.0/17"
  }
  rule {
    protocol    = "all"
    destination = "216.58.192.0/19"
  }
  rule {
    protocol    = "all"
    destination = "216.73.80.0/20"
  }
  rule {
    protocol    = "all"
    destination = "216.239.32.0/19"
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
