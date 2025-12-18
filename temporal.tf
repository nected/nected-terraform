resource "helm_release" "temporal" {
  name       = "temporal"
  repository = "https://nected.github.io/helm-charts"
  chart      = "temporal"
  namespace  = "default"
  version    = var.temporal_chart_version

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
    helm_release.agic,
    azurerm_postgresql_flexible_server.postgresql,
  ]

  values = [
    yamlencode({
      nameOverride     = "nected-temporal"
      fullnameOverride = "nected-temporal"

      server = {
        dynamicConfig = {
          "matching.numTaskqueueReadPartitions" = [
            { value = var.temporal_task_partitions, constraints = {} }
          ]
          "matching.numTaskqueueWritePartitions" = [
            { value = var.temporal_task_partitions, constraints = {} }
          ]
          "history.persistenceMaxQPS" = [
            { value = 15000, constraints = {} }
          ]
          "matching.persistenceMaxQPS" = [
            { value = 15000, constraints = {} }
          ]
          "frontend.persistenceMaxQPS" = [
            { value = 15000, constraints = {} }
          ]
          "frontend.rps" = [
            { value = 20000, constraints = {} }
          ]
          "frontend.namespaceRPS" = [
            { value = 20000, constraints = {} }
          ]
          "frontend.maxNamespaceRPSPerInstance" = [
            { value = 20000, constraints = {} }
          ]
        }

        config = {
          numHistoryShards = 512

          clusterMetadata = {
            enableGlobalNamespace    = true
            replicationConsumer      = { type = "rpc" }
            failoverVersionIncrement = 100
            masterClusterName        = local.temporal_cluster_name
            currentClusterName       = local.temporal_cluster_name

            clusterInformation = {
              "${local.temporal_cluster_name}" = {
                enabled                = true
                initialFailoverVersion = 1
                rpcName                = "frontend"
                rpcAddress             = "0.0.0.0:7233"
              }
            }
          }

          persistence = {
            default = {
              driver = "sql"
              sql = {
                driver          = "postgres12"
                maxConns        = 30
                maxConnLifetime = "30m"
                connectTimeout  = "5s"
                host            = azurerm_postgresql_flexible_server.postgresql.fqdn
                port            = 5432
                user            = var.pg_admin_user
                password        = var.pg_admin_passwd
                # tls = {
                #   enabled                = true
                #   enableHostVerification = false
                # }
              }
            }

            visibility = {
              driver = "sql"
              sql = {
                driver          = "postgres12"
                maxConns        = 30
                maxConnLifetime = "30m"
                connectTimeout  = "5s"
                host            = azurerm_postgresql_flexible_server.postgresql.fqdn
                port            = 5432
                user            = var.pg_admin_user
                password        = var.pg_admin_passwd
                # tls = {
                #   enabled                = true
                #   enableHostVerification = false
                # }
              }
            }
          }
        }

        frontend = {
          replicaCount = 1
          autoscaling = {
            enabled      = var.temporal_service_autoscale
            minReplicas  = "1"
            maxReplicas  = "4"
            targetCPU    = "85"
            targetMemory = "85"
          }
          resources = {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }
        }

        history = {
          replicaCount = 1
          resources = {
            requests = {
              cpu    = "1000m"
              memory = "2048Mi"
            }
          }
        }

        matching = {
          replicaCount = 1
          autoscaling = {
            enabled      = var.temporal_service_autoscale
            minReplicas  = "1"
            maxReplicas  = "4"
            targetCPU    = "85"
            targetMemory = "85"
          }
          resources = {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }
        }

        worker = {
          replicaCount = 1
          autoscaling = {
            enabled      = var.temporal_service_autoscale
            minReplicas  = "1"
            maxReplicas  = "3"
            targetCPU    = "85"
            targetMemory = "85"
          }
          resources = {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }
        }
      }

      admintools = {
        enabled = false
      }

      web = {
        enabled = false
      }


      elasticsearch = {
        external = false
        enabled  = false
      }

      prometheus = {
        enabled = false
      }

      grafana = {
        enabled = false
      }

      cassandra = {
        enabled = false
      }

      mysql = {
        enabled = false
      }
    })
  ]
}