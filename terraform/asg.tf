variable "remote_state_bucket" {}
variable "tooling_stack_name" {}
variable "iaas_stack_name" {}

terraform {
  backend "s3" {}
}

provider "cloudfoundry" {}

data "terraform_remote_state" "iaas" {
  backend = "s3"
  config {
    bucket = "${var.remote_state_bucket}"
    key = "${var.iaas_stack_name}/terraform.tfstate"
  }
}

data "terraform_remote_state" "tooling" {
  backend = "s3"
  config {
    bucket = "${var.remote_state_bucket}"
    key = "${var.tooling_stack_name}/terraform.tfstate"
  }
}

resource "cloudfoundry_asg" "public_networks" {
  name = "public_networks"

  rule {
    protocol = "all"
    destination = "0.0.0.0-9.255.255.255"
  }

  rule {
    protocol = "all"
    destination = "11.0.0.0-169.253.255.255"
  }

  rule {
    protocol = "all"
    destination = "169.255.0.0-172.15.255.255"
  }

  rule {
    protocol = "all"
    destination = "172.32.0.0-192.167.255.255"
  }

  rule {
    protocol = "all"
    destination = "192.169.0.0-255.255.255.255"
  }
}

resource "cloudfoundry_asg" "dns" {
  name = "dns"

  rule {
    protocol = "tcp"
    ports = "53"
    destination = "0.0.0.0/0"
  }

  rule {
    protocol = "udp"
    ports = "53"
    destination = "0.0.0.0/0"
  }
}

resource "cloudfoundry_asg" "trusted_local_networks" {
  name = "trusted_local_networks"

  # RDS access for postgres, mysql, mssql, oracle
  rule {
    protocol = "tcp"
    description = "Allow access to RDS"
    destination = "${data.terraform_remote_state.iaas.rds_subnet_cidr_az1}"
    ports = "5432,3306,1433,1521"
  }
  rule {
    protocol = "tcp"
    description = "Allow access to RDS"
    destination = "${data.terraform_remote_state.iaas.rds_subnet_cidr_az2}"
    ports = "5432,3306,1433,1521"
  }

  # Elasticache access
  rule {
    protocol = "tcp"
    description = "Allow access to Elasticache"
    destination = "${data.terraform_remote_state.iaas.elasticache_subnet_cidr_az1}"
    ports = "6379"
  }
  rule {
    protocol = "tcp"
    description = "Allow access to Elasticache"
    destination = "${data.terraform_remote_state.iaas.elasticache_subnet_cidr_az2}"
    ports = "6379"
  }

  # Elastisearch access
  rule {
    protocol = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = "${data.terraform_remote_state.iaas.elasticsearch_subnet_cidr_az1}"
    ports = "443"
  }
  rule {
    protocol = "tcp"
    description = "Allow access to AWS Elasticsearch"
    destination = "${data.terraform_remote_state.iaas.elasticsearch_subnet_cidr_az2}"
    ports = "443"
  }

  # Kubernetes
  rule {
    protocol = "tcp"
    description = "Allow access to kubernetes NodePorts for managed services"
    destination = "${data.terraform_remote_state.iaas.services_subnet_cidr_az1}"
    ports = "30000-32767"
  }
  rule {
    protocol = "tcp"
    description = "Allow access to kubernetes NodePorts for managed services"
    destination = "${data.terraform_remote_state.iaas.services_subnet_cidr_az2}"
    ports = "30000-32767"
  }
}

resource "cloudfoundry_asg" "brokers" {
  name = "brokers"
  rule {
    protocol = "tcp"
    destination = "169.254.169.254"
    ports = "80"
    description = "AWS Metadata Service"
  }

  rule {
    protocol = "tcp"
    description = "Allow access to kubernetes API"
    destination = "${data.terraform_remote_state.iaas.services_subnet_cidr_az1}"
    ports = "6443"
  }
  rule {
    protocol = "tcp"
    description = "Allow access to kubernetes API"
    destination = "${data.terraform_remote_state.iaas.services_subnet_cidr_az2}"
    ports = "6443"
  }
}

resource "cloudfoundry_asg" "smtp" {
  name = "smtp"
  rule {
    destination = "${data.terraform_remote_state.tooling.production_smtp_private_ip}"
    description = "SMTP relay"
    protocol = "tcp"
    ports = "25"
  }
}

resource "cloudfoundry_org_quota" "default-tts" {
  name = "default-tts"
  allow_paid_service_plans = true
  total_memory = 40960
  total_routes = 1000
  total_services = 200
}

resource "cloudfoundry_org" "cloud-gov" {
  name = "cloud-gov"
  quota = "${cloudfoundry_org_quota.default-tts.id}"
}

resource "cloudfoundry_space" "services" {
  name = "services"
  org = "${cloudfoundry_org.cloud-gov.id}"
  asgs = [
    "${cloudfoundry_asg.public_networks.id}",
    "${cloudfoundry_asg.trusted_local_networks.id}",
    "${cloudfoundry_asg.dns.id}",
    "${cloudfoundry_asg.brokers.id}",
    "${cloudfoundry_asg.smtp.id}"
  ]
  staging_asgs = [ 
    "${cloudfoundry_asg.trusted_local_networks.id}",
    "${cloudfoundry_asg.public_networks.id}",
    "${cloudfoundry_asg.dns.id}",
    "${cloudfoundry_asg.brokers.id}",
    "${cloudfoundry_asg.brokers.id}"
  ]
}

resource "cloudfoundry_space" "dashboard" {
  name = "dashboard"
  org = "${cloudfoundry_org.cloud-gov.id}"
  asgs = [ 
    "${cloudfoundry_asg.trusted_local_networks.id}",
    "${cloudfoundry_asg.public_networks.id}",
    "${cloudfoundry_asg.dns.id}",
    "${cloudfoundry_asg.smtp.id}"
  ]
  staging_asgs = [
    "${cloudfoundry_asg.trusted_local_networks.id}",
    "${cloudfoundry_asg.public_networks.id}",
    "${cloudfoundry_asg.dns.id}"
  ]
}

resource "cloudfoundry_space" "uaa-extras" {
  name = "uaa-extras"
  org = "${cloudfoundry_org.cloud-gov.id}"
  asgs = [
    "${cloudfoundry_asg.trusted_local_networks.id}",
    "${cloudfoundry_asg.public_networks.id}",
    "${cloudfoundry_asg.dns.id}",
    "${cloudfoundry_asg.smtp.id}"
  ]
  staging_asgs = [ 
    "${cloudfoundry_asg.trusted_local_networks.id}",
    "${cloudfoundry_asg.public_networks.id}",
    "${cloudfoundry_asg.dns.id}"
  ]
}


