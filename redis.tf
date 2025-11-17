# Redis Cache with Standard SKU
resource "azurerm_redis_cache" "redis" {
  name                = "${var.project}-redis"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  capacity            = var.redis_capacity
  family              = "C"
  sku_name            = var.redis_sku_name
  minimum_tls_version = "1.2"

  # For private endpoint access, disable public access
  public_network_access_enabled = false

  redis_configuration {
    # Standard SKU configurations
  }

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Private DNS Zone for Redis
resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = local.resource_group_name

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "${var.project}-redis-dns-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = azurerm_virtual_network.prod.id

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Private Endpoint for Redis
resource "azurerm_private_endpoint" "redis" {
  name                = "${var.project}-redis-pe"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  subnet_id           = azurerm_subnet.subnets["private"].id

  private_service_connection {
    name                           = "${var.project}-redis-psc"
    private_connection_resource_id = azurerm_redis_cache.redis.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "redis-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }

  depends_on = [azurerm_virtual_network.prod]
}