data "cloudfoundry_router_group" "tcp_router_group" {
  name = "default-tcp"
}

resource "cloudfoundry_isolation_segment" "tcp" {
  name = "tcp"
}

resource "cloudfoundry_isolation_segment_entitlement" "tcp" {
  segment = cloudfoundry_isolation_segment.tcp.id
  orgs = [
    var.cloud_gov_org_id
  ]
}

resource "cloudfoundry_domain" "tcp" {
  for_each     = toset(var.tcp_lb_dns_names)
  sub_domain   = "tcp-${index(var.tcp_lb_dns_names, each.key)}"
  domain       = var.domain_name
  internal     = false
  router_group = data.cloudfoundry_router_group.tcp_router_group.id
}
