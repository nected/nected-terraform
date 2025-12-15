resource "helm_release" "datastore" {
  name       = "datastore"
  repository = "https://nected.github.io/helm-charts"
  chart      = "datastore"
  namespace  = "default"

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
    helm_release.agic,
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
              cpu    = "1"
              memory = "2Gi"
            }
            limits = {
              cpu    = "2"
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