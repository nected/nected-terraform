provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "helm" {
  kubernetes = {
    host                   = data.azurerm_kubernetes_cluster.k8s.kube_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate)
  }
}

# provider "kubernetes" {
#   alias = "aks"

#   host                   = azurerm_kubernetes_cluster.k8s.kube_config[0].host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s.kube_config[0].client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.k8s.kube_config[0].client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate)
# }
