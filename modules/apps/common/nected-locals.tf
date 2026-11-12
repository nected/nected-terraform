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


locals {
  # Passed to the charts as `secretKeys`, which filters them out of the
  # ConfigMap that envVars renders into.
  #
  # Removing them from envVars here does NOT work: Helm deep-merges maps, so
  # each subchart's own default survives and reappears in the ConfigMap. Only
  # the chart-side filter actually removes them, so the values stay in envVars
  # and the charts drop them.
  #
  # Only keys the vault actually holds belong here: a key listed but not stored
  # is stripped from the ConfigMap and supplied by nothing. DEFAULT_VIDHAAN_SECRET_KEY,
  # MICROSOFT_CLIENT_SECRET, COPILOT_API_KEY, PRODUCT_API_KEY and
  # TEMPORAL_EXECUTER_API_KEY are deliberately absent, so they keep their chart
  # defaults.
  secret_env_keys = [
    "AES_SECRET",
    "AWS_SECRET_KEY",
    "DB_PASSWORD",
    "ELASTIC_API_KEY",
    "ELASTIC_PASSWORD",
    "EMAIL_PASSWORD",
    "JWT_SECRET",
    "MASTER_DB_PASSWORD",
    "NECTED_USER_PASSWORD",
    "REDIS_PASSWORD",
    "VIDHAAN_PRE_SHARED_KEY",
    "VIDHAAN_REDIS_PASSWORD",
  ]

  konark_env  = merge(local.konark_base_env, lookup(var.nected_env_overrides, "konark", {}))
  nalanda_env = merge(local.nalanda_base_env, lookup(var.nected_env_overrides, "nalanda", {}))
  vidhaan_env = merge(local.vidhaan_base_env, lookup(var.nected_env_overrides, "vidhaan", {}))
  medha_env   = merge(local.medha_base_env, lookup(var.nected_env_overrides, "medha", {}))
  garuda_env  = merge(local.garuda_base_env, lookup(var.nected_env_overrides, "garuda", {}))

  # Empty unless the secret manager supplies the values, so behaviour is
  # unchanged for anyone not using it.
  nected_secret_keys = var.secret_manager.enabled ? local.secret_env_keys : []

  # The chart's top-level existingSecret anchor. When the secret manager is on,
  # the job's target secret is authoritative.
  nected_secret_name = (
    var.secret_manager.enabled
    ? var.secret_manager.target_secret
    : var.nected_existing_secret_name
  )

  # Shared by both releases: whichever installs first writes the Secret, and
  # the second sees an unchanged payload hash and exits without writing.
  secretsmanager_values = {
    provider = var.secret_manager.provider
    failOpen = var.secret_manager.fail_open
    aws      = { region = var.secret_manager.aws_region }
    azure    = { vaultUrl = var.secret_manager.azure_vault_url }

    credentials = {
      enabled        = var.secret_manager.enabled
      secret         = var.secret_manager.target_secret
      remoteKeys     = var.secret_manager.remote_keys
      requiredKeys   = var.secret_manager.required_keys
      aliases        = var.secret_manager.aliases
      restartTargets = []
    }

    serviceAccount = {
      name     = var.secret_manager.service_account_name
      roleArn  = var.secret_manager.service_account_role_arn
      clientId = var.secret_manager.service_account_client_id
    }
  }
}
