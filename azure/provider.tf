# Azure Config
provider "azurerm" {
  features {}
  subscription_id = var.az_subscription_id
}

provider "helm" {
  kubernetes = {
    host                   = local.k8s_host
    client_certificate     = base64decode(local.k8s_client_certificate)
    client_key             = base64decode(local.k8s_client_key)
    cluster_ca_certificate = base64decode(local.k8s_cluster_ca_certificate)
  }
  alias = "aks"
}