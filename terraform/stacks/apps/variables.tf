variable "stack_name" {
  type        = string
  description = "One of development, staging, production."
}

variable "remote_state_bucket_iaas" {
  type        = string
  description = "Bucket where remote state for AWS GovCloud is stored."
}

variable "remote_state_bucket_external" {
  type        = string
  description = "Bucket where remote state for AWS Commercial is stored."
}

variable "external_remote_state_reader_access_key_id" {
  type        = string
  description = "Access key ID for the IAM user that has permission to read from the state bucket."
}

variable "external_remote_state_reader_secret_access_key" {
  type        = string
  sensitive   = true
  description = "Secret access key for the IAM user that has permission to read from the state bucket."
}

variable "external_remote_state_reader_region" {
  type        = string
  description = "The region in which the remote state bucket is located."
}

variable "external_stack_name" {
  type = string
}

variable "csb_aws_region_govcloud" {
  type = string
}

variable "csb_aws_region_commercial" {
  type = string
}

variable "csb_aws_ses_default_zone" {
  type = string
}

variable "csb_docker_image_name" {
  type = string
}

variable "csb_docker_image_version" {
  type = string
}

variable "csb_org_name" {
  type = string
}

variable "csb_space_name" {
  type = string
}

variable "csb_broker_route_domain" {
  type = string
}

variable "csb_docproxy_domain" {
  type = string
}

variable "csb_docproxy_docker_image_name" {
  type = string
}

variable "csb_docproxy_docker_image_version" {
  type = string
}

variable "csb_docproxy_instances" {
  type    = number
  default = 1
}
