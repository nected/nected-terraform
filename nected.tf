resource "helm_release" "nected" {
  name       = "nected"
  repository = "https://charts.nected.io"
  chart      = "nected"
  namespace  = "default"
  timeout    = 600
  version    = var.nected_chart_version

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
    helm_release.agic,
    helm_release.temporal,
    helm_release.cert-manager,
    azurerm_postgresql_flexible_server.postgresql,
    helm_release.datastore,
    azurerm_redis_cache.redis,
    time_sleep.wait_for_redis
  ]

  values = [
    yamlencode({
      konark = {
        envVars = merge(local.konark_base_env, lookup(var.nected_env_overrides, "konark", {}))

        livenessProbe = {
          failureThreshold = 10
        }

        readinessProbe = {
          failureThreshold = 10
        }

        resources = merge(
          {
            requests = {
              cpu    = var.nected_pods_resources.konark_cpu_request
              memory = var.nected_pods_resources.konark_memory_request
            }
          },
          var.nected_pods_resources.konark_cpu_limit != null || var.nected_pods_resources.konark_memory_limit != null ? {
            limits = merge(
              var.nected_pods_resources.konark_cpu_limit != null ? { cpu = var.nected_pods_resources.konark_cpu_limit } : {},
              var.nected_pods_resources.konark_memory_limit != null ? { memory = var.nected_pods_resources.konark_memory_limit } : {}
            )
          } : {}
        )
        ingress = {
          enabled = "true"
          annotations = {
            "kubernetes.io/ingress.class"                       = "azure/application-gateway"
            "appgw.ingress.kubernetes.io/ssl-redirect"          = "true"
            "appgw.ingress.kubernetes.io/use-private-ip"        = local.ingress_use_private
            "appgw.ingress.kubernetes.io/appgw-ssl-certificate" = local.alb_listener_cert_name
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
              hosts = [local.ui_domain]
            }
          ]
        }
      }
      nalanda = {
        existingSecret = var.nected_existing_secret_name
        envVars        = merge(local.nalanda_base_env, lookup(var.nected_env_overrides, "nalanda", {}))

        autoSetup = {
          resources = merge(
            var.nected_pods_resources.setup_job_cpu_request != null || var.nected_pods_resources.setup_job_memory_request != null ? {
              requests = merge(
                var.nected_pods_resources.setup_job_cpu_request != null ? { cpu = var.nected_pods_resources.setup_job_cpu_request } : {},
                var.nected_pods_resources.setup_job_memory_request != null ? { memory = var.nected_pods_resources.setup_job_memory_request } : {}
              )
            } : {},
            var.nected_pods_resources.setup_job_cpu_limit != null || var.nected_pods_resources.setup_job_memory_limit != null ? {
              limits = merge(
                var.nected_pods_resources.setup_job_cpu_limit != null ? { cpu = var.nected_pods_resources.setup_job_cpu_limit } : {},
                var.nected_pods_resources.setup_job_memory_limit != null ? { memory = var.nected_pods_resources.setup_job_memory_limit } : {}
              )
            } : {}
          )
        }

        ingress = {
          enabled = "true"
          annotations = {
            "kubernetes.io/ingress.class"                       = "azure/application-gateway"
            "appgw.ingress.kubernetes.io/ssl-redirect"          = "true"
            "appgw.ingress.kubernetes.io/use-private-ip"        = local.ingress_use_private
            "appgw.ingress.kubernetes.io/appgw-ssl-certificate" = local.alb_listener_cert_name
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
              hosts = [local.backend_domain]
            }
          ]
        }

        resources = merge(
          {
            requests = {
              cpu    = var.nected_pods_resources.nalanda_cpu_request
              memory = var.nected_pods_resources.nalanda_memory_request
            }
          },
          var.nected_pods_resources.nalanda_cpu_limit != null || var.nected_pods_resources.nalanda_memory_limit != null ? {
            limits = merge(
              var.nected_pods_resources.nalanda_cpu_limit != null ? { cpu = var.nected_pods_resources.nalanda_cpu_limit } : {},
              var.nected_pods_resources.nalanda_memory_limit != null ? { memory = var.nected_pods_resources.nalanda_memory_limit } : {}
            )
          } : {}
        )

        autoscaling = {
          enabled                           = var.nected_pods_replicas.autoscaling
          minReplicas                       = var.nected_pods_replicas.min_nalanda
          maxReplicas                       = var.nected_pods_replicas.max_nalanda
          targetCPUUtilizationPercentage    = 85
          targetMemoryUtilizationPercentage = 85
        }
      }

      vidhaan-executer = {
        existingSecret = var.nected_existing_secret_name
        envVars        = merge(local.vidhaan_base_env, lookup(var.nected_env_overrides, "vidhaan", {}))

        resources = merge(
          {
            requests = {
              cpu    = var.nected_pods_resources.executer_cpu_request
              memory = var.nected_pods_resources.executer_memory_request
            }
          },
          var.nected_pods_resources.executer_cpu_limit != null || var.nected_pods_resources.executer_memory_limit != null ? {
            limits = merge(
              var.nected_pods_resources.executer_cpu_limit != null ? { cpu = var.nected_pods_resources.executer_cpu_limit } : {},
              var.nected_pods_resources.executer_memory_limit != null ? { memory = var.nected_pods_resources.executer_memory_limit } : {}
            )
          } : {}
        )

        autoscaling = {
          enabled                           = var.nected_pods_replicas.autoscaling
          minReplicas                       = var.nected_pods_replicas.min_executer
          maxReplicas                       = var.nected_pods_replicas.max_executer
          targetCPUUtilizationPercentage    = 85
          targetMemoryUtilizationPercentage = 85
        }
      }

      vidhaan-router = {
        existingSecret = var.nected_existing_secret_name
        envVars        = merge(local.vidhaan_base_env, lookup(var.nected_env_overrides, "vidhaan", {}))

        resources = merge(
          {
            requests = {
              cpu    = var.nected_pods_resources.router_cpu_request
              memory = var.nected_pods_resources.router_memory_request
            }
          },
          var.nected_pods_resources.router_cpu_limit != null || var.nected_pods_resources.router_memory_limit != null ? {
            limits = merge(
              var.nected_pods_resources.router_cpu_limit != null ? { cpu = var.nected_pods_resources.router_cpu_limit } : {},
              var.nected_pods_resources.router_memory_limit != null ? { memory = var.nected_pods_resources.router_memory_limit } : {}
            )
          } : {}
        )

        autoscaling = {
          enabled                           = var.nected_pods_replicas.autoscaling
          minReplicas                       = var.nected_pods_replicas.min_router
          maxReplicas                       = var.nected_pods_replicas.max_router
          targetCPUUtilizationPercentage    = 85
          targetMemoryUtilizationPercentage = 85
        }
        ingress = {
          enabled = "true"
          annotations = {
            "kubernetes.io/ingress.class"                       = "azure/application-gateway"
            "appgw.ingress.kubernetes.io/ssl-redirect"          = "true"
            "appgw.ingress.kubernetes.io/use-private-ip"        = local.ingress_use_private
            "appgw.ingress.kubernetes.io/appgw-ssl-certificate" = local.alb_listener_cert_name
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
              hosts = [local.router_domain]
            }
          ]
        }
      }
      medha = {
        existingSecret = var.nected_existing_secret_name
        envVars        = merge(local.medha_base_env, lookup(var.nected_env_overrides, "medha", {}))

        livenessProbe = {
          failureThreshold = 10
        }
        readinessProbe = {
          failureThreshold = 10
        }

        resources = merge(
          {
            requests = {
              cpu    = var.nected_pods_resources.medha_cpu_request
              memory = var.nected_pods_resources.medha_memory_request
            }
          },
          var.nected_pods_resources.medha_cpu_limit != null || var.nected_pods_resources.medha_memory_limit != null ? {
            limits = merge(
              var.nected_pods_resources.medha_cpu_limit != null ? { cpu = var.nected_pods_resources.medha_cpu_limit } : {},
              var.nected_pods_resources.medha_memory_limit != null ? { memory = var.nected_pods_resources.medha_memory_limit } : {}
            )
          } : {}
        )

        autoscaling = {
          enabled                           = var.nected_pods_replicas.autoscaling
          minReplicas                       = var.nected_pods_replicas.min_medha
          maxReplicas                       = var.nected_pods_replicas.max_medha
          targetCPUUtilizationPercentage    = 85
          targetMemoryUtilizationPercentage = 85
        }
      }
      garuda = {
        enabled        = var.nected_enable_garuda
        existingSecret = var.nected_existing_secret_name
        envVars        = merge(local.garuda_base_env, lookup(var.nected_env_overrides, "garuda", {}))

        livenessProbe = {
          failureThreshold = 10
        }
        readinessProbe = {
          failureThreshold = 10
        }

        resources = merge(
          {
            requests = {
              cpu    = var.nected_pods_resources.garuda_cpu_request
              memory = var.nected_pods_resources.garuda_memory_request
            }
          },
          var.nected_pods_resources.garuda_cpu_limit != null || var.nected_pods_resources.garuda_memory_limit != null ? {
            limits = merge(
              var.nected_pods_resources.garuda_cpu_limit != null ? { cpu = var.nected_pods_resources.garuda_cpu_limit } : {},
              var.nected_pods_resources.garuda_memory_limit != null ? { memory = var.nected_pods_resources.garuda_memory_limit } : {}
            )
          } : {}
        )

        autoscaling = {
          enabled                           = var.nected_pods_replicas.autoscaling
          minReplicas                       = var.nected_pods_replicas.min_garuda
          maxReplicas                       = var.nected_pods_replicas.max_garuda
          targetCPUUtilizationPercentage    = 85
          targetMemoryUtilizationPercentage = 85
        }
      }

      commonSecret = {
        secretValue = var.nected_common_secret_value
        resources = merge(
          var.nected_pods_resources.secret_job_cpu_request != null || var.nected_pods_resources.secret_job_memory_request != null ? {
            requests = merge(
              var.nected_pods_resources.secret_job_cpu_request != null ? { cpu = var.nected_pods_resources.secret_job_cpu_request } : {},
              var.nected_pods_resources.secret_job_memory_request != null ? { memory = var.nected_pods_resources.secret_job_memory_request } : {}
            )
          } : {},
          var.nected_pods_resources.secret_job_cpu_limit != null || var.nected_pods_resources.secret_job_memory_limit != null ? {
            limits = merge(
              var.nected_pods_resources.secret_job_cpu_limit != null ? { cpu = var.nected_pods_resources.secret_job_cpu_limit } : {},
              var.nected_pods_resources.secret_job_memory_limit != null ? { memory = var.nected_pods_resources.secret_job_memory_limit } : {}
            )
          } : {}
        )
      }
    })
  ]
}
