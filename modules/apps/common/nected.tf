resource "helm_release" "nected" {
  name       = "nected"
  #repository = "https://charts.nected.io"
  chart      = "/tmp/nected-charts-local/charts/nected"
  namespace  = var.namespace
  timeout    = 600
  version    = var.nected_chart_version

  disable_openapi_validation = var.helm_disable_openapi_validation

  depends_on = [
    helm_release.temporal,
  ]

  values = [
    yamlencode({
      # Top level: the secret-manager hook validates that this matches its
      # target, so the services cannot be left pointing at a stale secret.
      existingSecret = local.nected_secret_name
      # Filters these keys out of the ConfigMap that envVars renders into.
      secretKeys = local.nected_secret_keys
      # One job, running before everything else in this release. The
      # encryption-at-rest key is always managed here; credentials only when a
      # provider is configured.
      secretsmanager = merge(local.secretsmanager_values, {
        commonSecret = {
          enabled     = true
          secretValue = var.secret_manager.ear_secret_value
          remoteKey   = var.secret_manager.ear_remote_key
        }
        credentials = merge(local.secretsmanager_values.credentials, {
          nectedReleaseName = "nected"
          temporalFullname  = "nected-temporal"
        })
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
      })

      konark = {
        envVars = local.konark_env

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
          enabled     = var.ingress_enabled
          annotations = var.ingress_annotations
          hosts = [
            {
              host = var.ui_domain
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
              hosts = [var.ui_domain]
            }
          ]
        }
        targetGroupBinding = {
          enabled        = var.targetgroupbinding_enabled
          targetGroupARN = var.aws_tg_arns["ui"]
        }
      }
      nalanda = {
        existingSecret = local.nected_secret_name
        secretKeys     = local.nected_secret_keys
        customCA       = var.nected_custom_ca
        envVars        = local.nalanda_env

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
          enabled     = var.ingress_enabled
          annotations = var.ingress_annotations
          hosts = [
            {
              host = var.backend_domain
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
              hosts = [var.backend_domain]
            }
          ]
        }

        targetGroupBinding = {
          enabled        = var.targetgroupbinding_enabled
          targetGroupARN = var.aws_tg_arns["backend"]
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
        existingSecret = local.nected_secret_name
        secretKeys     = local.nected_secret_keys
        customCA       = var.nected_custom_ca
        envVars        = local.vidhaan_env

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
        existingSecret = local.nected_secret_name
        secretKeys     = local.nected_secret_keys
        customCA       = var.nected_custom_ca
        envVars        = local.vidhaan_env

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
          enabled     = var.ingress_enabled
          annotations = var.ingress_annotations
          hosts = [
            {
              host = var.router_domain
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
              hosts = [var.router_domain]
            }
          ]
        }
        targetGroupBinding = {
          enabled        = var.targetgroupbinding_enabled
          targetGroupARN = var.aws_tg_arns["router"]
        }
      }
      medha = {
        existingSecret = local.nected_secret_name
        secretKeys     = local.nected_secret_keys
        customCA       = var.nected_custom_ca
        envVars        = local.medha_env

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
        existingSecret = local.nected_secret_name
        secretKeys     = local.nected_secret_keys
        customCA       = var.nected_custom_ca
        envVars        = local.garuda_env

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

    })
  ]
}
