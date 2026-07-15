resource "helm_release" "temporal" {
  name       = "temporal"
  repository = "https://charts.nected.io"
  chart      = "temporal"
  namespace  = var.namespace
  version    = var.temporal_chart_version
  timeout = 100

  values = [
    yamlencode({
      nameOverride     = "nected-temporal"
      fullnameOverride = "nected-temporal"
      additionalAnnotations = {
        "instrumentation.opentelemetry.io/inject-java"   = "false"
        "instrumentation.opentelemetry.io/inject-dotnet" = "false"
        "instrumentation.opentelemetry.io/inject-nodejs" = "false"
        "instrumentation.opentelemetry.io/inject-python" = "false"
      }

      server = {
        # additionalEnv = [
        #   { name = "OTEL_TRACES_EXPORTER", value = "otlp" },
        #   { name = "OTEL_EXPORTER_OTLP_TRACES_PROTOCOL", value = "grpc" },
        #   { name = "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT", value = "http://cloudwatch-agent.amazon-cloudwatch:4315" },
        #   { name = "OTEL_EXPORTER_OTLP_TRACES_INSECURE", value = "true" },
        #   { name = "OTEL_SERVICE_NAME", value = "nected-temporal-frontend" },
        #   { name = "OTEL_RESOURCE_ATTRIBUTES", value = "service.name=nected-temporal-frontend" },
        # ]
        dynamicConfig = {
          "matching.numTaskqueueReadPartitions" = [
            { value = var.temporal_task_partitions, constraints = {} }
          ]
          "matching.numTaskqueueWritePartitions" = [
            { value = var.temporal_task_partitions, constraints = {} }
          ]
          "history.persistenceMaxQPS" = [
            { value = 18000, constraints = {} }
          ]
          "matching.persistenceMaxQPS" = [
            { value = 6000, constraints = {} }
          ]
          "frontend.persistenceMaxQPS" = [
            { value = 4000, constraints = {} }
          ]
        }

        config = {
          numHistoryShards = var.temporal_history_shards

          clusterMetadata = {
            enableGlobalNamespace    = true
            replicationConsumer      = { type = "rpc" }
            failoverVersionIncrement = 100
            masterClusterName        = var.temporal_cluster_name
            currentClusterName       = var.temporal_cluster_name

            clusterInformation = {
              "${var.temporal_cluster_name}" = {
                enabled                = true
                initialFailoverVersion = 1
                rpcName                = "frontend"
                rpcAddress             = "0.0.0.0:7233"
              }
            }
          }

          persistence = {
            default = {
              driver = "${var.temporal_persistant_driver}"
              sql = {
                driver          = "postgres12"
                maxConns        = 30
                maxConnLifetime = "30m"
                connectTimeout  = "5s"
                host            = var.postgresql_host
                port            = 5432
                user            = var.pg_admin_user
                password        = var.pg_admin_passwd
                tls = {
                  enabled                = true
                  enableHostVerification = false
                }
              }
              cassandra = {
                hosts    = "${var.seed_node_list}"
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
            enabled      = var.temporal_pods_replicas.autoscaling
            minReplicas  = "${var.temporal_pods_replicas.min_frontend}"
            maxReplicas  = "${var.temporal_pods_replicas.max_frontend}"
            targetCPU    = "85"
            targetMemory = "85"
          }
          resources = merge(
            {
              requests = {
                cpu    = var.temporal_pods_resources.frontend_cpu_request
                memory = var.temporal_pods_resources.frontend_memory_request
              }
            },
            var.temporal_pods_resources.frontend_cpu_limit != null || var.temporal_pods_resources.frontend_memory_limit != null ? {
              limits = merge(
                var.temporal_pods_resources.frontend_cpu_limit != null ? { cpu = var.temporal_pods_resources.frontend_cpu_limit } : {},
                var.temporal_pods_resources.frontend_memory_limit != null ? { memory = var.temporal_pods_resources.frontend_memory_limit } : {}
              )
            } : {}
          )
        }

        history = {
          replicaCount = var.temporal_pods_replicas.history
          resources = merge(
            {
              requests = {
                cpu    = var.temporal_pods_resources.history_cpu_request
                memory = var.temporal_pods_resources.history_memory_request
              }
            },
            var.temporal_pods_resources.history_cpu_limit != null || var.temporal_pods_resources.history_memory_limit != null ? {
              limits = merge(
                var.temporal_pods_resources.history_cpu_limit != null ? { cpu = var.temporal_pods_resources.history_cpu_limit } : {},
                var.temporal_pods_resources.history_memory_limit != null ? { memory = var.temporal_pods_resources.history_memory_limit } : {}
              )
            } : {}
          )
        }

        matching = {
          replicaCount = 1
          autoscaling = {
            enabled      = var.temporal_pods_replicas.autoscaling
            minReplicas  = "${var.temporal_pods_replicas.min_matching}"
            maxReplicas  = "${var.temporal_pods_replicas.max_matching}"
            targetCPU    = "85"
            targetMemory = "85"
          }
          resources = merge(
            {
              requests = {
                cpu    = var.temporal_pods_resources.matching_cpu_request
                memory = var.temporal_pods_resources.matching_memory_request
              }
            },
            var.temporal_pods_resources.matching_cpu_limit != null || var.temporal_pods_resources.matching_memory_limit != null ? {
              limits = merge(
                var.temporal_pods_resources.matching_cpu_limit != null ? { cpu = var.temporal_pods_resources.matching_cpu_limit } : {},
                var.temporal_pods_resources.matching_memory_limit != null ? { memory = var.temporal_pods_resources.matching_memory_limit } : {}
              )
            } : {}
          )
        }

        worker = {
          replicaCount = 1
          autoscaling = {
            enabled      = var.temporal_pods_replicas.autoscaling
            minReplicas  = "${var.temporal_pods_replicas.min_worker}"
            maxReplicas  = "${var.temporal_pods_replicas.max_worker}"
            targetCPU    = "85"
            targetMemory = "85"
          }
          resources = merge(
            {
              requests = {
                cpu    = var.temporal_pods_resources.worker_cpu_request
                memory = var.temporal_pods_resources.worker_memory_request
              }
            },
            var.temporal_pods_resources.worker_cpu_limit != null || var.temporal_pods_resources.worker_memory_limit != null ? {
              limits = merge(
                var.temporal_pods_resources.worker_cpu_limit != null ? { cpu = var.temporal_pods_resources.worker_cpu_limit } : {},
                var.temporal_pods_resources.worker_memory_limit != null ? { memory = var.temporal_pods_resources.worker_memory_limit } : {}
              )
            } : {}
          )
        }
      }

      admintools = {
        enabled = false
      }

      web = {
        enabled = false
      }

      schema = {
        resources = merge(
          var.temporal_pods_resources.schema_job_cpu_request != null || var.temporal_pods_resources.schema_job_memory_request != null ? {
            requests = merge(
              var.temporal_pods_resources.schema_job_cpu_request != null ? { cpu = var.temporal_pods_resources.schema_job_cpu_request } : {},
              var.temporal_pods_resources.schema_job_memory_request != null ? { memory = var.temporal_pods_resources.schema_job_memory_request } : {}
            )
          } : {},
          var.temporal_pods_resources.schema_job_cpu_limit != null || var.temporal_pods_resources.schema_job_memory_limit != null ? {
            limits = merge(
              var.temporal_pods_resources.schema_job_cpu_limit != null ? { cpu = var.temporal_pods_resources.schema_job_cpu_limit } : {},
              var.temporal_pods_resources.schema_job_memory_limit != null ? { memory = var.temporal_pods_resources.schema_job_memory_limit } : {}
            )
          } : {}
        )
      }

      elasticsearch = {
        external = true
        enabled  = false
        host     = "${var.elasticsearch_ip}"
        scheme   = "${var.elasticsearch_scheme}"
        port     = "${var.elasticsearch_port}"
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