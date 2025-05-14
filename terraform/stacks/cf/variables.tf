variable "remote_state_bucket" {
}

variable "tooling_stack_name" {
}

variable "iaas_stack_name" {
}

variable "domain_name" {
}

variable "devtools_org_name" {
  default = "cloud-gov-devtools-production"
}

variable "devtools_secondary_org" {
  default = false
}

variable "devtools_org_name_secondary" {
  default = "cloud-gov-devtools-staging"
}
