data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_dns_zone" "dns_zone" {
  name                = var.hosted_zone
  resource_group_name = var.hosted_zone_rg == "null" ? local.resource_group_name : var.hosted_zone_rg
}

data "azurerm_kubernetes_cluster" "k8s" {
  name                = azurerm_kubernetes_cluster.k8s.name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_kubernetes_cluster.k8s]
}