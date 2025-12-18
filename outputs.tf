output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config_raw
  sensitive = true
}

# AKS outputs
output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.k8s.name
}

output "resource_group_name" {
  description = "Resource group name"
  value       = local.resource_group_name
}

output "postgresql_host" {
  value = azurerm_postgresql_flexible_server.postgresql.fqdn
}