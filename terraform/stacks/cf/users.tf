resource "cloudfoundry_user" "opensearch_e2e_test_setup_user" {
  name     = "opensearch-e2e-test-setup-user"
  password = var.opensearch_e2e_test_setup_user_password

  groups = ["cloud_controller.admin", "scim.read", "scim.write"]
}
