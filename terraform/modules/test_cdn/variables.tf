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

variable "source_code_repo" {
  type = string
  description = "HTTPS link to git repo containing source code for test CDN app"
  default = "https://github.com/cloud-gov/cf-hello-worlds.git"
}

variable "source_code_path" {
  type = string
  description = "Path in source_code_repo containing app code"
  default = "static"
}

variable "git_clone_dir" {
  type = string
  description = "Subdirectory of module path to clone git repo"
  default = "cf-hello-worlds"
}

variable "zip_output_filename" {
  type = string
  description = "Name of zip file containing source code for test CDN app"
  default = "hello-world-static.zip"
}
