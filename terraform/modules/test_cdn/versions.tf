terraform {
  required_version = "< 2.0.0"
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = "< 2.0"
    }
  }
}
