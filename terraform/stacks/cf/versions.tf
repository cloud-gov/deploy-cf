terraform {
  required_version = ">= 0.14"
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = "< 2.0"
    }
  }
}
