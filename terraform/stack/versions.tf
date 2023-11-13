terraform {
  required_version = ">= 0.14"
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "< 1.0.0"
    }

    zipper = {
      source = "ArthurHlt/zipper"
      version = "0.14.0"
    }
  }
}
