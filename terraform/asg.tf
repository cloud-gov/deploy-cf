variable "remote_state_bucket" {}
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

resource "cloudfoundry_sec_group" "public_networks" {
  name = "public_networks"
  on_staging = true
  on_running = true

  rules {
    protocol = "all"
    destination = "0.0.0.0-9.255.255.255"
  }

  rules {
    protocol = "all"
    destination = "11.0.0.0-169.253.255.255"
  }

  rules {
    protocol = "all"
    destination = "169.255.0.0-172.15.255.255"
  }

  rules {
    protocol = "all"
    destination = "172.32.0.0-192.167.255.255"
  }

  rules {
    protocol = "all"
    destination = "192.169.0.0-255.255.255.255"
  }
}

resource "cloudfoundry_sec_group" "dns" {
  name = "dns"
  on_staging = true
  on_running = true

  rules {
    protocol = "tcp"
    ports = "53"
    destination = "0.0.0.0/0"
  }

  rules {
    protocol = "udp"
    ports = "53"
    destination = "0.0.0.0/0"
  }
}

resource "cloudfoundry_sec_group" "trusted_local_networks" {
  name = "trusted_local_networks"
  on_staging = true
  on_running = true

  # RDS access for postgres, mysql, mssql, oracle
  rules {
    protocol = "tcp"
    description = "Allow access to RDS"
    destination = "${data.terraform_remote_state.iaas.rds_subnet_cidr_az1}"
    ports = "5432,3306,1433,1521"
  }
  rules {
    protocol = "tcp"
    description = "Allow access to RDS"
    destination = "${data.terraform_remote_state.iaas.rds_subnet_cidr_az2}"
    ports = "5432,3306,1433,1521"
  }

  # Kubernetes
  rules {
    protocol = "tcp"
    description = "Allow access to kubernetes NodePorts for managed services"
    destination = "${data.terraform_remote_state.iaas.services_subnet_cidr_az1}"
    ports = "30000-32767"
  }
  rules {
    protocol = "tcp"
    description = "Allow access to kubernetes NodePorts for managed services"
    destination = "${data.terraform_remote_state.iaas.services_subnet_cidr_az2}"
    ports = "30000-32767"
  }
}

resource "cloudfoundry_sec_group" "brokers" {
  name = "brokers"
  rules {
    protocol = "tcp"
    destination = "169.254.169.254"
    ports = "80"
    description = "AWS Metadata Service"
  }

  rules {
    protocol = "tcp"
    description = "Allow access to kubernetes API"
    destination = "${data.terraform_remote_state.iaas.services_subnet_cidr_az1}"
    ports = "6443"
  }
  rules {
    protocol = "tcp"
    description = "Allow access to kubernetes API"
    destination = "${data.terraform_remote_state.iaas.services_subnet_cidr_az2}"
    ports = "6443"
  }
}

resource "cloudfoundry_sec_group" "metrics-network" {
  name = "metrics-network"
  rules {
    protocol = "tcp"
    description = "Allow access to riemann"
    destination = "${data.terraform_remote_state.iaas.monitoring_ip_address}"
    ports = "5555"
  }
}

resource "cloudfoundry_quota" "default-tts" {
  name = "default-tts"
  total_memory = "20G"
  routes = 1000
  service_instances = 200
}

resource "cloudfoundry_organization" "cloud-gov" {
  name = "cloud-gov"
  is_system_domain = true
  quota_id = "${cloudfoundry_quota.default-tts.id}"
}

resource "cloudfoundry_space" "services" {
  name = "services"
  org_id = "${cloudfoundry_organization.cloud-gov.id}"
  sec_groups = ["${cloudfoundry_sec_group.brokers.id}"]
}

resource "cloudfoundry_space" "firehose" {
  name = "firehose"
  org_id = "${cloudfoundry_organization.cloud-gov.id}"
  sec_groups = ["${cloudfoundry_sec_group.metrics-network.id}"]
}
