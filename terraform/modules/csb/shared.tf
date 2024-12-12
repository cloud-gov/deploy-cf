data "cloudfoundry_org" "platform" {
  name = var.org_name
}

data "cloudfoundry_space" "brokers" {
  name = var.space_name
  org  = data.cloudfoundry_org.platform.id
}
