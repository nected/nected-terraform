resource "helm_release" "temporal" {
  name       = "temporal"
  repository = "https://nected.github.io/helm-charts"
  chart      = "temporal"
  namespace  = "default"
  version    = var.temporal_chart_version

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
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
            { value = 10000, constraints = {} }
          ]
          "matching.persistenceMaxQPS" = [
            { value = 10000, constraints = {} }
          ]
          "frontend.persistenceMaxQPS" = [
            { value = 10000, constraints = {} }
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
              driver = "${local.temporal_persistant_driver}"
              sql = {
                driver          = "postgres12"
                maxConns        = 20
                maxConnLifetime = "30m"
                connectTimeout  = "5s"
                host            = azurerm_postgresql_flexible_server.postgresql.fqdn
                port            = 5432
                user            = var.pg_admin_user
                password        = var.pg_admin_passwd
                tls = {
                  enabled                = true
                  enableHostVerification = false
                }
              }
              cassandra = {
                hosts    = "${local.seed_node_list}"
                port     = 9042
                keyspace = "temporal"
                user     = ""
                password = ""
              }
            }
          }
        }

        frontend = {
          replicaCount = 1
          autoscaling = {
            enabled      = var.temporal_service_autoscale
            minReplicas  = "${var.temporal_min_frontend_pods}"
            maxReplicas  = "${var.temporal_max_frontend_pods}"
            targetCPU    = "85"
            targetMemory = "85"
          }
          resources = {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }

        history = {
          replicaCount = var.temporal_history_pods
          resources = {
            requests = {
              cpu    = "512m"
              memory = "1024Mi"
            }
          }
        }

        matching = {
          replicaCount = 1
          autoscaling = {
            enabled      = var.temporal_service_autoscale
            minReplicas  = "${var.temporal_min_matching_pods}"
            maxReplicas  = "${var.temporal_max_matching_pods}"
            targetCPU    = "85"
            targetMemory = "85"
          }
          resources = {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }

        worker = {
          replicaCount = 1
          autoscaling = {
            enabled      = var.temporal_service_autoscale
            minReplicas  = "${var.temporal_min_worker_pods}"
            maxReplicas  = "${var.temporal_max_worker_pods}"
            targetCPU    = "85"
            targetMemory = "85"
          }
          resources = {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
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
        external = true
        enabled  = false
        host     = "${azurerm_linux_virtual_machine.elasticsearch.private_ip_address}"
        scheme   = "http"
        port     = 9200
        version  = "v7"
        username = "${var.elasticsearch_admin_username}"
        password = "${var.elasticsearch_admin_password}"
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