data "terraform_remote_state" "iaas" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = "${var.iaas_stack_name}/terraform.tfstate"
  }
}

data "terraform_remote_state" "tooling" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = "${var.tooling_stack_name}/terraform.tfstate"
  }
}

data "terraform_remote_state" "external" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = "${var.external_stack_name}/terraform.tfstate"
  }
}
