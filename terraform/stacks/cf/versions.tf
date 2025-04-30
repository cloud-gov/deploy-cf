terraform {
  required_version = ">= 0.14"
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.53.0"
    }
    cloudfoundryv3 = {
      source  = "cloudfoundry/cloudfoundry"
      version = "< 2.0"
    }
  }
}
