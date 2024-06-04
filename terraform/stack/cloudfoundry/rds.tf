variable "rds_apply_immediately" {
  default = "false"
}
variable "rds_allow_major_version_upgrade" {
  default = "false"
}
variable "rds_db_engine" {
  default = "postgres"
}
variable "rds_db_engine_version" {
  default = "16.2-R2"
}
variable "rds_db_name" {
}
variable "rds_db_size" {
  default = 100
}
variable "rds_instance_type" {
  default = "db.m5.large"
}
variable "rds_parameter_group_family" {
  default = "postgres16"
}
variable "rds_password" {
  sensitive = true
}
variable "rds_security_groups" {
  type = list(string)
}
variable "rds_subnet_group" {
}
variable "rds_username" {
}

# module "rds_network" {
#   source = "../../rds_network_v2"

#   stack_description     = var.stack_description
#   vpc_id                = module.vpc.vpc_id
#   availability_zones    = var.availability_zones
#   allowed_cidrs         = var.target_concourse_security_group_cidrs
#   security_groups       = var.rds_security_groups
#   security_groups_count = var.rds_security_groups_count
#   rds_private_cidrs     = var.rds_private_cidrs
#   route_table_ids       = module.vpc.private_route_table_ids
# }



module "cfdb" {
  source = "github.com/cloud-gov/cg-provision//terraform/modules/rds"

  stack_description               = "${var.env_name}-cfdb"
  rds_instance_type               = var.rds_instance_type
  rds_db_size                     = var.rds_db_size
  rds_db_engine                   = var.rds_db_engine
  rds_db_engine_version           = var.rds_db_engine_version
  rds_db_name                     = var.rds_db_name
  rds_username                    = var.rds_username
  rds_password                    = var.rds_password
  rds_subnet_group                = var.rds_subnet_group
  rds_security_groups             = var.rds_security_groups
  rds_parameter_group_family      = var.rds_parameter_group_family
  rds_allow_major_version_upgrade = var.rds_allow_major_version_upgrade
  rds_apply_immediately           = var.rds_apply_immediately
}

