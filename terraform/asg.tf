provider "cloudfoundry" {
  api_endpoint = "https://api.dev.us-gov-west-1.aws-us-gov.cloud.gov"
  username = ""
  password = ""
  verbose = true
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

  # RDS
  rules {
    protocol = "all"
    destination = "x.x.20.0-x.x.21.255"
  }

  # services
  rules {
    protocol = "all"
    destination = "x.x.30.0-x.x.31.255"
  }

  # public; I think we don't need this
  rules {
    protocol = "all"
    destination = "x.x.100.0-x.x.101.255"
  }

}

resource "cloudfoundry_sec_group" "brokers" {
  name = "brokers"
  rules {
    protocol = "tcp"
    destination = "169.254.169.254"
    ports = "80"
    log = false
    description = "AWS Metadata Service"
  }
}

resource "cloudfoundry_sec_group" "metrics-network" {
  name = "metrics-network"
  rules {
    protocol = "tcp"
    ports = "5555"
    destination = "x.x.x.x/32"
  }
}

resource "cloudfoundry_organization" "cloud-gov" {
  name = "cloud-gov"
  is_system_domain = true
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
