output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config_raw
  sensitive = true
}

# Network
output "vnet" {
  value = try(azurerm_virtual_network.prod[0], null)
}

output "subnets" {
  value = var.existing_vnet_name != "" ? data.azurerm_subnet.existing : { for k, v in azurerm_subnet.subnets : k => v }
}

# AKS outputs
output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.k8s.name
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.k8s.id
}

output "aks_identity_principal_id" {
  value = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}

output "resource_group_name" {
  description = "Resource group name"
  value       = local.resource_group_name
}

output "resource_group_location" {
  value = local.resource_group_location
}

output "postgresql_host" {
  value = azurerm_postgresql_flexible_server.postgresql.fqdn
}

output "identity_client_id" {
  value = azurerm_user_assigned_identity.identity.client_id
}

output "identity_id" {
  value = azurerm_user_assigned_identity.identity.id
}

output "identity_principal_id" {
  value = azurerm_user_assigned_identity.identity.principal_id
}

output "redis_access_key" {
  value = local.redis_password
}

output "elasticsearch_ip" {
  value = azurerm_linux_virtual_machine.elasticsearch.private_ip_address
}

output "cassandra_seed_node_list" {
  value = local.seed_node_list
}

output "redis_endpoint" {
  value = local.redis_endpoint
}

output "redis_password" {
  value     = local.redis_password
  sensitive = true
}

output "redis_port" {
  value = local.redis_port
}

output "redis_tls_enabled" {
  value = local.redis_tls_enabled
}

output "key_vault_id" {
  value = local.key_vault_id
}

output "key_vault_uri" {
  value = local.key_vault_uri
}

output "alb_vault_secret_endpoint" {
  value = local.alb_vault_secret_endpoint
}

output "cert_secret_name" {
  value = local.cert_secret_name
}

output "cert_vault_name" {
  value = local.cert_vault_name
}

output "internal_app_gateway_ip" {
  value = local.internal_app_gateway_ip
}

output "public_app_gateway_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "public_app_gateway_id" {
  value = azurerm_public_ip.appgw_pip.id
}

output "log_analytics_workspace_id" {
  value       = var.enable_azure_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
  description = "Log Analytics workspace backing Container Insights"
}

output "monitor_workspace_id" {
  value       = var.enable_azure_monitoring && var.enable_managed_prometheus ? azurerm_monitor_workspace.prometheus[0].id : null
  description = "Azure Monitor (managed Prometheus) workspace ID"
}

output "grafana_endpoint" {
  value       = var.enable_azure_monitoring && var.enable_managed_prometheus && var.enable_managed_grafana ? azurerm_dashboard_grafana.main[0].endpoint : null
  description = "Azure Managed Grafana endpoint URL"
}
output "secret_sync_client_id" {
  description = "Client id to annotate the nected-secret-sync service account with (null when disabled)"
  value       = var.secret_manager.enabled ? azurerm_user_assigned_identity.identity.client_id : null
}

output "secret_sync_federated_credential_id" {
  description = "Federated credential, for use in depends_on so the hook does not run before the binding exists"
  value       = var.secret_manager.enabled ? azurerm_federated_identity_credential.secret_sync[0].id : null
}
