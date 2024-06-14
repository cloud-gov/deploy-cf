output "cf_rds_engine" {
  value = module.cfdb.rds_engine
}

output "cf_rds_host" {
  value = module.cfdb.rds_host
}

output "cf_rds_password" {
  value     = module.cfdb.rds_password
  sensitive = true
}

output "cf_rds_username" {
  value = module.cfdb.rds_username
}

output "tcp_lb_listener_ports" {
  value = aws_lb_listener.cf_apps_tcp.*.port
}

output "vpc_region" {
  value = var.aws_default_region
}

output "cf_router_target_groups" {
  value = flatten(concat(
    [aws_lb_target_group.cf_target_https.name],
    [aws_lb_target_group.cf_apps_target_https.name],
  ))
}

output "cf_router_main_target_group" {
  value = concat(
    [aws_lb_target_group.cf_uaa_target.name],
  )
}

output "diego_elb_name" {
  value = aws_elb.diego_elb_main.name
}

output "tcp_lb_target_groups" {
  value = aws_lb_target_group.cf_apps_target_tcp.*.name
}


output "tcp_lb_security_groups" {
  value = concat(aws_security_group.nlb_traffic.*.id)
}

output "cf_blobstore_profile" {
  value = module.cf_blobstore_role.profile_name
}

output "platform_profile" {
  value = module.platform_role.profile_name
}
