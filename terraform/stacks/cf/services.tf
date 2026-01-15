# Get organization
resource "cloudfoundry_org" "opensearch_smoke_test_org" {
  name = ""opensearch_smoke_test_org"
}

# Get space
resource "cloudfoundry_space" "opensearch_smoke_test_space" {
  name = "opensearch_smoke_tests_space"
  org  = cloudfoundry_org.opensearch_smoke_test_org.id
}

# Get service plan
data "cloudfoundry_service_plan" "rds_plan" {
  name                  = "micro-psql"
  service_offering_name = "aws-rds"
}

# Create RDS service instance
resource "cloudfoundry_service_instance" "rds_instance" {
  name         = "opensearch-test-db"
  space        = cloudfoundry_space.opensearch_smoke_test_space.id
  service_plan = data.cloudfoundry_service_plan.rds_plan.id
  type         = "managed"
}