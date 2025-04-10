variable "remote_state_bucket" {
}

variable "tooling_stack_name" {
}

variable "iaas_stack_name" {
}

variable "domain_name" {
}

variable "opensearch_e2e_test_setup_user_password" {
  type        = string
  description = "Password for OpenSearch E2E test setup user"
}
