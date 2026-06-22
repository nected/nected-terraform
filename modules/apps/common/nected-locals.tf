locals {
  scheme = "https"
  konark_base_env = {
    VITE_API_HOST          = "${var.scheme}://${var.backend_domain}"
    VITE_GRAPHQL_URL       = "${var.scheme}://${var.backend_domain}/graphql/query"
    VITE_NGINX_SERVER_NAME = var.ui_domain
  }
  nalanda_base_env = {
    ALLOWED_CORS_ORIGIN = "${var.scheme}://${var.backend_domain},${var.scheme}://${var.ui_domain}"
    ALLOWED_HOSTS       = var.backend_domain
    BACKEND_URL         = "${var.scheme}://${var.backend_domain}"

    MASTER_DB_USER     = var.pg_admin_user
    MASTER_DB_PASSWORD = var.pg_admin_passwd
    MASTER_DB_HOST     = var.postgresql_host
    MASTER_SSL_MODE    = "require"

    VIDHAAN_PRE_SHARED_KEY = var.nected_pre_shared_key

    REDIS_TLS_ENABLED = "${var.redis_tls_enabled}"
    REDIS_HOST        = var.redis_endpoint
    REDIS_PORT        = format("%s", var.redis_port)
    REDIS_PASSWORD    = var.redis_password
    # Azure Managed Redis supports only DB index 0, so pin every service to 0.
    REDIS_DATABASE = "0"

    VIDHAAN_REDIS_TLS_ENABLED = "${var.redis_tls_enabled}"
    VIDHAAN_REDIS_HOST        = var.redis_endpoint
    VIDHAAN_REDIS_PORT        = format("%s", var.redis_port)
    VIDHAAN_REDIS_PASSWORD    = var.redis_password
    VIDHAAN_REDIS_DATABASE    = "0"

    ELASTIC_HOSTS    = "${var.elasticsearch_scheme}://${var.elasticsearch_ip}:${var.elasticsearch_port}"
    ELASTIC_PROVIDER = var.elasticsearch_provider
    ELASTIC_USER     = var.elasticsearch_admin_username
    ELASTIC_PASSWORD = var.elasticsearch_admin_password

    ASSETS_BASE_URL = "${var.scheme}://${var.ui_domain}/assets/konark"
    KONARK_BASE_URL = "${var.scheme}://${var.ui_domain}"

    NECTED_USER_EMAIL    = var.console_user_email
    NECTED_USER_PASSWORD = var.console_user_password

    DEFAULT_VIDHAAN_SCHEME = var.scheme
    DEFAULT_VIDHAAN_DOMAIN = var.router_domain
  }
  vidhaan_base_env = {
    VIDHAAN_PRE_SHARED_KEY = var.nected_pre_shared_key
    DB_USER                = var.pg_admin_user
    DB_PASSWORD            = var.pg_admin_passwd
    DB_HOST                = var.postgresql_host
    DB_MAX_IDLE_CONNS      = "20"
    DB_MAX_OPEN_CONNS      = "30"
    SSL_MODE               = "require"

    REDIS_TLS_ENABLED = "${var.redis_tls_enabled}"
    REDIS_HOST        = "${var.redis_endpoint}:${var.redis_port}"
    REDIS_PASSWORD    = var.redis_password
    REDIS_DATABASE    = "0"

    ELASTIC_ADDRESSES = "${var.elasticsearch_scheme}://${var.elasticsearch_ip}:${var.elasticsearch_port}"
    ELASTIC_PROVIDER  = var.elasticsearch_provider
    ELASTIC_USERNAME  = var.elasticsearch_admin_username
    ELASTIC_PASSWORD  = var.elasticsearch_admin_password

    AUDIT_LOG_ENABLED = "true"
    SKIP_SUBDOMAINS   = var.router_domain

    TEMPORAL_EXECUTER_WORKFLOW_TASK_POLLERS                    = "10"
    TEMPORAL_EXECUTER_ACTIVITY_TASK_POLLERS                    = "10"
    TEMPORAL_EXECUTER_WORKFLOW_CONCURRENT_EXECUTION_SIZE       = "2000"
    TEMPORAL_EXECUTER_ACTIVITY_CONCURRENT_EXECUTION_SIZE       = "1000"
    TEMPORAL_EXECUTER_LOCAL_ACTIVITY_CONCURRENT_EXECUTION_SIZE = "4000"
    TEMPORAL_EXECUTER_ACTIVITY_EXECUTION_RPS                   = "50000"
    TEMPORAL_EXECUTER_LOCAL_ACTIVITY_EXECUTION_RPS             = "200000"
  }
  medha_base_env = {
    DB_ENABLED      = "true"
    DB_HOST         = var.postgresql_host
    DB_USER         = var.pg_admin_user
    DB_PASSWORD     = var.pg_admin_passwd
    DB_SSL_MODE     = "require"
    COPILOT_PDF_OCR = "true"
  }
  garuda_base_env = {
    REDIS_ENABLED     = "true"
    REDIS_TLS_ENABLED = "${var.redis_tls_enabled}"
    REDIS_HOST        = "${var.redis_endpoint}"
    REDIS_PORT        = "${var.redis_port}"
    REDIS_PASSWORD    = var.redis_password
    REDIS_DB          = "0"
  }
}

