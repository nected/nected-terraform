output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config_raw
  sensitive = true
}

# Redis outputs
output "redis_hostname" {
  description = "Redis Cache hostname"
  value       = azurerm_redis_cache.redis.hostname
}

output "redis_port" {
  description = "Redis Cache port"
  value       = azurerm_redis_cache.redis.port
}

output "redis_ssl_port" {
  description = "Redis Cache SSL port"
  value       = azurerm_redis_cache.redis.ssl_port
}

output "redis_primary_access_key" {
  description = "Redis Cache primary access key"
  value       = azurerm_redis_cache.redis.primary_access_key
  sensitive   = true
}

output "redis_connection_string" {
  description = "Redis Cache connection string"
  value       = azurerm_redis_cache.redis.primary_connection_string
  sensitive   = true
}

output "redis_private_ip" {
  description = "Redis private endpoint IP"
  value       = azurerm_private_endpoint.redis.private_service_connection[0].private_ip_address
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

output "application_gateway_public_ip" {
  description = "Application Gateway public IP"
  value       = azurerm_public_ip.appgw_pip.ip_address
}

output "postgresql_host" {
  value = azurerm_postgresql_flexible_server.postgresql.fqdn
}