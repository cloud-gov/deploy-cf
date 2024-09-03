terraform {
  backend "s3" {
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

  rule {
    description = "Rule for private endpoint to s3 in region"
    protocol    = "tcp"
    destination = data.terraform_remote_state.iaas.outputs.vpc_endpoint_customer_s3_if1_ip
    ports="443"
  }

  rule{
    description = "Rule for private endpoint to s3 in region"
    protocol    = "tcp"
    destination = data.terraform_remote_state.iaas.outputs.vpc_endpoint_customer_s3_if2_ip
    ports="443"
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
  rule {
    protocol    = "tcp"
    description = "Allow access to RDS"
    destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az3
    ports       = "5432,3306,1433,1521"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to RDS"
    destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az4
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
  rule {
    protocol    = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az3
    ports       = "443"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az4
    ports       = "443"
  }
  # S3 Gateway access
  dynamic "rule" {

    for_each = data.terraform_remote_state.iaas.outputs.s3_gateway_endpoint_cidrs
    iterator = rule

    protocol    = "tcp"
    description = "Allow access to AWS S3 Gateway"
    destination = rule.value
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
  rule {
    protocol    = "tcp"
    description = "Allow access to RDS"
    destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az3
    ports       = "5432,3306,1433,1521"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to RDS"
    destination = data.terraform_remote_state.iaas.outputs.rds_subnet_cidr_az4
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
  rule {
    protocol    = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az3
    ports       = "443"
  }
  rule {
    protocol    = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = data.terraform_remote_state.iaas.outputs.elasticsearch_subnet_cidr_az4
    ports       = "443"
  }
  # S3 Gateway access
  dynamic "rule" {

    for_each = data.terraform_remote_state.iaas.outputs.s3_gateway_endpoint_cidrs
    iterator = rule

    protocol    = "tcp"
    description = "Allow access to AWS S3 Gateway"
    destination = rule.value
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

resource "cloudfoundry_asg" "internal_services_egress" {
  name = "internal_services_egress"

  rule {
    protocol    = "tcp"
    description = "Allow access to internal services on port 443 - AZ 1"
    destination = data.terraform_remote_state.iaas.outputs.services_subnet_cidr_az1
    ports       = "443"
  }

  rule {
    protocol    = "tcp"
    description = "Allow access to internal services on port 443 - AZ 2"
    destination = data.terraform_remote_state.iaas.outputs.services_subnet_cidr_az2
    ports       = "443"
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
      cloudfoundry_asg.public_networks_egress.id,
      cloudfoundry_asg.trusted_local_networks_egress.id,
    ]
}

