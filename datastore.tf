resource "helm_release" "datastore" {
  count = var.use_managed_redis ? 0 : 1

  name       = "datastore"
  repository = "https://charts.nected.io"
  chart      = "datastore"
  namespace  = "default"
  timeout    = 600
  version    = var.datastore_chart_version

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
  ]

  values = [
    yamlencode({
      redis = {
        enabled = true
        image = {
          registry   = "public.ecr.aws/f6k1n6r3"
          repository = "redis"
          tag        = "8.2.1"
          pullPolicy = "IfNotPresent"
        }
        master = {
          resources = {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "1000m"
              memory = "4Gi"
            }
          }
        }
      }

      postgresql = {
        enabled = false
      }
      elasticsearch = {
        enabled = false
      }
    })
  ]
}