terraform {
  required_version = "< 2.0.0"
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.53.0"
    }
    cloudfoundryv3 = {
      source  = "cloudfoundry/cloudfoundry"
      version = "1.4.0"
    }
  }
}
