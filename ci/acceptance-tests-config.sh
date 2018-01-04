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
  "skip_ssl_validation": false
}
EOF
