resource "helm_release" "nected" {
  name       = "nected"
  repository = "https://nected.github.io/helm-charts"
  chart      = "nected"
  namespace  = "default"

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
    helm_release.agic,
    helm_release.temporal,
    helm_release.cert-manager,
    azurerm_postgresql_flexible_server.postgresql,
    azurerm_redis_cache.redis
  ]

  values = [
    yamlencode({
      konark = {
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
        ingress = {
          enabled   = "true"
          className = "azure-application-gateway"
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          hosts = [
            {
              host = local.ui_domain
              paths = [
                {
                  path     = "/"
                  pathType = "Prefix"
                }
              ]
            }
          ]
          tls = [
            {
              secretName = local.cert_secret_name
              hosts      = [local.ui_domain]
            }
          ]
        }
      }
      nalanda = {
        replicaCount      = 1
        existingSecretMap = local.common_secret_map

        envVars = {
          ALLOWED_CORS_ORIGIN = "${var.scheme}://${local.backend_domain},${var.scheme}://${local.ui_domain}"
          ALLOWED_HOSTS       = local.backend_domain
          BACKEND_URL         = "${var.scheme}://${local.backend_domain}"

          MASTER_DB_USER     = var.pg_admin_user
          MASTER_DB_PASSWORD = var.pg_admin_passwd
          MASTER_DB_HOST     = azurerm_postgresql_flexible_server.postgresql.fqdn
          MASTER_SSL_MODE    = "require"

          REDIS_TLS_ENABLED = "true"
          REDIS_HOST        = azurerm_redis_cache.redis.hostname
          REDIS_PORT        = format("%s", azurerm_redis_cache.redis.ssl_port)
          REDIS_PASSWORD    = azurerm_redis_cache.redis.primary_access_key

          VIDHAAN_PRE_SHARED_KEY    = var.nected_pre_shared_key
          VIDHAAN_REDIS_TLS_ENABLED = "true"
          VIDHAAN_REDIS_HOST        = azurerm_redis_cache.redis.hostname
          VIDHAAN_REDIS_PORT        = format("%s", azurerm_redis_cache.redis.ssl_port)
          VIDHAAN_REDIS_PASSWORD    = azurerm_redis_cache.redis.primary_access_key

          ELASTIC_HOSTS    = "http://${azurerm_linux_virtual_machine.elasticsearch.private_ip_address}:9200"
          ELASTIC_USER     = var.elasticsearch_admin_username
          ELASTIC_PASSWORD = var.elasticsearch_admin_password

          SEND_EMAIL         = "${var.smtp_config.SEND_EMAIL}"
          EMAIL_PROVIDER     = var.smtp_config.EMAIL_PROVIDER
          SENDER_EMAIL       = var.smtp_config.SENDER_EMAIL
          SENDER_NAME        = var.smtp_config.SENDER_NAME
          EMAIL_INSECURE_TLS = "${var.smtp_config.EMAIL_INSECURE_TLS}"
          EMAIL_HOST         = var.smtp_config.EMAIL_HOST
          EMAIL_PORT         = "${var.smtp_config.EMAIL_PORT}"
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

        ingress = {
          enabled   = "true"
          className = "azure-application-gateway"
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          hosts = [
            {
              host = local.backend_domain
              paths = [
                {
                  path     = "/"
                  pathType = "Prefix"
                }
              ]
            }
          ]
          tls = [
            {
              secretName = local.cert_secret_name
              hosts      = [local.backend_domain]
            }
          ]
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
      vidhaan-executer = {
        replicaCount      = 1
        existingSecretMap = local.common_secret_map

        envVars = {
          VIDHAAN_PRE_SHARED_KEY = var.nected_pre_shared_key
          DB_USER                = var.pg_admin_user
          DB_PASSWORD            = var.pg_admin_passwd
          DB_HOST                = azurerm_postgresql_flexible_server.postgresql.fqdn
          SSL_MODE               = "require"

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

      vidhaan-router = {
        enabled           = "true"
        replicaCount      = 1
        existingSecretMap = local.common_secret_map
        envVars = {
          VIDHAAN_PRE_SHARED_KEY = var.nected_pre_shared_key
          DB_USER                = var.pg_admin_user
          DB_PASSWORD            = var.pg_admin_passwd
          DB_HOST                = azurerm_postgresql_flexible_server.postgresql.fqdn
          SSL_MODE               = "require"

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
            cpu    = "250m"
            memory = "512Mi"
          }
        }

        autoscaling = {
          enabled                           = "false"
          minReplicas                       = 1
          maxReplicas                       = 1
          targetCPUUtilizationPercentage    = 80
          targetMemoryUtilizationPercentage = 80
        }
        ingress = {
          enabled   = "true"
          className = "azure-application-gateway"
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          hosts = [
            {
              host = local.router_domain
              paths = [
                {
                  path     = "/"
                  pathType = "Prefix"
                }
              ]
            }
          ]
          tls = [
            {
              secretName = local.cert_secret_name
              hosts      = [local.router_domain]
            }
          ]
        }
      }
      medha = {
        enabled      = "true"
        replicaCount = 1

        resources = {
          requests = {
            cpu    = "600m"
            memory = "1024Mi"
          }
        }

        autoscaling = {
          enabled                           = "false"
          minReplicas                       = 1
          maxReplicas                       = 1
          targetCPUUtilizationPercentage    = 80
          targetMemoryUtilizationPercentage = 80
        }
      }
    })
  ]
}
