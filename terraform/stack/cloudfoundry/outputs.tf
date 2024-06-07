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
