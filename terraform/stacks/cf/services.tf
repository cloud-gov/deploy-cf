resource "cloudfoundry_service_instance" "rds_instance" {
  name             = "opensearch-test-db"
  service          = "aws-rds"
  plan             = "micro-psql" 
}