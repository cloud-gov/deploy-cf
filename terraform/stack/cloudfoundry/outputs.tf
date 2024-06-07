output "cf_rds_engine" {
  value = module.cf_database_96.rds_engine
}

output "cf_rds_host" {
  value = module.cf_database_96.rds_host
}

output "cf_rds_password" {
  value     = module.cf_database_96.rds_password
  sensitive = true
}

output "cf_rds_username" {
  value = module.cf_database_96.rds_username
}

output "tcp_lb_listener_ports" {
  value = aws_lb_listener.cf_apps_tcp.*.port
}
