variable "iaas_stack_name" {
}

variable "organization_id" {
  type = string
  description = "Organization GUID to use for test CDN app"
}

variable "space_name" {
  type = string
  description = "Space name to use for test CDN app"
  default = "hello-worlds"
}
