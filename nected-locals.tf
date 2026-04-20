locals {
  scheme = "https"
  konark_base_env = {
    VITE_API_HOST          = "${local.scheme}://${local.backend_domain}"
    VITE_GRAPHQL_URL       = "${local.scheme}://${local.backend_domain}/graphql/query"
    VITE_NGINX_SERVER_NAME = local.ui_domain
  }
  nalanda_base_env = {
    ALLOWED_CORS_ORIGIN = "${local.scheme}://${local.backend_domain},${local.scheme}://${local.ui_domain}"
    ALLOWED_HOSTS       = local.backend_domain
    BACKEND_URL         = "${local.scheme}://${local.backend_domain}"

    MASTER_DB_USER     = var.pg_admin_user
    MASTER_DB_PASSWORD = var.pg_admin_passwd
    MASTER_DB_HOST     = azurerm_postgresql_flexible_server.postgresql.fqdn
    MASTER_SSL_MODE    = "require"

    VIDHAAN_PRE_SHARED_KEY = var.nected_pre_shared_key

    REDIS_TLS_ENABLED = "${local.redis_tls_enabled}"
    REDIS_HOST        = local.redis_endpoint
    REDIS_PORT        = format("%s", local.redis_port)
    REDIS_PASSWORD    = local.redis_password

    VIDHAAN_REDIS_TLS_ENABLED = "${local.redis_tls_enabled}"
    VIDHAAN_REDIS_HOST        = local.redis_endpoint
    VIDHAAN_REDIS_PORT        = format("%s", local.redis_port)
    VIDHAAN_REDIS_PASSWORD    = local.redis_password

    ELASTIC_HOSTS    = "http://${azurerm_linux_virtual_machine.elasticsearch.private_ip_address}:9200"
    ELASTIC_USER     = var.elasticsearch_admin_username
    ELASTIC_PASSWORD = var.elasticsearch_admin_password

    ASSETS_BASE_URL = "${local.scheme}://${local.ui_domain}/assets/konark"
    KONARK_BASE_URL = "${local.scheme}://${local.ui_domain}"

    NECTED_USER_EMAIL    = var.console_user_email
    NECTED_USER_PASSWORD = var.console_user_password

    DEFAULT_VIDHAAN_SCHEME = local.scheme
    DEFAULT_VIDHAAN_DOMAIN = local.router_domain
  }
  vidhaan_base_env = {
    VIDHAAN_PRE_SHARED_KEY = var.nected_pre_shared_key
    DB_USER                = var.pg_admin_user
    DB_PASSWORD            = var.pg_admin_passwd
    DB_HOST                = azurerm_postgresql_flexible_server.postgresql.fqdn
    SSL_MODE               = "require"

    REDIS_TLS_ENABLED = "${local.redis_tls_enabled}"
    REDIS_HOST        = "${local.redis_endpoint}:${local.redis_port}"
    REDIS_PASSWORD    = local.redis_password

    ELASTIC_ADDRESSES = "http://${azurerm_linux_virtual_machine.elasticsearch.private_ip_address}:9200"
    ELASTIC_USERNAME  = var.elasticsearch_admin_username
    ELASTIC_PASSWORD  = var.elasticsearch_admin_password

    AUDIT_LOG_ENABLED = "true"
    SKIP_SUBDOMAINS   = local.router_domain

    TEMPORAL_EXECUTER_WORKFLOW_TASK_POLLERS                    = "8"
    TEMPORAL_EXECUTER_ACTIVITY_TASK_POLLERS                    = "4"
    TEMPORAL_EXECUTER_WORKFLOW_CONCURRENT_EXECUTION_SIZE       = "1000"
    TEMPORAL_EXECUTER_ACTIVITY_CONCURRENT_EXECUTION_SIZE       = "1000"
    TEMPORAL_EXECUTER_LOCAL_ACTIVITY_CONCURRENT_EXECUTION_SIZE = "3000"
    TEMPORAL_EXECUTER_ACTIVITY_EXECUTION_RPS                   = "50000"
    TEMPORAL_EXECUTER_LOCAL_ACTIVITY_EXECUTION_RPS             = "100000"
  }
  medha_base_env = {
    DB_ENABLED      = "true"
    DB_HOST         = azurerm_postgresql_flexible_server.postgresql.fqdn
    DB_USER         = var.pg_admin_user
    DB_PASSWORD     = var.pg_admin_passwd
    DB_SSL_MODE     = "require"
    COPILOT_PDF_OCR = "true"
  }
  garuda_base_env = {
    REDIS_ENABLED     = "true"
    REDIS_TLS_ENABLED = "${local.redis_tls_enabled}"
    REDIS_HOST        = "${local.redis_endpoint}"
    REDIS_PORT        = "${local.redis_port}"
    REDIS_PASSWORD    = local.redis_password
    REDIS_DB          = "2"
  }
}

