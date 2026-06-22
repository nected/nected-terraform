data "azurerm_kubernetes_cluster" "k8s" {
  name                = module.azure_infra.aks_cluster_name
  resource_group_name = var.az_resource_group_name
  depends_on          = [module.azure_infra]
}