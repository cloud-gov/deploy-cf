#!/bin/bash

cat > integration-config/integration_config.json <<EOF
{
  "api": "${API_URL}",
  "apps_domain": "${APPS_DOMAIN}",
  "admin_user": "${ADMIN_USER}",
  "admin_password": "${ADMIN_PASSWORD}",
  "use_existing_user": true,
  "existing_user": "${EXISTING_USER}",
  "existing_user_password": "${EXISTING_USER_PASSWORD}",
  "include_container_networking": true,
  "include_service_discovery": true,
  "include_docker": true,
  "include_v3": false,
  "skip_ssl_validation": false,
  "use_log_cache": false
}
EOF
