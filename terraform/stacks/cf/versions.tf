terraform {
  required_version = ">= 0.14"
  required_providers {
    cloudfoundryv3 = {
      source  = "cloudfoundry/cloudfoundry"
      version = "< 2.0"
    }
  }
}
