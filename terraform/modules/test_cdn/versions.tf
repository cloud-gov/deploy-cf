terraform {
  required_version = "< 2.0.0"
  required_providers {
    cloudfoundryv3 = {
      source  = "cloudfoundry/cloudfoundry"
      version = "< 2.0"
    }
  }
}
