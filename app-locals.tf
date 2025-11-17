locals {

  backend_domain   = "${var.backend_domain_prefix}.${var.hosted_zone}"
  router_domain    = "${var.router_domain_prefix}.${var.hosted_zone}"
  ui_domain        = "${var.ui_domain_prefix}.${var.hosted_zone}"
  cert_secret_name = "${var.project}-tls-${var.environment}"

  temporal_cluster_name = "${var.project}-${var.environment}"

  common_secret_map = [
    {
      name = "ENCRYPTKEY_EAR_1"
      value_from = {
        secret_key_ref = {
          name = "encryption-at-rest-secret"
          key  = "encryption-at-rest"
        }
      }
    }
  ]

  konark_values = {
    envVars = {
      VITE_API_HOST          = "${var.scheme}://${local.backend_domain}"
      VITE_GRAPHQL_URL       = "${var.scheme}://${local.backend_domain}/graphql/query"
      VITE_NGINX_SERVER_NAME = local.ui_domain
    }

    resources = {
      requests = {
        cpu    = "350m"
        memory = "512Mi"
      }
    }
  }

  nalanda_values = {
    replicaCount      = 1
    existingSecretMap = local.common_secret_map

    envVars = {
      ALLOWED_CORS_ORIGIN = "${var.scheme}://${local.backend_domain},${var.scheme}://${local.ui_domain}"
      ALLOWED_HOSTS       = local.backend_domain
      BACKEND_URL         = "${var.scheme}://${local.backend_domain}"

      MASTER_DB_USER     = var.pg_admin_user
      MASTER_DB_PASSWORD = var.pg_admin_passwd
      MASTER_DB_HOST     = azurerm_postgresql_flexible_server.postgresql.fqdn

      REDIS_TLS_ENABLED = "true"
      REDIS_HOST        = azurerm_redis_cache.redis.hostname
      REDIS_PORT        = azurerm_redis_cache.redis.ssl_port
      REDIS_PASSWORD    = azurerm_redis_cache.redis.primary_access_key

      VIDHAAN_REDIS_TLS_ENABLED = "true"
      VIDHAAN_REDIS_HOST        = azurerm_redis_cache.redis.hostname
      VIDHAAN_REDIS_PORT        = azurerm_redis_cache.redis.ssl_port
      VIDHAAN_REDIS_PASSWORD    = azurerm_redis_cache.redis.primary_access_key

      ELASTIC_HOSTS    = "http://${azurerm_linux_virtual_machine.elasticsearch.private_ip_address}:9200"
      ELASTIC_USER     = var.elasticsearch_admin_username
      ELASTIC_PASSWORD = var.elasticsearch_admin_password

      SEND_EMAIL         = var.smtp_config.SEND_EMAIL
      EMAIL_PROVIDER     = var.smtp_config.EMAIL_PROVIDER
      SENDER_EMAIL       = var.smtp_config.SENDER_EMAIL
      SENDER_NAME        = var.smtp_config.SENDER_NAME
      EMAIL_INSECURE_TLS = var.smtp_config.EMAIL_INSECURE_TLS
      EMAIL_HOST         = var.smtp_config.EMAIL_HOST
      EMAIL_PORT         = var.smtp_config.EMAIL_PORT
      EMAIL_USERNAME     = var.smtp_config.EMAIL_USERNAME
      EMAIL_PASSWORD     = var.smtp_config.EMAIL_PASSWORD

      ASSETS_BASE_URL        = "${var.scheme}://${local.ui_domain}/assets/konark"
      KONARK_BASE_URL        = "${var.scheme}://${local.ui_domain}"
      SIGNUP_DOMAINS         = ""
      NECTED_USER_EMAIL      = var.console_user_email
      NECTED_USER_PASSWORD   = var.console_user_password
      DEFAULT_VIDHAAN_SCHEME = var.scheme
      DEFAULT_VIDHAAN_DOMAIN = local.router_domain
    }

    resources = {
      requests = {
        cpu    = "250m"
        memory = "512Mi"
      }
    }

    autoscaling = {
      enabled                           = false
      minReplicas                       = 1
      maxReplicas                       = 1
      targetCPUUtilizationPercentage    = 80
      targetMemoryUtilizationPercentage = 80
    }
  }

  vidhaan_executer_values = {
    replicaCount      = 1
    existingSecretMap = local.common_secret_map

    envVars = {
      DB_USER     = var.pg_admin_user
      DB_PASSWORD = var.pg_admin_passwd
      DB_HOST     = azurerm_postgresql_flexible_server.postgresql.fqdn

      REDIS_TLS_ENABLED = "true"
      REDIS_HOST        = "${azurerm_redis_cache.redis.hostname}:${azurerm_redis_cache.redis.ssl_port}"
      REDIS_PASSWORD    = azurerm_redis_cache.redis.primary_access_key

      ELASTIC_ADDRESSES = "http://${azurerm_linux_virtual_machine.elasticsearch.private_ip_address}:9200"
      ELASTIC_USERNAME  = var.elasticsearch_admin_username
      ELASTIC_PASSWORD  = var.elasticsearch_admin_password

      AUDIT_LOG_ENABLED = "true"
      SKIP_SUBDOMAINS   = local.router_domain
    }

    resources = {
      requests = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }

    autoscaling = {
      enabled                           = false
      minReplicas                       = 1
      maxReplicas                       = 1
      targetCPUUtilizationPercentage    = 80
      targetMemoryUtilizationPercentage = 80
    }
  }

  vidhaan_router_values = {
    enabled           = true
    replicaCount      = 1
    existingSecretMap = local.common_secret_map
    envVars           = local.vidhaan_executer_values.envVars

    resources = {
      requests = {
        cpu    = "250m"
        memory = "512Mi"
      }
    }

    autoscaling = {
      enabled                           = false
      minReplicas                       = 1
      maxReplicas                       = 1
      targetCPUUtilizationPercentage    = 80
      targetMemoryUtilizationPercentage = 80
    }
  }

  medha_values = {
    enabled      = true
    replicaCount = 1

    resources = {
      requests = {
        cpu    = "600m"
        memory = "1024Mi"
      }
    }

    autoscaling = {
      enabled                           = false
      minReplicas                       = 1
      maxReplicas                       = 1
      targetCPUUtilizationPercentage    = 80
      targetMemoryUtilizationPercentage = 80
    }
  }
}