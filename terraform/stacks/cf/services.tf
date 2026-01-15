resource "cloudfoundry_service_instance" "rds_instance" {
  name             = "opensearch-test-db"
  space        = data.cloudfoundry_space.space.id
  service_plan = data.cloudfoundry_service_plan.rds_plan.id
}

data "cloudfoundry_org" "org" {
  name = "cf_smoke_tests_org"
}

data "cloudfoundry_space" "space" {
  name = "cf_smoke_tests_space"
  org  = data.cloudfoundry_org.org.id
}

data "cloudfoundry_service_plan" "rds_plan" {
  name = "micro-psql" 
  service_offering_name = "aws-rds"  
}
