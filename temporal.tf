resource "helm_release" "temporal" {
  name       = "temporal"
  repository = "https://nected.github.io/helm-charts"
  chart      = "temporal"
  namespace  = "default"

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
            { value = 20, constraints = {} }
          ]
          "matching.numTaskqueueWritePartitions" = [
            { value = 20, constraints = {} }
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
                maxConns        = 20
                maxConnLifetime = "1h"
                host            = azurerm_postgresql_flexible_server.postgresql.fqdn
                port            = 5432
                user            = var.pg_admin_user
                password        = var.pg_admin_passwd
                tls = {
                  enabled                = true
                  enableHostVerification = false
                }
              }
            }

            visibility = {
              driver = "sql"
              sql = {
                driver          = "postgres12"
                maxConns        = 20
                maxConnLifetime = "1h"
                host            = azurerm_postgresql_flexible_server.postgresql.fqdn
                port            = 5432
                user            = var.pg_admin_user
                password        = var.pg_admin_passwd
                tls = {
                  enabled                = true
                  enableHostVerification = false
                }
              }
            }
          }
        }

        frontend = {
          replicaCount = 1
          autoscaling = {
            enabled      = false
            minReplicas  = "1"
            maxReplicas  = "1"
            targetCPU    = "75"
            targetMemory = "75"
          }
          resources = {
            requests = {
              cpu    = "400m"
              memory = "1024Mi"
            }
          }
        }

        history = {
          replicaCount = 1
          resources = {
            requests = {
              cpu    = "700m"
              memory = "2048Mi"
            }
          }
        }

        matching = {
          replicaCount = 1
          autoscaling = {
            enabled      = false
            minReplicas  = "1"
            maxReplicas  = "1"
            targetCPU    = "75"
            targetMemory = "75"
          }
          resources = {
            requests = {
              cpu    = "400m"
              memory = "1024Mi"
            }
          }
        }

        worker = {
          replicaCount = 1
          autoscaling = {
            enabled      = false
            minReplicas  = "1"
            maxReplicas  = "1"
            targetCPU    = "75"
            targetMemory = "75"
          }
          resources = {
            requests = {
              cpu    = "200m"
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